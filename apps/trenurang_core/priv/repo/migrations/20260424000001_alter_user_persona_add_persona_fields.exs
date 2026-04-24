defmodule TrenurangCore.Repo.Migrations.AlterUserPersonaAddPersonaFields do
  use Ecto.Migration

  def change do
    alter table(:user_persona) do
      add :roles,           {:array, :map}, default: []
      add :needs,           {:array, :map}, default: []
      add :skills,          {:array, :string}, default: []
      add :budget_range,    :map, default: %{}
      add :prompted_fields, {:array, :string}, default: []
      add :persona_consent, :boolean, default: false, null: false
    end
  end
end
