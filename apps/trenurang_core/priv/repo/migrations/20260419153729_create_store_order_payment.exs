defmodule TrenurangCore.Repo.Migrations.CreateStoreOrderPayment do
  use Ecto.Migration

  def change do
    create table(:store_order_payment) do
      add :order_id,   references(:store_orders, on_delete: :delete_all), null: false
      add :method,     :string, null: false
      add :via,        :string
      add :send_to,    references(:users, on_delete: :restrict), null: false
      add :due_date,   :utc_datetime
      add :status,     :string, null: false, default: "pending"

      timestamps()
    end

    create index(:store_order_payment, [:order_id])
    create index(:store_order_payment, [:status])
  end
end
