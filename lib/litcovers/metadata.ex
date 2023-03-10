defmodule Litcovers.Metadata do
  @moduledoc """
  The Metadata context.
  """

  import Ecto.Query, warn: false
  alias Litcovers.Repo

  alias Litcovers.Metadata.Prompt

  @doc """
  Returns the list of prompts.

  ## Examples

      iex> list_prompts()
      [%Prompt{}, ...]

  """
  def list_prompts do
    Prompt
    |> order_by(:name)
    |> Repo.all()
  end

  defp order_by_query(query, field), do: from(p in query, order_by: [desc: ^field])

  def list_all_where(realm, sentiment, type) do
    Prompt
    |> order_by_query(:id)
    |> where_realm_query(realm)
    |> where_sentiment_query(sentiment)
    |> where_type_query(type)
    |> Repo.all()
  end

  defp where_realm_query(query, nil), do: query

  defp where_realm_query(query, realm) do
    from(p in query, where: p.realm == ^realm)
  end

  defp where_sentiment_query(query, nil), do: query

  defp where_sentiment_query(query, sentiment) do
    from(p in query, where: p.sentiment == ^sentiment)
  end

  defp where_type_query(query, nil), do: query

  defp where_type_query(query, type) do
    from(p in query, where: p.type == ^type)
  end

  @doc """
  Gets a single prompt.

  Raises `Ecto.NoResultsError` if the Prompt does not exist.

  ## Examples

      iex> get_prompt!(123)
      %Prompt{}

      iex> get_prompt!(456)
      ** (Ecto.NoResultsError)

  """
  def get_prompt!(id), do: Repo.get!(Prompt, id)

  @doc """
  Creates a prompt.

  ## Examples

      iex> create_prompt(%{field: value})
      {:ok, %Prompt{}}

      iex> create_prompt(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_prompt(attrs \\ %{}) do
    %Prompt{}
    |> Prompt.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a prompt.

  ## Examples

      iex> update_prompt(prompt, %{field: new_value})
      {:ok, %Prompt{}}

      iex> update_prompt(prompt, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_prompt(%Prompt{} = prompt, attrs) do
    prompt
    |> Prompt.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a prompt.

  ## Examples

      iex> delete_prompt(prompt)
      {:ok, %Prompt{}}

      iex> delete_prompt(prompt)
      {:error, %Ecto.Changeset{}}

  """
  def delete_prompt(%Prompt{} = prompt) do
    Repo.delete(prompt)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking prompt changes.

  ## Examples

      iex> change_prompt(prompt)
      %Ecto.Changeset{data: %Prompt{}}

  """
  def change_prompt(%Prompt{} = prompt, attrs \\ %{}) do
    Prompt.changeset(prompt, attrs)
  end

  alias Litcovers.Metadata.Placeholder

  @doc """
  Returns the list of placeholders.

  ## Examples

      iex> list_placeholders()
      [%Placeholder{}, ...]

  """
  def list_placeholders do
    Repo.all(Placeholder)
  end

  @doc """
  Gets a single placeholder.

  Raises `Ecto.NoResultsError` if the Placeholder does not exist.

  ## Examples

      iex> get_placeholder!(123)
      %Placeholder{}

      iex> get_placeholder!(456)
      ** (Ecto.NoResultsError)

  """
  def get_placeholder!(id), do: Repo.get!(Placeholder, id)

  def get_random_placeholder do
    Placeholder
    |> random_order_query()
    |> limit_query(1)
    |> Repo.one()
  end

  defp limit_query(query, limit) do
    from(r in query, limit: ^limit)
  end

  defp random_order_query(query) do
    from(p in query, order_by: fragment("RANDOM()"))
  end

  @doc """
  Creates a placeholder.

  ## Examples

      iex> create_placeholder(%{field: value})
      {:ok, %Placeholder{}}

      iex> create_placeholder(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_placeholder(attrs \\ %{}) do
    %Placeholder{}
    |> Placeholder.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a placeholder.

  ## Examples

      iex> update_placeholder(placeholder, %{field: new_value})
      {:ok, %Placeholder{}}

      iex> update_placeholder(placeholder, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_placeholder(%Placeholder{} = placeholder, attrs) do
    placeholder
    |> Placeholder.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a placeholder.

  ## Examples

      iex> delete_placeholder(placeholder)
      {:ok, %Placeholder{}}

      iex> delete_placeholder(placeholder)
      {:error, %Ecto.Changeset{}}

  """
  def delete_placeholder(%Placeholder{} = placeholder) do
    Repo.delete(placeholder)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking placeholder changes.

  ## Examples

      iex> change_placeholder(placeholder)
      %Ecto.Changeset{data: %Placeholder{}}

  """
  def change_placeholder(%Placeholder{} = placeholder, attrs \\ %{}) do
    Placeholder.changeset(placeholder, attrs)
  end
end
