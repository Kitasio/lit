defmodule LitcoversWeb.Plugs.EnsureEnoughCoins do
  import Plug.Conn
  use LitcoversWeb, :controller

  def init(opts), do: opts

  def call(conn, _opts) do
    cost =
      CoverGen.Models.price(conn.assigns[:current_user], conn.assigns[:model_name])

    if conn.assigns[:current_user].litcoins < cost do
      conn
      |> put_status(:payment_required)
      |> put_view(LitcoversWeb.ErrorJSON)
      |> render(:"402")
      |> halt()
    else
      assign(conn, :cost, cost)
    end
  end
end
