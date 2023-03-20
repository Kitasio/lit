defmodule LitcoversWeb.Plugs.GetReferer do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    referer = get_req_header(conn, "referer")

    conn
    |> put_session(:referer, referer)
    |> assign(:referer, referer)
  end
end
