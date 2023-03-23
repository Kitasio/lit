defmodule LitcoversWeb.PromptLive.Index do
  use LitcoversWeb, :live_view

  alias Litcovers.Metadata
  alias Litcovers.Metadata.Prompt

  @impl true
  def mount(%{"locale" => locale}, _session, socket) do
    Gettext.put_locale(locale)
    {:ok, assign(socket, prompts: list_prompts(), locale: locale)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Prompt")
    |> assign(:prompt, Metadata.get_prompt!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Prompt")
    |> assign(:prompt, %Prompt{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Prompts")
    |> assign(:prompt, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    prompt = Metadata.get_prompt!(id)
    {:ok, _} = Metadata.delete_prompt(prompt)

    {:noreply, assign(socket, :prompts, list_prompts())}
  end

  defp list_prompts do
    prompts = Metadata.list_prompts()

    prompt_name_as_integers(prompts)
    |> sort_by(:name)
  end

  defp sort_by(prompts, value) do
    Enum.sort_by(prompts, &Map.fetch(&1, value))
  end

  defp prompt_name_as_integers(prompts) when is_list(prompts) do
    Stream.map(prompts, fn prompt ->
      Map.update!(prompt, :name, fn x ->
        case Integer.parse(x) do
          {integer, _remainder} ->
            integer

          :error ->
            x
        end
      end)
    end)
  end
end
