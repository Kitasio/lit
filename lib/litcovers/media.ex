defmodule Litcovers.Media do
  @moduledoc """
  The Media context.
  """

  import Ecto.Query, warn: false
  alias Litcovers.Metadata
  alias Litcovers.Accounts
  alias Litcovers.Repo

  alias Litcovers.Media.Image
  alias Litcovers.Media.Cover

  def see_all_user_covers(%Accounts.User{} = user) do
    Cover
    |> user_images_query(user)
    |> all_unseen_images_query()
    |> Repo.update_all(set: [seen: true])
  end

  def has_unseen_covers?(%Accounts.User{} = user) do
    Cover
    |> user_images_query(user)
    |> all_unseen_images_query()
    |> Repo.aggregate(:count) > 0
  end

  def has_covers?(%Accounts.User{} = user) do
    Cover
    |> user_images_query(user)
    |> Repo.aggregate(:count) > 0
  end

  def has_images?(%Accounts.User{} = user) do
    Image
    |> user_images_query(user)
    |> Repo.aggregate(:count) > 0
  end

  def see_all_user_images(%Accounts.User{} = user) do
    Image
    |> user_images_query(user)
    |> all_unseen_images_query()
    |> Repo.update_all(set: [seen: true])
  end

  def has_unseen_images?(%Accounts.User{} = user) do
    Image
    |> user_images_query(user)
    |> all_unseen_images_query()
    |> Repo.aggregate(:count) > 0
  end

  def last_image(%Accounts.User{} = user) do
    Image
    |> user_images_query(user)
    |> order_by(desc: :inserted_at)
    |> Ecto.Query.first()
    |> Repo.one()
  end

  defp all_unseen_images_query(query) do
    from(r in query, where: r.seen == false)
  end

  def unlock_image(%Image{} = image) do
    image
    |> Image.unlocked_changeset(%{unlocked: true})
    |> Repo.update()
  end

  # shows only images older than 1 day
  def list_old_images do
    Image
    |> order_by_date_insert()
    |> locked_query()
    |> old_images_query()
    |> Repo.all()
  end

  defp yesterday do
    NaiveDateTime.add(Timex.now(), -1, :day)
  end

  defp old_images_query(query) do
    from(r in query, where: r.inserted_at < ^yesterday())
  end

  @doc """
  Returns the list of images.

  ## Examples

      iex> list_images()
      [%Image{}, ...]

  """
  def list_images do
    Image
    |> Repo.all()
  end

  def list_images(offset) do
    Image
    |> limit_query(2)
    |> offset_query(offset)
    |> Repo.all()
  end

  defp offset_query(query, offset) do
    from(r in query, offset: ^offset)
  end

  defp limit_query(query, limit) do
    from(r in query, limit: ^limit)
  end

  def list_unlocked_user_images(%Accounts.User{} = user) do
    Image
    |> user_images_query(user)
    |> order_by_date_insert()
    |> completed_query()
    |> unlocked_query()
    |> Repo.all()
    |> Repo.preload(:ideas)
  end

  def list_unlocked_user_images(%Accounts.User{} = user, limit, offset) do
    Image
    |> user_images_query(user)
    |> order_by_date_insert()
    |> completed_query()
    |> unlocked_query()
    |> limit_query(limit)
    |> offset_query(offset)
    |> Repo.all()
    |> Repo.preload(:ideas)
  end

  def list_user_images(%Accounts.User{} = user) do
    Image
    |> user_images_query(user)
    |> order_by_date_insert()
    |> completed_query()
    |> Repo.all()
    |> Repo.preload(:ideas)
  end

  def list_user_covers(%Accounts.User{} = user) do
    Cover
    |> user_images_query(user)
    |> order_by_date_insert()
    |> Repo.all()
  end

  def list_user_covers(%Accounts.User{} = user, limit, offset) do
    Cover
    |> user_images_query(user)
    |> order_by_date_insert()
    |> limit_query(limit)
    |> offset_query(offset)
    |> Repo.all()
  end

  def list_user_images(%Accounts.User{} = user, limit, offset) do
    Image
    |> user_images_query(user)
    |> order_by_date_insert()
    |> completed_query()
    |> limit_query(limit)
    |> offset_query(offset)
    |> Repo.all()
    |> Repo.preload(:ideas)
  end

  def list_user_favorite_images(%Accounts.User{} = user) do
    Image
    |> user_images_query(user)
    |> order_by_date_insert()
    |> completed_query()
    |> unlocked_query()
    |> favorite_query()
    |> Repo.all()
    |> Repo.preload(:ideas)
  end

  def list_user_favorite_images(%Accounts.User{} = user, limit, offset) do
    Image
    |> user_images_query(user)
    |> order_by_date_insert()
    |> completed_query()
    |> unlocked_query()
    |> favorite_query()
    |> limit_query(limit)
    |> offset_query(offset)
    |> Repo.all()
    |> Repo.preload(:ideas)
  end

  # defp limit_query(query, limit) do
  #   from(r in query, limit: ^limit)
  # end

  defp order_by_date_insert(query) do
    from(r in query, order_by: [desc: r.inserted_at])
  end

  defp completed_query(query) do
    from(r in query, where: r.completed == true)
  end

  defp favorite_query(query) do
    from(r in query, where: r.favorite == true)
  end

  defp user_images_query(query, %Accounts.User{id: user_id}) do
    from(r in query, where: r.user_id == ^user_id)
  end

  defp unlocked_query(query) do
    from(r in query, where: r.unlocked == true)
  end

  defp locked_query(query) do
    from(r in query, where: r.unlocked == false)
  end

  def user_images_amount(%Accounts.User{} = user) do
    Image
    |> user_images_query(user)
    |> Repo.aggregate(:count)
  end

  def user_unlocked_images_amount(%Accounts.User{} = user) do
    Image
    |> user_images_query(user)
    |> unlocked_query()
    |> Repo.aggregate(:count)
  end

  @doc """
  Gets a single image.

  Raises `Ecto.NoResultsError` if the Image does not exist.

  ## Examples

      iex> get_image!(123)
      %Image{}

      iex> get_image!(456)
      ** (Ecto.NoResultsError)

  """
  def get_image!(id), do: Repo.get!(Image, id)

  def get_image_preload_ideas!(id) do
    Image
    |> Repo.get!(id)
    |> Repo.preload(:ideas)
  end

  def get_image_preload!(id) do
    Image
    |> Repo.get!(id)
    |> Repo.preload([:user, :prompt])
  end

  def get_image_preload_all!(id) do
    Image
    |> Repo.get!(id)
    |> Repo.preload([:user, :prompt, :ideas])
  end

  @doc """
  Creates a image.

  ## Examples

      iex> create_image(%{field: value})
      {:ok, %Image{}}

      iex> create_image(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_image(%Accounts.User{} = user, attrs) do
    %Image{}
    |> Image.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Repo.insert()
  end

  def create_image(%Accounts.User{} = user, %Metadata.Prompt{} = prompt, attrs \\ %{}) do
    %Image{}
    |> Image.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Ecto.Changeset.put_assoc(:prompt, prompt)
    |> Repo.insert()
  end

  @doc """
  Updates a image.

  ## Examples

      iex> update_image(image, %{field: new_value})
      {:ok, %Image{}}

      iex> update_image(image, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_image(%Image{} = image, attrs) do
    image
    |> Image.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a image.

  ## Examples

      iex> delete_image(image)
      {:ok, %Image{}}

      iex> delete_image(image)
      {:error, %Ecto.Changeset{}}

  """
  def delete_image(%Image{} = image) do
    Repo.delete(image)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking image changes.

  ## Examples

      iex> change_image(image)
      %Ecto.Changeset{data: %Image{}}

  """
  def change_image(%Image{} = image, attrs \\ %{}) do
    Image.changeset(image, attrs)
  end

  alias Litcovers.Media.Idea

  @doc """
  Returns the list of ideas.

  ## Examples

      iex> list_ideas()
      [%Idea{}, ...]

  """
  def list_ideas do
    Repo.all(Idea)
  end

  @doc """
  Gets a single idea.

  Raises `Ecto.NoResultsError` if the Idea does not exist.

  ## Examples

      iex> get_idea!(123)
      %Idea{}

      iex> get_idea!(456)
      ** (Ecto.NoResultsError)

  """
  def get_idea!(id), do: Repo.get!(Idea, id)

  @doc """
  Creates a idea.

  ## Examples

      iex> create_idea(%{field: value})
      {:ok, %Idea{}}

      iex> create_idea(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_idea(%Image{} = image, attrs \\ %{}) do
    %Idea{}
    |> Idea.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:image, image)
    |> Repo.insert()
  end

  @doc """
  Updates a idea.

  ## Examples

      iex> update_idea(idea, %{field: new_value})
      {:ok, %Idea{}}

      iex> update_idea(idea, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_idea(%Idea{} = idea, attrs) do
    idea
    |> Idea.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a idea.

  ## Examples

      iex> delete_idea(idea)
      {:ok, %Idea{}}

      iex> delete_idea(idea)
      {:error, %Ecto.Changeset{}}

  """
  def delete_idea(%Idea{} = idea) do
    Repo.delete(idea)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking idea changes.

  ## Examples

      iex> change_idea(idea)
      %Ecto.Changeset{data: %Idea{}}

  """
  def change_idea(%Idea{} = idea, attrs \\ %{}) do
    Idea.changeset(idea, attrs)
  end

  alias Litcovers.Media.Cover

  @doc """
  Returns the list of covers.

  ## Examples

      iex> list_covers()
      [%Cover{}, ...]

  """
  def list_covers do
    Repo.all(Cover)
  end

  @doc """
  Gets a single cover.

  Raises `Ecto.NoResultsError` if the Cover does not exist.

  ## Examples

      iex> get_cover!(123)
      %Cover{}

      iex> get_cover!(456)
      ** (Ecto.NoResultsError)

  """
  def get_cover!(id), do: Repo.get!(Cover, id)

  @doc """
  Creates a cover.

  ## Examples

      iex> create_cover(%{field: value})
      {:ok, %Cover{}}

      iex> create_cover(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_cover(%Image{} = image, %Accounts.User{} = user, attrs \\ %{}) do
    %Cover{}
    |> Cover.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:image, image)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Repo.insert()
  end

  @doc """
  Updates a cover.

  ## Examples

      iex> update_cover(cover, %{field: new_value})
      {:ok, %Cover{}}

      iex> update_cover(cover, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_cover(%Cover{} = cover, attrs) do
    cover
    |> Cover.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a cover.

  ## Examples

      iex> delete_cover(cover)
      {:ok, %Cover{}}

      iex> delete_cover(cover)
      {:error, %Ecto.Changeset{}}

  """
  def delete_cover(%Cover{} = cover) do
    Repo.delete(cover)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking cover changes.

  ## Examples

      iex> change_cover(cover)
      %Ecto.Changeset{data: %Cover{}}

  """
  def change_cover(%Cover{} = cover, attrs \\ %{}) do
    Cover.changeset(cover, attrs)
  end
end
