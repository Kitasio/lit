defmodule LitcoversWeb.AdminLive.Image do
  use LitcoversWeb, :live_view
  alias Litcovers.Media

  @impl true
  def mount(%{"locale" => locale, "id" => id}, _session, socket) do
    image = Media.get_image_preload_all!(id)
    {:ok, assign(socket, locale: locale, image: image)}
  end
end
