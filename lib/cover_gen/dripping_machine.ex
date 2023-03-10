defmodule CoverGen.DrippingMachine do
  use GenServer, restart: :transient
  require Logger

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def init(state) do
    Logger.info("Dripping machine init")
    state = Map.put(state, :timer_ref, schedule_work())
    {:ok, state}
  end

  def handle_info({:drip, :server}, state) do
    Process.cancel_timer(state.timer_ref)

    Logger.info("Starting cheap generation")
    CoverGen.SD.dummy_diffuse()

    {:noreply, %{state | timer_ref: schedule_work()}}
  end

  def handle_info({:drip, :user}, state) do
    Process.cancel_timer(state.timer_ref)
    {:noreply, %{state | timer_ref: schedule_work()}}
  end

  defp schedule_work do
    Process.send_after(self(), {:drip, :server}, :timer.minutes(6))
  end
end
