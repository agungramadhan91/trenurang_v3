defmodule TrenurangCore.Repo.Migrations.CreateDisputes do
  use Ecto.Migration

  def change do
    create table(:disputes) do
      add :order_id,   references(:store_orders, on_delete: :restrict), null: false
      add :raised_by,  references(:users, on_delete: :restrict), null: false
      add :against_id, references(:users, on_delete: :restrict), null: false
      add :reason,     :text, null: false
      add :evidence,   {:array, :map}, default: []
      add :status,     :string, null: false, default: "open"
      add :resolution, :text
      add :resolved_at, :utc_datetime

      timestamps()
    end

    create index(:disputes, [:order_id])
    create index(:disputes, [:status])
  end
end
