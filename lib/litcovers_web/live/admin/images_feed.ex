defmodule LitcoversWeb.AdminLive.ImagesFeed do
  use LitcoversWeb, :live_view
  alias Litcovers.Media

  @impl true
  def mount(%{"locale" => locale}, _session, socket) do
    socket =
      assign(socket,
        locale: locale,
        page: 0
      )

    if connected?(socket) do
      get_images(socket)
    else
      socket
    end

    {:ok, socket, temporary_assigns: [images: []]}
  end

  defp get_images(%{assigns: %{page: page}} = socket) do
    socket = assign(socket, page: page)

    assign(socket, images: Media.list_images(8, page * 8))
  end

  @impl true
  def handle_event("load-more", _, %{assigns: assigns} = socket) do
    {:noreply, assign(socket, page: assigns.page + 1) |> get_images()}
  end
end

