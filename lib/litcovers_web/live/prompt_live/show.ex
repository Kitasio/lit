defmodule LitcoversWeb.PromptLive.Show do
  use LitcoversWeb, :live_view

  alias Litcovers.Metadata

  @impl true
  def mount(%{"locale" => locale}, _session, socket) do
    socket = assign(socket, :locale, locale)
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:prompt, Metadata.get_prompt!(id))}
  end

  defp page_title(:show), do: "Show Prompt"
  defp page_title(:edit), do: "Edit Prompt"
end
