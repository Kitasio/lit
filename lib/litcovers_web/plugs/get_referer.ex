defmodule LitcoversWeb.Plugs.GetReferer do
  import Plug.Conn

  @discount_referers [
    %{host: "rugram.me", discount: 0.8},
    %{host: "litnet.com", discount: 0.8},
    %{host: "sapients.art", discount: 0.5},
    %{host: "localhost", discount: 0.7}
  ]

  def init(opts), do: opts

  def call(conn, _opts) do
    referer = get_req_header(conn, "referer")
    referer = List.first(referer) || ""

    %URI{host: referer_host} = URI.parse(referer)
    discount_referer = Enum.find(@discount_referers, fn dr -> dr.host == referer_host end)

    conn
    |> put_session(:referer, discount_referer)
    |> assign(:referer, discount_referer)
  end
end
