defmodule TrenurangCore.Schema.StoreTrustScore do
  use Ecto.Schema
  import Ecto.Changeset

  schema "store_trust_scores" do
    field :score,                :integer, default: 350
    field :tier,                 :string,  default: "pemula_aktif"
    field :is_cold_start,        :boolean, default: true
    field :payment_reliability,  :decimal, default: 0
    field :fulfillment_rate,     :decimal, default: 0
    field :repeat_buyer_rate,    :decimal, default: 0
    field :dispute_ratio,        :decimal, default: 0
    field :network_breadth,      :decimal, default: 0
    field :longevity,            :decimal, default: 0
    field :growth_trend,         :decimal
    field :on_time_count,        :integer, default: 0
    field :late_count,           :integer, default: 0
    field :completed_count,      :integer, default: 0
    field :cancelled_count,      :integer, default: 0
    field :repeat_buyer_count,   :integer, default: 0
    field :total_unique_buyers,  :integer, default: 0
    field :dispute_raised,       :integer, default: 0
    field :dispute_lost,         :integer, default: 0
    field :unique_partners,      :integer, default: 0
    field :cold_start_ends_at,   :date
    field :last_recalculated_at, :utc_datetime

    belongs_to :store, TrenurangCore.Schema.Store

    timestamps()
  end

  @valid_tiers ~w(belum_teruji pemula_aktif pedagang_tumbuh pedagang_andal juragan)

  def changeset(ts, attrs) do
    ts
    |> cast(attrs, [:store_id, :score, :tier, :is_cold_start,
                    :payment_reliability, :fulfillment_rate, :repeat_buyer_rate,
                    :dispute_ratio, :network_breadth, :longevity, :growth_trend,
                    :on_time_count, :late_count, :completed_count, :cancelled_count,
                    :repeat_buyer_count, :total_unique_buyers, :dispute_raised,
                    :dispute_lost, :unique_partners, :cold_start_ends_at, :last_recalculated_at])
    |> validate_required([:store_id, :score, :tier, :is_cold_start, :cold_start_ends_at])
    |> validate_inclusion(:tier, @valid_tiers)
    |> validate_number(:score, greater_than_or_equal_to: 0, less_than_or_equal_to: 1000)
    |> unique_constraint(:store_id)
    |> foreign_key_constraint(:store_id)
  end
end
