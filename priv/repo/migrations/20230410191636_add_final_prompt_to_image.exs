defmodule Litcovers.Repo.Migrations.AddFinalPromptToImage do
  use Ecto.Migration

  def change do
    alter table(:images) do
      add :final_prompt, :text
    end
  end
end
