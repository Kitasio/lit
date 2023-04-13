defmodule CoverGen do
  def create_new(args) do
    args =
      Keyword.put(
        args,
        :state_holder_name,
        {:via, Registry, {CoverGen.Registry, key: random_job_id()}}
      )

    child_spec =
      Supervisor.child_spec({CoverGen.Worker.CreatorSupervisor, args},
        type: :supervisor,
        shutdown: 30_000
      )

    DynamicSupervisor.start_child(CoverGen.Runner, child_spec)
  end

  def correct(args) do
    args =
      Keyword.put(
        args,
        :state_holder_name,
        {:via, Registry, {CoverGen.Registry, key: random_job_id()}}
      )

    child_spec =
      Supervisor.child_spec({CoverGen.Worker.CorrectorSupervisor, args},
        type: :supervisor,
        shutdown: 30_000
      )

    DynamicSupervisor.start_child(CoverGen.Runner, child_spec)
  end

  defp random_job_id do
    :crypto.strong_rand_bytes(5) |> Base.url_encode64(padding: false)
  end
end
