defmodule LitcoversWeb.V1.AccountJSON do
  alias Litcovers.Accounts.User
  alias CoverGen.Models

  @doc """
  Renders an account.
  """
  def index(%{account: account}) do
    %{data: data(account)}
  end

  defp data(%User{} = user) do
    %{
      email: user.email,
      litcoins: user.litcoins,
      models: Models.all_with_price(user)
    }
  end
end
