defmodule TrenurangCore.Repo.Migrations.CreateStoreOrders do
  use Ecto.Migration

  def change do
    create table(:store_orders) do
      add :type,            :string, null: false
      add :buyer_id,        references(:users, on_delete: :nilify_all)
      add :seller_id,       references(:users, on_delete: :restrict), null: false
      add :relation_id,     references(:store_relations, on_delete: :nilify_all)
      add :status,          :string, null: false, default: "pending"
      add :need_delivery,   :boolean, null: false, default: false

      timestamps()
    end

    create index(:store_orders, [:buyer_id])
    create index(:store_orders, [:seller_id])
    create index(:store_orders, [:relation_id])
    create index(:store_orders, [:status])
  end
end
