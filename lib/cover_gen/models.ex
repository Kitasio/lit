defmodule CoverGen.Models do
  alias Litcovers.Accounts.User

  @doc """
  Returns the price of the model
  """
  def price(%User{} = user, "sd3"), do: 10 * user.discount
end
