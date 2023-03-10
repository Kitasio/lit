defmodule LitcoversWeb.AdminLive.Index do
  use LitcoversWeb, :live_view
  alias Litcovers.Accounts

  @impl true
  def mount(%{"locale" => locale}, _session, socket) do
    users = Accounts.list_regular_users()

    drip_machine =
      case GenServer.whereis(CoverGen.DrippingMachine) do
        nil -> false
        _ -> true
      end

    {:ok, assign(socket, locale: locale, users: users, drip_machine: drip_machine)}
  end

  @impl true
  def handle_event("add-litcoin", %{"id" => id}, socket) do
    user = Accounts.get_user!(id)
    Accounts.add_litcoins(user, 1)
    {:noreply, assign(socket, users: Accounts.list_regular_users())}
  end

  @impl true
  def handle_event("remove-litcoin", %{"id" => id}, socket) do
    user = Accounts.get_user!(id)
    Accounts.remove_litcoins(user, 1)
    {:noreply, assign(socket, users: Accounts.list_regular_users())}
  end

  @impl true
  def handle_event("toggle-enabled", %{"id" => id}, socket) do
    user = Accounts.get_user!(id)
    Accounts.update_enabled(user, %{enabled: !user.enabled})
    {:noreply, assign(socket, users: Accounts.list_regular_users())}
  end

  @impl true
  def handle_event("toggle-dripping_machine", %{}, socket) do
    if GenServer.whereis(CoverGen.DrippingMachine) != nil do
      CoverGen.Supervisor.terminate_child(CoverGen.DrippingMachine)
      CoverGen.Supervisor.delete_child(CoverGen.DrippingMachine)
    else
      CoverGen.Supervisor.start_child({CoverGen.DrippingMachine, %{}})
    end

    drip_machine =
      case GenServer.whereis(CoverGen.DrippingMachine) do
        nil -> false
        _ -> true
      end

    {:noreply, assign(socket, users: Accounts.list_regular_users(), drip_machine: drip_machine)}
  end
end
