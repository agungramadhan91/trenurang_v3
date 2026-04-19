defmodule TrenurangCore.Repo.Migrations.CreateStoreOrderItems do
  use Ecto.Migration

  def change do
    create table(:store_order_items) do
      add :order_id,   references(:store_orders, on_delete: :delete_all), null: false
      add :product_id, references(:products, on_delete: :restrict), null: false
      add :qty,        :integer, null: false
      add :price,      :decimal, null: false
      add :status,     :string, null: false, default: "sold"

      timestamps()
    end

    create index(:store_order_items, [:order_id])
    create index(:store_order_items, [:product_id])
  end
end
