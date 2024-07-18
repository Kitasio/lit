defmodule CoverGen.Models do
  alias Litcovers.Accounts.User

  @doc """
  Returns the price of the model
  """
  def price(%User{} = user, "sd3"), do: 10 * user.discount
  def price(%User{} = user, "core"), do: 8 * user.discount
  def price(%User{} = user, "ultra"), do: 12 * user.discount
end
