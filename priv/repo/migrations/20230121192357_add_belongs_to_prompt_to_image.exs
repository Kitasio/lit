defmodule Litcovers.Repo.Migrations.AddBelongsToPromptToImage do
  use Ecto.Migration

  def change do
    alter table(:images) do
      add :prompt_id, references(:prompts, on_delete: :delete_all)
      # drops the field prompt
      remove :prompt
    end
  end
end
