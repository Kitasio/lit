defmodule LitcoversWeb.AdminLive.User do
  use LitcoversWeb, :live_view
  alias Litcovers.Accounts

  @impl true
  def mount(%{"locale" => locale, "id" => id}, _session, socket) do
    user = Accounts.get_user_preload_images!(id)

    {:ok, assign(socket, locale: locale, user: user)}
  end
end