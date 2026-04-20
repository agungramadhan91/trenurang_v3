defmodule TrenurangCore.Repo.Migrations.CreateStoreRewards do
  use Ecto.Migration

  def change do
    create table(:store_rewards) do
      add :store_id,       references(:stores, on_delete: :delete_all), null: false
      add :type,           :string, null: false
      add :description,    :text, null: false
      add :value,          :map, null: false
      add :claim_deadline, :date, null: false
      add :total_codes,    :integer, null: false
      add :claimed_count,  :integer, null: false, default: 0
      add :batch_date,     :date, null: false
      add :status,         :string, null: false, default: "active"

      timestamps()
    end

    create index(:store_rewards, [:store_id])
    create index(:store_rewards, [:status])
    create index(:store_rewards, [:batch_date])
  end
end
