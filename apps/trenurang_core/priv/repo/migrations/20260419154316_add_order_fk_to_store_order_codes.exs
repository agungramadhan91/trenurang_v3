defmodule TrenurangCore.Repo.Migrations.AddOrderFkToStoreOrderCodes do
  use Ecto.Migration

  def change do
    alter table(:store_order_codes) do
      modify :order_id, references(:store_orders, on_delete: :nilify_all)
    end
  end
end
