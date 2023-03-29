defmodule LitcoversWeb.Plugs.GetReferer do
  import Plug.Conn
  alias Litcovers.Campaign

  def init(opts), do: opts

  def call(conn, _opts) do
    %{query_params: query_params} = conn

    case Map.fetch(query_params, "code") do
      {:ok, coupon_code} ->
        referrer = Campaign.get_referral_by_code(coupon_code)

        case referrer do
          nil ->
            conn

          ref ->
            discount_referer = %{host: ref.host, discount: ref.discount}

            conn
            |> put_session(:referer, discount_referer)
            |> assign(:referer, discount_referer)
        end

      :error ->
        conn
    end
  end
end
