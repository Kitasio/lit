defmodule Litcovers.Repo.Migrations.CreateChats do
  use Ecto.Migration

  def change do
    create table(:chats) do
      add :role, :string
      add :content, :text
      add :image_id, references(:images, on_delete: :nothing)

      timestamps()
    end

    create index(:chats, [:image_id])
  end
end
