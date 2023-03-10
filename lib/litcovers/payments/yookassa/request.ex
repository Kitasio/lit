defmodule Litcovers.Payments.Yookassa.Request do
  alias Litcovers.Payments.Yookassa
  require Logger

  @test_shop_id "986370"
  @test_secret_key "test_LE2NhUWa-qGZv5mNU8dqSDp99dcQ2hfkjj9QAaeBiEY"

  @derive Jason.Encoder
  defstruct amount: %{
              value: "390.00",
              currency: "RUB"
            },
            capture: true,
            confirmation: %{
              type: "redirect",
              return_url: "https://litcovers.com/ru/images/new"
            },
            description: "Buying litcoins"

  defp auth_header do
    if System.get_env("MIX_ENV") == "prod" do
      shop_id = System.get_env("YOOKASSA_SHOP_ID")
      secret_key = System.get_env("YOOKASSA_SECRET_KEY")
      "Basic " <> Base.encode64("#{shop_id}:#{secret_key}")
    else
      "Basic " <> Base.encode64("#{@test_shop_id}:#{@test_secret_key}")
    end
  end

  def payment(amount) do
    endpoint = "https://api.yookassa.ru/v3/payments"

    headers = [
      Authorization: auth_header(),
      "Content-Type": "application/json",
      "Idempotence-Key": Ecto.UUID.generate()
    ]

    yookassa_params = %Yookassa.Request{
      amount: %{
        value: amount,
        currency: "RUB"
      },
      capture: true,
      confirmation: %{
        type: "redirect",
        return_url: "https://litcovers.com/ru/images/new"
      },
      description: "Buying litcoins"
    }

    body = Jason.encode!(yookassa_params)

    case HTTPoison.post(endpoint, body, headers) do
      {:ok, %HTTPoison.Response{body: res_body}} ->
        body = Jason.decode!(res_body)
        {:ok, body}

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("Yookassa error: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def get_payment_status(tnx_id) do
    endpoint = "https://api.yookassa.ru/v3/payments/#{tnx_id}"

    headers = [
      Authorization: auth_header()
    ]

    case HTTPoison.get(endpoint, headers) do
      {:ok, %HTTPoison.Response{body: res_body}} ->
        body = Jason.decode!(res_body)
        {:ok, body}

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("Yookassa error: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
