defmodule TrenurangCore.Repo.Migrations.CreateStoreRelations do
  use Ecto.Migration

  def change do
    create table(:store_relations) do
      add :code,        :string, null: false
      add :supplier_id, references(:stores, on_delete: :delete_all), null: false
      add :receiver_id, references(:stores, on_delete: :delete_all), null: false
      add :type,        :string, null: false
      add :agreement,   :text
      add :transaction, :map, default: %{}

      timestamps()
    end

    create unique_index(:store_relations, [:code])
    create index(:store_relations, [:supplier_id])
    create index(:store_relations, [:receiver_id])
  end
end
