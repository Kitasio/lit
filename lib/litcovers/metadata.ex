defmodule Litcovers.Metadata do
  @moduledoc """
  The Metadata context.
  """

  import Ecto.Query, warn: false
  alias Litcovers.Media.Image
  alias Litcovers.Accounts
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

  def get_prompt(id), do: Repo.get(Prompt, id)

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
    prompt
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.no_assoc_constraint(:images)
    |> Repo.delete()
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

  alias Litcovers.Metadata.Tutotial

  @doc """
  Returns the list of tutorials.

  ## Examples

      iex> list_tutorials()
      [%Tutotial{}, ...]

  """
  def list_tutorials do
    Repo.all(Tutotial)
  end

  defp user_tutorials_query(query, %Accounts.User{id: user_id}) do
    from(r in query, where: r.user_id == ^user_id)
  end

  defp by_the_title(query, title) do
    from(r in query, where: r.title == ^title)
  end

  def list_user_tutorials(%Accounts.User{} = user) do
    Tutotial
    |> user_tutorials_query(user)
    |> Repo.all()
  end

  def has_tutorial?(%Accounts.User{} = user, title) do
    Tutotial
    |> user_tutorials_query(user)
    |> by_the_title(title)
    |> Repo.exists?()
  end

  @doc """
  Gets a single tutotial.

  Raises `Ecto.NoResultsError` if the Tutotial does not exist.

  ## Examples

      iex> get_tutotial!(123)
      %Tutotial{}

      iex> get_tutotial!(456)
      ** (Ecto.NoResultsError)

  """
  def get_tutotial!(id), do: Repo.get!(Tutotial, id)

  @doc """
  Creates a tutotial.

  ## Examples

      iex> create_tutotial(%{field: value})
      {:ok, %Tutotial{}}

      iex> create_tutotial(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_tutotial(%Accounts.User{} = user, attrs \\ %{}) do
    %Tutotial{}
    |> Tutotial.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Repo.insert()
  end

  @doc """
  Updates a tutotial.

  ## Examples

      iex> update_tutotial(tutotial, %{field: new_value})
      {:ok, %Tutotial{}}

      iex> update_tutotial(tutotial, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_tutotial(%Tutotial{} = tutotial, attrs) do
    tutotial
    |> Tutotial.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a tutotial.

  ## Examples

      iex> delete_tutotial(tutotial)
      {:ok, %Tutotial{}}

      iex> delete_tutotial(tutotial)
      {:error, %Ecto.Changeset{}}

  """
  def delete_tutotial(%Tutotial{} = tutotial) do
    Repo.delete(tutotial)
  end

  def delete_all_tutorials(%Accounts.User{} = user) do
    Tutotial
    |> user_tutorials_query(user)
    |> Repo.delete_all()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking tutotial changes.

  ## Examples

      iex> change_tutotial(tutotial)
      %Ecto.Changeset{data: %Tutotial{}}

  """
  def change_tutotial(%Tutotial{} = tutotial, attrs \\ %{}) do
    Tutotial.changeset(tutotial, attrs)
  end

  alias Litcovers.Metadata.Chat

  @doc """
  Returns the list of chats.

  ## Examples

      iex> list_chats()
      [%Chat{}, ...]

  """
  def list_chats do
    Repo.all(Chat)
  end

  defp image_chats_query(query, %Image{id: image_id}) do
    from(r in query, where: r.image_id == ^image_id)
  end

  defp order_by_id(query) do
    from(r in query, order_by: [asc: r.id])
  end

  def list_image_chats(%Image{} = image) do
    Chat
    |> image_chats_query(image)
    |> order_by_id()
    |> Repo.all()
  end

  @doc """
  Gets a single chat.

  Raises `Ecto.NoResultsError` if the Chat does not exist.

  ## Examples

      iex> get_chat!(123)
      %Chat{}

      iex> get_chat!(456)
      ** (Ecto.NoResultsError)

  """
  def get_chat!(id), do: Repo.get!(Chat, id)

  @doc """
  Creates a chat.

  ## Examples

      iex> create_chat(%{field: value})
      {:ok, %Chat{}}

      iex> create_chat(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_chat(%Image{} = image, attrs \\ %{}) do
    %Chat{}
    |> Chat.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:image, image)
    |> Repo.insert()
  end

  @doc """
  Updates a chat.

  ## Examples

      iex> update_chat(chat, %{field: new_value})
      {:ok, %Chat{}}

      iex> update_chat(chat, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_chat(%Chat{} = chat, attrs) do
    chat
    |> Chat.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a chat.

  ## Examples

      iex> delete_chat(chat)
      {:ok, %Chat{}}

      iex> delete_chat(chat)
      {:error, %Ecto.Changeset{}}

  """
  def delete_chat(%Chat{} = chat) do
    Repo.delete(chat)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking chat changes.

  ## Examples

      iex> change_chat(chat)
      %Ecto.Changeset{data: %Chat{}}

  """
  def change_chat(%Chat{} = chat, attrs \\ %{}) do
    Chat.changeset(chat, attrs)
  end
end
