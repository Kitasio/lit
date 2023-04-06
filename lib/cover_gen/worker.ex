defmodule CoverGen.Worker do
  use GenServer, restart: :transient
  require Logger

  alias Litcovers.Accounts
  alias Litcovers.Media
  alias Litcovers.Repo
  alias Litcovers.Media.Image
  alias CoverGen.Spaces
  alias CoverGen.OAI
  alias CoverGen.StateHolder
  alias CoverGen.Replicate.Model
  alias CoverGen.Helpers

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init(args) do
    image = Keyword.get(args, :image)
    stage = Keyword.get(args, :stage, :oai_request)
    params = Keyword.get(args, :params, %{})
    state_holder_name = Keyword.get(args, :state_holder_name)

    lock_user(image.user_id)

    state = %{
      image: image,
      stage: stage,
      state_holder_name: state_holder_name,
      params: params,
      image_list: []
    }

    {:ok, state, {:continue, :run}}
  end

  def handle_continue(:run, state) do
    current_state = StateHolder.get(state.state_holder_name)
    send(self(), current_state.stage)
    {:noreply, state}
  end

  def handle_info(:oai_request, state) do
    params = generate_model_params(state.image)

    # Updating the state
    new_state = %{state | params: params, stage: :sd_request}
    StateHolder.set(state.state_holder_name, new_state)

    {:noreply, new_state, {:continue, :run}}
  end

  def handle_info(:sd_request, state) do
    {:ok, res} =
      Model.diffuse(
        state.params,
        System.get_env("REPLICATE_TOKEN")
      )

    %{"output" => image_list} = res

    # Updating the state
    new_state = %{state | image_list: image_list, stage: :spaces_request}
    StateHolder.set(state.state_holder_name, new_state)

    {:noreply, new_state, {:continue, :run}}
  end

  def handle_info(:spaces_request, state) do
    case Spaces.save_to_spaces(state.image_list) do
      {:error, reason} ->
        release_user(state.image.user_id)
        Logger.error("Spaces upload failed: #{inspect(reason)}")
        IO.inspect(reason)

      img_urls ->
        for url <- img_urls do
          image_params = %{url: url, completed: true}
          ai_update_image(state.image, image_params)
        end

        {:ok, user} = release_user(state.image.user_id)
        {:ok, user} = Accounts.inc_recent_generations(user)

        if user.recent_generations >= user.litcoins * 10 + 10 do
          broadcast(state.image.user_id, state.image.id, :relaxed_mode)
        else
          broadcast(state.image.user_id, state.image.id, :gen_complete)
        end
    end

    GenServer.stop(state.state_holder_name)
    {:stop, :normal, state}
  end

  # ======================
  # Helpers

  def subscribe(user_id) do
    Phoenix.PubSub.subscribe(Litcovers.PubSub, "generations:#{user_id}")
  end

  defp broadcast(user_id, image_id, event) do
    Phoenix.PubSub.broadcast(Litcovers.PubSub, "generations:#{user_id}", {event, image_id})
    {:ok, image_id}
  end

  def ai_update_image(image, attrs) do
    image
    |> Image.ai_changeset(attrs)
    |> Repo.update()
  end

  defp lock_user(id) do
    user = Accounts.get_user!(id)
    Accounts.update_is_generating(user, true)
  end

  defp release_user(id) do
    user = Accounts.get_user!(id)
    Accounts.update_is_generating(user, false)
  end

  defp generate_model_params(image) do
    oai_res = mutate_description(image)

    prompt =
      Helpers.create_prompt(
        oai_res,
        image.prompt.style_prompt,
        image.character_gender,
        image.prompt.type
      )

    Model.get_params(
      image.model_name,
      prompt,
      image.width,
      image.height
    )
  end

  defp mutate_description(image) when image.lit_ai == true do
    {:ok, ideas_list} =
      OAI.description_to_cover_idea(
        image.description,
        image.prompt.type,
        image.character_gender,
        System.get_env("OAI_TOKEN")
      )

    save_ideas(ideas_list, image)

    Enum.random(ideas_list)
  end

  defp mutate_description(image) when image.lit_ai == false do
    {:ok, text} =
      OAI.description_tldr(
        image.description,
        System.get_env("OAI_TOKEN")
      )

    save_ideas([text], image)

    text
  end

  defp save_ideas(ideas_list, image) do
    for idea <- ideas_list do
      idea = String.trim(idea)
      Media.create_idea(image, %{idea: idea})
    end
  end
end
