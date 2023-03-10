defmodule Litcovers.Payments.TransactionChecker do
  alias Litcovers.Accounts
  alias Litcovers.Payments.Yookassa
  alias Litcovers.Payments
  require Logger

  use Task, restart: :transient

  def start_link(_arg) do
    Task.start_link(&loop/0)
  end

  def loop do
    Logger.info("TransactionChecker working")

    for transaction <- pending_transactions() do
      case Yookassa.Helpers.check_transaction(transaction) do
        {:ok, {:succeeded, litcoins}} ->
          # add litcoins to user
          user = Accounts.get_user!(transaction.user_id)
          {:ok, user} = Accounts.add_litcoins(user, litcoins)
          Logger.info("User #{user.id} now has #{user.litcoins} litcoins")

        {:error, reason} ->
          Logger.error(
            "TransactionChecker: transaction #{transaction.id} check error: #{inspect(reason)}"
          )

        status ->
          Logger.info(
            "TransactionChecker: transaction #{transaction.id} status: #{inspect(status)}"
          )
      end
    end

    :timer.minutes(1) |> Process.sleep()
    loop()
  end

  defp pending_transactions do
    Payments.list_pending_transactions()
  end
end
