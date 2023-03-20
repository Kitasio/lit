defmodule CoverGen.Create do
  alias CoverGen.Replicate.Model
  alias Litcovers.Accounts
  alias Litcovers.Repo
  alias Litcovers.Media
  alias Litcovers.Media.Image

  alias CoverGen.OAI
  alias CoverGen.Helpers
  alias CoverGen.Spaces

  require Elixir.Logger

  def new(%Image{} = image, %Model{} = params) do
    with _ <- lock_user(image.user_id),
         {:ok, res} <-
           Model.diffuse(
             params,
             System.get_env("REPLICATE_TOKEN")
           ) do
      %{"output" => image_list} = res

      case Spaces.save_to_spaces(image_list) do
        {:error, reason} ->
          release_user(image.user_id)
          IO.inspect(reason)

        img_urls ->
          for url <- img_urls do
            image_params = %{url: url, completed: true}
            ai_update_image(image, image_params)
          end

          {:ok, user} = release_user(image.user_id)
          {:ok, user} = Accounts.inc_recent_generations(user)

          if user.recent_generations >= user.litcoins * 1 + 1 do
            broadcast(image.user_id, image.id, :relaxed_mode)
          else
            broadcast(image.user_id, image.id, :gen_complete)
          end
      end
    else
      {:error, :oai_failed} ->
        release_user(image.user_id)
        broadcast(image.user_id, image.id, :oai_failed)

      {:error, :sd_failed, error} ->
        release_user(image.user_id)
        IO.inspect(error)
        broadcast(image.user_id, image.id, :sd_failed)

      _ ->
        release_user(image.user_id)
        broadcast(image.user_id, image.id, :unknown_error)
    end
  end

  def new(%Image{} = image) do
    with _ <- lock_user(image.user_id),
         {:ok, ideas_list} <-
           OAI.description_to_cover_idea(
             image.description,
             image.prompt.type,
             image.character_gender,
             System.get_env("OAI_TOKEN")
           ),
         _ <- save_ideas(ideas_list, image),
         prompt <-
           Helpers.create_prompt(
             ideas_list |> Enum.random(),
             image.prompt.style_prompt,
             image.character_gender,
             image.prompt.type
           ),
         params <-
           Model.get_params(
             image.model_name,
             prompt,
             image.width,
             image.height
           ),
         {:ok, res} <-
           Model.diffuse(
             params,
             System.get_env("REPLICATE_TOKEN")
           ) do
      %{"output" => image_list} = res

      case Spaces.save_to_spaces(image_list) do
        {:error, reason} ->
          release_user(image.user_id)
          IO.inspect(reason)

        img_urls ->
          for url <- img_urls do
            image_params = %{url: url, completed: true}
            ai_update_image(image, image_params)
          end

          {:ok, user} = release_user(image.user_id)
          {:ok, user} = Accounts.inc_recent_generations(user)

          if user.recent_generations >= user.litcoins * 10 + 10 do
            broadcast(image.user_id, image.id, :relaxed_mode)
          else
            broadcast(image.user_id, image.id, :gen_complete)
          end
      end
    else
      {:error, :oai_failed} ->
        release_user(image.user_id)
        broadcast(image.user_id, image.id, :oai_failed)

      {:error, :sd_failed, error} ->
        release_user(image.user_id)
        IO.inspect(error)
        broadcast(image.user_id, image.id, :sd_failed)

      _ ->
        release_user(image.user_id)
        broadcast(image.user_id, image.id, :unknown_error)
    end
  end

  def ai_update_image(%Image{} = image, attrs) do
    image
    |> Image.ai_changeset(attrs)
    |> Repo.update()
  end

  def save_ideas(ideas_list, image) do
    for idea <- ideas_list do
      idea = String.trim(idea)
      Media.create_idea(image, %{idea: idea})
    end
  end

  defp lock_user(id) do
    user = Accounts.get_user!(id)
    Accounts.update_is_generating(user, true)
  end

  defp release_user(id) do
    user = Accounts.get_user!(id)
    Accounts.update_is_generating(user, false)
  end

  def subscribe(user_id) do
    Phoenix.PubSub.subscribe(Litcovers.PubSub, "generations:#{user_id}")
  end

  defp broadcast(user_id, image_id, event) do
    Phoenix.PubSub.broadcast(Litcovers.PubSub, "generations:#{user_id}", {event, image_id})
    {:ok, image_id}
  end
end
