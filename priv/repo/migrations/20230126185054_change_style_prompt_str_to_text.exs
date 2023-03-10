defmodule Litcovers.Repo.Migrations.ChangeStylePromptStrToText do
  use Ecto.Migration

  def change do
    alter table(:prompts) do
      modify :style_prompt, :text
    end
  end
end
