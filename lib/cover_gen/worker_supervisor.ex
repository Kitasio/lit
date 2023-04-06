defmodule CoverGen.WorkerSupervisor do
  use Supervisor, restart: :temporary

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args)
  end

  def init(args) do
    state_holder_name = Keyword.get(args, :state_holder_name)
    image = Keyword.get(args, :image)

    children = [
      {CoverGen.StateHolder, name: state_holder_name, image: image},
      {CoverGen.Worker, args}
    ]

    options = [strategy: :one_for_one, max_seconds: :timer.seconds(30)]
    Supervisor.init(children, options)
  end
end
