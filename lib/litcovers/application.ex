defmodule Litcovers.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      LitcoversWeb.Telemetry,
      # Start the Ecto repository
      Litcovers.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Litcovers.PubSub},
      # Start Finch
      {Finch, name: Litcovers.Finch},
      # Start the Endpoint (http/https)
      LitcoversWeb.Endpoint,
      # Start a worker by calling: Litcovers.Worker.start_link(arg)
      # {Litcovers.Worker, arg}
      CoverGen.CoverProducer,
      CoverGen.CoverConsumerSupervisor,
      CoverGen.Supervisor,
      Litcovers.GenericSupervisor
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Litcovers.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    LitcoversWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
