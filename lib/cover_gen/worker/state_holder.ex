defmodule CoverGen.Worker.StateHolder do
  alias Litcovers.Accounts
  use GenServer, restart: :transient
  require Logger

  def start_link(args) do
    name = Keyword.get(args, :state_holder_name)
    GenServer.start_link(__MODULE__, args, name: name)
  end

  def get(pid) do
    GenServer.call(pid, :get)
  end

  def set(pid, new_state) do
    GenServer.cast(pid, {:set, new_state})
  end

  def init(args) do
    Process.flag(:trap_exit, true)
    stage = Keyword.get(args, :stage, :oai_request)
    image = Keyword.get(args, :image)
    Logger.info("StateHolder started, stage: #{inspect(stage)}")

    state = %{
      stage: stage,
      image: image
    }

    {:ok, state}
  end

  def handle_call(:get, _from, state) do
    Logger.info("Getting state")
    {:reply, state, state}
  end

  def handle_cast({:set, new_state}, _state) do
    Logger.info("Setting state, new stage: #{inspect(new_state.stage)}")
    {:noreply, new_state}
  end

  def terminate(:shutdown, state) do
    Logger.info("StateHolder terminated, doing cleanup...")
    release_user(state.image.user_id)
    broadcast(state.image.user_id, state.image.id, :unknown_error)
  end

  def terminate(_reason, _state), do: nil

  # Helpers

  defp broadcast(user_id, image_id, event) do
    Phoenix.PubSub.broadcast(Litcovers.PubSub, "generations:#{user_id}", {event, image_id})
    {:ok, image_id}
  end

  defp release_user(id) do
    user = Accounts.get_user!(id)
    Accounts.update_is_generating(user, false)
  end
end
