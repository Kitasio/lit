defmodule LitcoversWeb.V1.AccountJSON do
  alias Litcovers.Accounts.User

  @doc """
  Renders an account.
  """
  def index(%{account: account}) do
    %{data: data(account)}
  end

  defp data(%User{} = user) do
    %{
      email: user.email,
      id: user.id,
      litcoins: user.litcoins,
    }
  end
end
