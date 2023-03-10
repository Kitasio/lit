defmodule CoverGen.CoverProducer do
  alias Litcovers.Media.Image
  use GenStage
  require Logger

  def start_link(_args) do
    GenStage.start_link(__MODULE__, [], name: __MODULE__)
  end

  def start_image_gen(%Image{} = image) do
    GenStage.cast(__MODULE__, {:start_image_gen, [image]})
  end

  # client
  def init(initial_state) do
    Logger.info("CoverProducer init")
    {:producer, initial_state}
  end

  def handle_demand(demand, state) do
    Logger.info("CoverProducer received demand: #{demand}")
    {:noreply, [], state}
  end

  def handle_cast({:start_image_gen, images}, state) do
    {:noreply, images, state}
  end
end
