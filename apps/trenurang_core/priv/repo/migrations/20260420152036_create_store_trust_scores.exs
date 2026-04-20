defmodule TrenurangCore.Repo.Migrations.CreateStoreTrustScores do
  use Ecto.Migration

  def change do
    create table(:store_trust_scores) do
      add :store_id,            references(:stores, on_delete: :delete_all), null: false
      add :score,               :integer, null: false, default: 350
      add :tier,                :string,  null: false, default: "pemula_aktif"
      add :is_cold_start,       :boolean, null: false, default: true
      # Komponen formula
      add :payment_reliability, :decimal, null: false, default: 0
      add :fulfillment_rate,    :decimal, null: false, default: 0
      add :repeat_buyer_rate,   :decimal, null: false, default: 0
      add :dispute_ratio,       :decimal, null: false, default: 0
      add :network_breadth,     :decimal, null: false, default: 0
      add :longevity,           :decimal, null: false, default: 0
      add :growth_trend,        :decimal
      # Raw counters
      add :on_time_count,       :integer, null: false, default: 0
      add :late_count,          :integer, null: false, default: 0
      add :completed_count,     :integer, null: false, default: 0
      add :cancelled_count,     :integer, null: false, default: 0
      add :repeat_buyer_count,  :integer, null: false, default: 0
      add :total_unique_buyers, :integer, null: false, default: 0
      add :dispute_raised,      :integer, null: false, default: 0
      add :dispute_lost,        :integer, null: false, default: 0
      add :unique_partners,     :integer, null: false, default: 0
      add :cold_start_ends_at,  :date, null: false
      add :last_recalculated_at, :utc_datetime

      timestamps()
    end

    create unique_index(:store_trust_scores, [:store_id])
  end
end
