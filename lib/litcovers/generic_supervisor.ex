defmodule Litcovers.GenericSupervisor do
  use Supervisor
  require Logger

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    Logger.info("Litcovers.Supervisor init, pid: #{inspect(self())}")

    children = [
      {Redix, {System.get_env("REDIS_CONN_URL"), [name: :redix]}},
      Litcovers.UserReleaser,
      Litcovers.RelaxedModeReleaser,
      Litcovers.Payments.TransactionChecker
    ]

    Supervisor.init(children,
      strategy: :one_for_one
    )
  end
end
