defmodule LitcoversWeb.PlaceholderLive.Index do
  use LitcoversWeb, :live_view

  alias Litcovers.Metadata
  alias Litcovers.Metadata.Placeholder

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :placeholders, list_placeholders())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Placeholder")
    |> assign(:placeholder, Metadata.get_placeholder!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Placeholder")
    |> assign(:placeholder, %Placeholder{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Placeholders")
    |> assign(:placeholder, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    placeholder = Metadata.get_placeholder!(id)
    {:ok, _} = Metadata.delete_placeholder(placeholder)

    {:noreply, assign(socket, :placeholders, list_placeholders())}
  end

  defp list_placeholders do
    Metadata.list_placeholders()
  end
end
