defmodule LitcoversWeb.ImageLive.Index do
  use LitcoversWeb, :live_view

  alias Phoenix.LiveView.JS
  alias Litcovers.Media
  alias Litcovers.Media.Image
  alias Litcovers.Accounts

  @impl true
  def mount(%{"locale" => locale}, _session, socket) do
    Gettext.put_locale(locale)
    Task.start_link(fn -> Media.see_all_user_images(socket.assigns.current_user) end)

    socket = assign(socket, locale: locale, page: 0)

    if connected?(socket) do
      get_images(socket)
    else
      socket
    end

    {:ok, socket, temporary_assigns: [images: []]}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    if has_images?(socket.assigns.current_user) do
      socket
      |> push_navigate(to: ~p"/#{socket.assigns.locale}/images/all")
    else
      socket
      |> push_navigate(to: ~p"/#{socket.assigns.locale}/images/new")
    end
  end

  defp apply_action(socket, :favorites, _params) do
    socket
    |> assign(images: list_favorite_images(socket.assigns.current_user))
  end

  defp apply_action(socket, :all, _params) do
    socket
    |> assign(images: list_all_images(socket.assigns.current_user))
  end

  defp apply_action(socket, :unlocked, _params) do
    socket
    |> assign(images: list_images(socket.assigns.current_user))
  end

  @impl true
  def handle_event("load-more", _, %{assigns: assigns} = socket) do
    {:noreply, assign(socket, page: assigns.page + 1) |> get_images()}
  end

  # unlocks image spending 1 litcoin to current user
  @impl true
  def handle_event("unlock", %{"image_id" => image_id}, socket) do
    litcoins = socket.assigns.current_user.litcoins

    if litcoins > 0 do
      image = Media.get_image!(image_id)
      {:ok, image} = Media.unlock_image(image)
      {:ok, user} = Accounts.remove_litcoins(socket.assigns.current_user, 1)
      socket = assign(socket, current_user: user)
      socket = push_event(socket, "update-litcoins", %{id: "litcoins"})
      send(self(), {:update_image, image})
      {:noreply, redirect(socket, to: "/#{socket.assigns.locale}/images/#{image_id}/edit")}
    else
      {:noreply, redirect(socket, to: "/#{socket.assigns.locale}/payment_options")}
    end
  end

  @impl true
  def handle_event("delete-image", %{"image_id" => id}, socket) do
    image = Media.get_image!(id)

    Task.start(fn ->
      CoverGen.Spaces.delete_object(image.url)
    end)

    {:ok, _image} = Media.delete_image(image)

    {:noreply, socket}
  end

  @impl true
  def handle_event("toggle-favorite", %{"image_id" => image_id}, socket) do
    image = Media.get_image_preload_ideas!(image_id)

    case Media.update_image(image, %{favorite: !image.favorite}) do
      {:ok, image} ->
        send(self(), {:update_image, image})
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  @impl true
  def handle_info({:update_image, image}, socket) do
    {:noreply, update(socket, :images, fn images -> [image | images] end)}
  end

  defp get_images(%{assigns: %{page: page}} = socket) do
    socket = assign(socket, page: page)

    case socket.assigns.live_action do
      :all ->
        assign(socket, images: Media.list_user_images(socket.assigns.current_user, 8, page * 8))

      :unlocked ->
        assign(socket,
          images: Media.list_unlocked_user_images(socket.assigns.current_user, 8, page * 8)
        )

      :favorites ->
        assign(socket,
          images: Media.list_user_favorite_images(socket.assigns.current_user, 8, page * 8)
        )

      _ ->
        socket
    end
  end

  def hide_deleted_image(js \\ %JS{}, id) do
    IO.puts("hiding deleted image #{id}")

    js
    |> hide("##{id}-img")
    |> JS.add_class("w-1/2", to: "body")
  end

  def has_images?(user) do
    Media.user_images_amount(user) > 0
  end

  def has_new_images?(user) do
    Media.has_unseen_images?(user)
  end

  defp list_images(user) do
    Media.list_unlocked_user_images(user, 8, 0)
  end

  defp list_all_images(user) do
    Media.list_user_images(user, 8, 0)
  end

  defp list_favorite_images(user) do
    Media.list_user_favorite_images(user, 8, 0)
  end

  def aspect_ratio({512, 512}), do: "square"
  def aspect_ratio({512, 768}), do: "cover"

  def placeholder_or_empty(nil),
    do: %{
      author: "Герман Мелвилл",
      title: "Моби Дик",
      description:
        "История о мести человека гигантскому белому киту. После того, как кит нападает и убивает его друга, мужчина, Ахав, посвящает свою жизнь выслеживанию и убийству этого существа. В романе затрагиваются темы борьбы добра со злом, Бога и человеческой способности к дикости.",
      vibe: "приключения, опасность, одержимость"
    }

  def placeholder_or_empty(placeholder), do: placeholder

  def insert_image_watermark(%Image{url: nil}), do: nil

  def insert_image_watermark(%Image{unlocked: false} = image) do
    uri = image.url |> URI.parse()
    %URI{host: host, path: path} = uri

    {filename, list} = path |> String.split("/") |> List.pop_at(-1)
    bucket = list |> List.last()
    transformation = "tr:oi-litmark.png,ow-#{image.width},oh-#{image.height}"

    case host do
      "ik.imagekit.io" ->
        Path.join(["https://", host, bucket, transformation, filename])

      _ ->
        image.url
    end
  end

  def insert_image_watermark(%Image{unlocked: true} = image) do
    image.url
  end
end
