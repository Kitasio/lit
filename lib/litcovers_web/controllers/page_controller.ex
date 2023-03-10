defmodule LitcoversWeb.PageController do
  use LitcoversWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, layout: false)
  end

  def dummy(_conn, _params), do: nil
end
