defmodule TrenurangCore.Repo.Migrations.CreateStorePersona do
  use Ecto.Migration

  def change do
    create table(:store_persona) do
      add :store_id,    references(:stores, on_delete: :delete_all), null: false
      add :info,        :map, default: %{}
      add :notes,       :map, default: %{}
      add :schedule,    {:array, :map}, default: []
      add :transaction, {:array, :map}, default: []
      add :profit,      {:array, :map}, default: []
      add :liabilities, {:array, :map}, default: []

      timestamps()
    end

    create index(:store_persona, [:store_id])
  end
end
