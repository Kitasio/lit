defmodule CoverGen.Worker do
  alias Litcovers.Media.Image
  use GenServer
  require Logger

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def generate(%Image{} = image, lit_ai) do
    GenServer.cast(__MODULE__, {:gen, image, lit_ai})
  end

  def init(state) do
    Logger.info("Starting CoverGen Worker")
    {:ok, state}
  end

  def handle_cast({:gen, image, lit_ai}, state) do
    Task.start_link(fn ->
      CoverGen.Create.new(image, lit_ai)
    end)

    {:noreply, state}
  end
end
