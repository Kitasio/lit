defmodule CoverGen.CoverConsumerSupervisor do
  use ConsumerSupervisor
  require Logger

  def start_link(_args) do
    ConsumerSupervisor.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    Logger.info("CoverConsumerSupervisor init")

    children = [
      %{
        id: CoverGen.CoverConsumer,
        start: {CoverGen.CoverConsumer, :start_link, []},
        restart: :transient
      }
    ]

    opts = [
      strategy: :one_for_one,
      max_seconds: :timer.minutes(30),
      subscribe_to: [{CoverGen.CoverProducer, max_demand: System.schedulers_online() * 100}]
    ]

    ConsumerSupervisor.init(children, opts)
  end
end
