defmodule Litcovers.Payments do
  @moduledoc """
  The Payments context.
  """

  import Ecto.Query, warn: false
  alias Litcovers.Repo

  alias Litcovers.Payments.Transaction
  alias Litcovers.Accounts.User

  def list_pending_transactions do
    Transaction
    |> pending_transaction_query()
    |> Repo.all()
  end

  def user_pending_transactions(%User{} = user) do
    Transaction
    |> user_transaction_query(user)
    |> pending_transaction_query()
    |> Repo.all()
  end

  # user transaction query
  defp user_transaction_query(query, %User{} = user) do
    from t in query,
      where: t.user_id == ^user.id
  end

  # pending transaction query
  defp pending_transaction_query(query) do
    from t in query,
      where: t.status == :pending
  end

  @doc """
  Returns the list of transactions.

  ## Examples

      iex> list_transactions()
      [%Transaction{}, ...]

  """
  def list_transactions do
    Repo.all(Transaction)
  end

  @doc """
  Gets a single transaction.

  Raises `Ecto.NoResultsError` if the Transaction does not exist.

  ## Examples

      iex> get_transaction!(123)
      %Transaction{}

      iex> get_transaction!(456)
      ** (Ecto.NoResultsError)

  """
  def get_transaction!(id), do: Repo.get!(Transaction, id)

  @doc """
  Creates a transaction.

  ## Examples

      iex> create_transaction(%{field: value})
      {:ok, %Transaction{}}

      iex> create_transaction(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_transaction(%User{} = user, attrs \\ %{}) do
    %Transaction{}
    |> Transaction.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Repo.insert()
  end

  @doc """
  Updates a transaction.

  ## Examples

      iex> update_transaction(transaction, %{field: new_value})
      {:ok, %Transaction{}}

      iex> update_transaction(transaction, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_transaction(%Transaction{} = transaction, attrs) do
    transaction
    |> Transaction.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a transaction.

  ## Examples

      iex> delete_transaction(transaction)
      {:ok, %Transaction{}}

      iex> delete_transaction(transaction)
      {:error, %Ecto.Changeset{}}

  """
  def delete_transaction(%Transaction{} = transaction) do
    Repo.delete(transaction)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking transaction changes.

  ## Examples

      iex> change_transaction(transaction)
      %Ecto.Changeset{data: %Transaction{}}

  """
  def change_transaction(%Transaction{} = transaction, attrs \\ %{}) do
    Transaction.changeset(transaction, attrs)
  end
end
