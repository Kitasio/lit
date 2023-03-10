defmodule Litcovers.Repo.Migrations.AddSecondaryUrlToPrompt do
  use Ecto.Migration

  def change do
    alter table(:prompts) do
      add :secondary_url, :string, default: nil
    end
  end
end
