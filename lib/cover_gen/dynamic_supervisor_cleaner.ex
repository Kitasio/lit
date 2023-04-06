defmodule CoverGen.DynamicSupervisorCleaner do
  use GenServer
  require Logger

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(args) do
    {:ok, args, {:continue, :run}}
  end

  def handle_continue(:run, state) do
    Process.send_after(self(), :cleanup, :timer.seconds(60))
    {:noreply, state}
  end

  def handle_info(:cleanup, state) do
    Logger.info("Starting DynamicSupervisorCleaner")

    for {_, pid, _, _} <- Supervisor.which_children(CoverGen.Runner) do
      active = Map.get(Supervisor.count_children(pid), :active)

      if active == 0 do
        Process.exit(pid, :kill)
      end
    end

    {:noreply, state, {:continue, :run}}
  end
end
