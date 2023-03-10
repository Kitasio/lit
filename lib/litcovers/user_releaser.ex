defmodule Litcovers.UserReleaser do
  alias Litcovers.Accounts
  require Logger
  use Task, restart: :transient

  def start_link(_arg) do
    Task.start_link(&loop/0)
  end

  defp loop do
    Logger.info("UserReleaser doing work")

    Accounts.list_stuck_users()
    |> Enum.map(fn user ->
      release(user)
    end)

    Process.sleep(:timer.minutes(3))
    loop()
  end

  defp release(user) do
    Accounts.update_is_generating(user, false)
  end
end
