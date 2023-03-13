defmodule CoverGen.CoverConsumer do
  alias CoverGen.Replicate.Model
  alias Litcovers.Media.Image
  use GenStage
  require Logger

  def start_link({%Image{} = image, %Model{} = params}) do
    Task.start_link(fn -> CoverGen.Create.new(image, params) end)
  end

  def start_link(%Image{} = image) do
    Task.start_link(fn -> CoverGen.Create.new(image) end)
  end

  def init(initial_state) do
    {:consumer, initial_state}
  end
end
