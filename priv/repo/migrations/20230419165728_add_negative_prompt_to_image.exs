defmodule Litcovers.Repo.Migrations.AddNegativePromptToImage do
  use Ecto.Migration

  def change do
    alter table(:images) do
      add :negative_prompt, :string
    end
  end
end
