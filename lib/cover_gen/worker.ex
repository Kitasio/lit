defmodule CoverGen.Worker do
  alias Litcovers.Media.Image
  alias CoverGen.Replicate.Model
  use GenServer
  require Logger

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def generate(%Image{} = image, lit_ai) when is_boolean(lit_ai) do
    GenServer.cast(__MODULE__, {:gen, image, lit_ai})
  end

  def generate(%Image{} = image, %Model{} = params) do
    GenServer.cast(__MODULE__, {:gen_with_model, image, params})
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

  def handle_cast({:gen_with_model, image, params}, state) do
    Task.start_link(fn ->
      CoverGen.Create.new(image, params)
    end)

    {:noreply, state}
  end
end
