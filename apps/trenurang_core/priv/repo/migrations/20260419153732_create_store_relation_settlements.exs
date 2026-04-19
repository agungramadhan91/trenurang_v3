defmodule TrenurangCore.Repo.Migrations.CreateStoreRelationSettlements do
  use Ecto.Migration

  def change do
    create table(:store_relation_settlements) do
      add :relation_id, references(:store_relations, on_delete: :delete_all), null: false
      add :amount,      :decimal, null: false
      add :status,      :string, null: false, default: "pending"
      add :notes,       :text
      add :settled_at,  :utc_datetime

      timestamps()
    end

    create index(:store_relation_settlements, [:relation_id])
  end
end
