defmodule LitcoversWeb.V1.AccountController do
  alias Litcovers.Accounts
  use LitcoversWeb, :controller

  action_fallback LitcoversWeb.FallbackController

  def index(conn, _params) do
    account = Accounts.get_user!(conn.assigns[:current_user].id)
    render(conn, :index, account: account)
  end
end
