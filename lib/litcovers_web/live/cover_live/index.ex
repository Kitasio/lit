defmodule LitcoversWeb.CoverLive.Index do
  use LitcoversWeb, :live_view

  alias Litcovers.Media

  @impl true
  def mount(%{"locale" => locale}, _session, socket) do
    Gettext.put_locale(locale)
    Task.start_link(fn -> Media.see_all_user_covers(socket.assigns.current_user) end)

    socket = assign(socket, locale: locale, page: 0)

    # on initial load it'll return false,
    # then true on the next.
    if connected?(socket) do
      get_images(socket)
    else
      socket
    end

    {:ok, socket, temporary_assigns: [images: []]}
  end

  @impl true
  def handle_event("load-more", _, %{assigns: assigns} = socket) do
    {:noreply, assign(socket, page: assigns.page + 1) |> get_images()}
  end

  @impl true
  def handle_event("delete-cover", %{"image_id" => id}, socket) do
    image = Media.get_cover!(id)

    Task.start(fn ->
      CoverGen.Spaces.delete_object(image.url)
    end)

    {:ok, _image} = Media.delete_cover(image)

    {:noreply, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    if Media.has_covers?(socket.assigns.current_user) do
      socket
      |> assign(images: Media.list_user_covers(socket.assigns.current_user, 8, 0))
    else
      socket
      |> push_navigate(to: ~p"/#{socket.assigns.locale}/images")
    end
  end

  defp get_images(%{assigns: %{page: page}} = socket) do
    socket = assign(socket, page: page)

    case socket.assigns.live_action do
      :index ->
        images = Media.list_user_covers(socket.assigns.current_user, 8, page * 8)
        assign(socket, images: images)
      _ ->
        socket
    end
  end
end
