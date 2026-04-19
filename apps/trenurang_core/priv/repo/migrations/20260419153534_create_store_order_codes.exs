defmodule TrenurangCore.Repo.Migrations.CreateStoreOrderCodes do
  use Ecto.Migration

  def change do
    create table(:store_order_codes) do
      add :store_id,   references(:stores, on_delete: :delete_all), null: false
      add :code,       :string, null: false
      add :valid_date, :date, null: false
      add :used_at,    :utc_datetime
      add :order_id,   :integer

      timestamps()
    end

    create unique_index(:store_order_codes, [:store_id, :code, :valid_date])
    create index(:store_order_codes, [:store_id, :valid_date])
  end
end
