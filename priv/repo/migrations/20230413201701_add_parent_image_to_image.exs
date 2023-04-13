defmodule Litcovers.Repo.Migrations.AddParentImageToImage do
  use Ecto.Migration

  def change do
    alter table(:images) do
      add :parent_image_id, :integer, default: nil
    end
  end
end
