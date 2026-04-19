defmodule TrenurangCore.Repo.Migrations.CreateBillingRecords do
  use Ecto.Migration

  def change do
    create table(:billing_records) do
      add :store_id,  references(:stores, on_delete: :restrict), null: false
      add :order_id,  references(:store_orders, on_delete: :nilify_all)
      add :type,      :string, null: false
      add :amount,    :decimal, null: false
      add :status,    :string, null: false, default: "pending"

      timestamps()
    end

    create index(:billing_records, [:store_id])
    create index(:billing_records, [:status])
  end
end
