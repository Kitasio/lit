defmodule CoverGen.Worker.CreatorSupervisor do
  use Supervisor, restart: :temporary

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args)
  end

  def init(args) do
    children = [
      {CoverGen.Worker.StateHolder, args},
      {CoverGen.Worker.Creator, args}
    ]

    options = [strategy: :one_for_one, max_seconds: :timer.seconds(30)]
    Supervisor.init(children, options)
  end
end
