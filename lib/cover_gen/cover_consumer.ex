defmodule CoverGen.CoverConsumer do
  alias Litcovers.Media.Image
  use GenStage
  require Logger

  def start_link(%Image{} = image) do
    Task.start_link(fn -> CoverGen.Create.new(image) end)
  end

  def init(initial_state) do
    {:consumer, initial_state}
  end
end
