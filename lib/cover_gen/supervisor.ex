defmodule CoverGen.Supervisor do
  use Supervisor
  require Logger

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def start_child(child_spec) do
    Supervisor.start_child(__MODULE__, child_spec)
  end

  def terminate_child(child_spec) do
    Supervisor.terminate_child(__MODULE__, child_spec)
  end

  def delete_child(child_spec) do
    Supervisor.delete_child(__MODULE__, child_spec)
  end

  @impl true
  def init(_init_arg) do
    Logger.info("CoverGen.Supervisor init, pid: #{inspect(self())}")

    children =
      if System.get_env("MIX_ENV") == "prod" do
        [
          CoverGen.Cleaner.ImageDeleter,
          {CoverGen.DrippingMachine, %{}},
          {CoverGen.Worker, %{}}
        ]
      else
        [
          CoverGen.Cleaner.ImageDeleter,
          {CoverGen.DrippingMachine, %{}}
        ]
      end

    Supervisor.init(children,
      strategy: :one_for_one
    )
  end
end
