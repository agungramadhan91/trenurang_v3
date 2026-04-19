defmodule TrenurangCore.Repo.Migrations.CreateUserPersona do
  use Ecto.Migration

  def change do
    create table(:user_persona) do
      add :user_id,      references(:users, on_delete: :delete_all), null: false
      add :activity_log, {:array, :map}, default: []

      timestamps()
    end

    create index(:user_persona, [:user_id])
  end
end
