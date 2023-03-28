defmodule Litcovers.Payments.Yookassa.Helpers do
  alias Litcovers.Payments
  alias Litcovers.Payments.Yookassa
  require Logger

  def transaction_from_yookassa(body) do
    %{
      "amount" => %{
        "value" => amount,
        "currency" => currency
      },
      "id" => id,
      "status" => status,
      "paid" => paid
    } = body

    %{
      amount: amount |> String.split(".") |> List.first() |> String.to_integer(),
      currency: currency,
      tnx_id: id,
      status: status,
      paid: paid,
      payment_service: "yookassa",
      description: "Buying litcoins"
    }
  end

  def calculate_litcoins(amount, discount) when is_integer(amount) and is_integer(discount) do
    price = 390
    amount = amount + discount

    cond do
      amount >= 7800 ->
        div(amount, price) + 10

      amount >= 5850 ->
        div(amount, price) + 5

      amount >= 3900 ->
        div(amount, price) + 3

      amount >= 1950 ->
        div(amount, price) + 2

      amount >= 780 ->
        div(amount, price) + 1

      true ->
        div(amount, price)
    end
  end

  def check_transaction(transaction) do
    case Yookassa.Request.get_payment_status(transaction.tnx_id) do
      {:ok, body} ->
        %{"status" => status, "paid" => paid} = body
        status = status_handler(transaction, status, paid)
        {:ok, status}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def status_handler(transaction, status, paid) do
    case status do
      "succeeded" ->
        Logger.info("Transaction #{transaction.id} succeeded")
        {:ok, _tnx} = Payments.update_transaction(transaction, %{status: status, paid: paid})
        # calculate litcoins based on transaction amount
        litcoins = calculate_litcoins(transaction.amount, transaction.discount)
        {:succeeded, litcoins}

      "canceled" ->
        Logger.info("Transaction #{transaction.id} canceled")
        Payments.update_transaction(transaction, %{status: status})
        :canceled

      "waiting_for_capture" ->
        Logger.info("Transaction #{transaction.id} waiting_for_capture")
        Payments.update_transaction(transaction, %{status: status})
        :waiting_for_capture

      "pending" ->
        Logger.info("Transaction #{transaction.id} is still pending")
        :pending

      unknown ->
        Logger.warn("Transaction #{transaction.id} has #{unknown} status")
        :unknown
    end
  end
end
