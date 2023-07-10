defmodule Litcovers.Repo.Migrations.AddStylePresetToImage do
  use Ecto.Migration

  def change do
    alter table(:images) do
      add :style_preset, :string
    end
  end
end
