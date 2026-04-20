defmodule TrenurangCore.Repo.Migrations.AddGoldenFieldsToStoreOrderCodes do
  use Ecto.Migration

  def change do
    alter table(:store_order_codes) do
      add :is_golden, :boolean, null: false, default: false
      add :reward_id, references(:store_rewards, on_delete: :nilify_all)
    end

    create index(:store_order_codes, [:reward_id])
  end
end
