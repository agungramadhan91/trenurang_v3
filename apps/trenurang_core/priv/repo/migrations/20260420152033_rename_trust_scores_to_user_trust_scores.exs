defmodule TrenurangCore.Repo.Migrations.RenameTrustScoresToUserTrustScores do
  use Ecto.Migration

  def up do
    # 1. Rename table
    rename table(:trust_scores), to: table(:user_trust_scores)

    # 2. Alter existing columns
    alter table(:user_trust_scores) do
      modify :score, :integer, null: false, default: 350
      add :tier,                 :string,  null: false, default: "pemula_aktif"
      add :is_cold_start,        :boolean, null: false, default: true
      add :payment_on_time_rate, :decimal, null: false, default: 0
      add :cancellation_rate,    :decimal, null: false, default: 0
      add :dispute_ratio,        :decimal, null: false, default: 0
      add :longevity,            :decimal, null: false, default: 0
      add :cancel_count,         :integer, null: false, default: 0
      add :total_order_count,    :integer, null: false, default: 0
      add :cold_start_ends_at,   :date
      add :last_recalculated_at, :utc_datetime
    end

    # 3. Backfill cold_start_ends_at = inserted_at + 3 bulan
    execute "UPDATE user_trust_scores SET cold_start_ends_at = (inserted_at + INTERVAL '3 months')::date"

    # 4. Set NOT NULL setelah backfill
    alter table(:user_trust_scores) do
      modify :cold_start_ends_at, :date, null: false
    end

    # 5. Rename index lama
    drop_if_exists unique_index(:trust_scores, [:user_id])
    create unique_index(:user_trust_scores, [:user_id])
  end

  def down do
    drop unique_index(:user_trust_scores, [:user_id])

    alter table(:user_trust_scores) do
      remove :tier
      remove :is_cold_start
      remove :payment_on_time_rate
      remove :cancellation_rate
      remove :dispute_ratio
      remove :longevity
      remove :cancel_count
      remove :total_order_count
      remove :cold_start_ends_at
      remove :last_recalculated_at
      modify :score, :decimal, null: false, default: 5.0
    end

    rename table(:user_trust_scores), to: table(:trust_scores)
    create unique_index(:trust_scores, [:user_id])
  end
end
