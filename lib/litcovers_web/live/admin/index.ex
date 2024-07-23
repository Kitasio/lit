defmodule LitcoversWeb.AdminLive.Index do
  use LitcoversWeb, :live_view
  alias Litcovers.Accounts

  @impl true
  def mount(%{"locale" => locale}, _session, socket) do
    current_page = 0
    users = Accounts.list_regular_users(10, current_page * 10)

    {:ok, assign(socket, locale: locale, users: users, current_page: current_page)}
  end

  @impl true
  def handle_event("confirm-user", %{"id" => id}, socket) do
    user = Accounts.get_user!(id)
    {:ok, confirmed_user} = Accounts.admin_confirm_user(user)
    IO.inspect(confirmed_user, label: "confirmed user")

    current_page = socket.assigns.current_page
    users = Accounts.list_regular_users(10, current_page * 10)

    {:noreply, assign(socket, users: users, current_page: current_page)}
  end

  @impl true
  def handle_event("next-page", _, socket) do
    current_page = socket.assigns.current_page + 1
    users = Accounts.list_regular_users(10, current_page * 10)

    {:noreply, assign(socket, users: users, current_page: current_page)}
  end

  @impl true
  def handle_event("add-litcoin", %{"id" => id}, socket) do
    user = Accounts.get_user!(id)
    Accounts.add_litcoins(user, 10)

    current_page = socket.assigns.current_page
    users = Accounts.list_regular_users(10, current_page * 10)

    {:noreply, assign(socket, users: users, current_page: current_page)}
  end

  @impl true
  def handle_event("remove-litcoin", %{"id" => id}, socket) do
    user = Accounts.get_user!(id)
    Accounts.remove_litcoins(user, 10)

    current_page = socket.assigns.current_page
    users = Accounts.list_regular_users(10, current_page * 10)

    {:noreply, assign(socket, users: users, current_page: current_page)}
  end

  @impl true
  def handle_event("toggle-enabled", %{"id" => id}, socket) do
    user = Accounts.get_user!(id)
    Accounts.update_enabled(user, %{enabled: !user.enabled})

    current_page = socket.assigns.current_page
    users = Accounts.list_regular_users(10, current_page * 10)

    {:noreply, assign(socket, users: users, current_page: current_page)}
  end
end
