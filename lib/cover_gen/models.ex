defmodule CoverGen.Models do
  alias Litcovers.Accounts.User

  @doc """
  Returns all the models
  """
  def all() do
    [
      "core",
      "ultra",
      "sd3"
    ]
  end

  @doc """
  Returns the price of the model
  """
  def price(%User{} = user, "sd3"), do: floor(16 * user.discount)
  def price(%User{} = user, "core"), do: floor(8 * user.discount)
  def price(%User{} = user, "ultra"), do: floor(20 * user.discount)

  def all_with_price(%User{} = user) do
    all()
    |> Enum.map(fn model -> %{"model" => model, "price" => price(user, model)} end)
  end
end
