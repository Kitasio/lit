defmodule LitcoversWeb.PlaceholderLive.Show do
  use LitcoversWeb, :live_view

  alias Litcovers.Metadata

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:placeholder, Metadata.get_placeholder!(id))}
  end

  defp page_title(:show), do: "Show Placeholder"
  defp page_title(:edit), do: "Edit Placeholder"
end
