defmodule TrenurangCore.Schema.UserTrustScore do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_trust_scores" do
    field :score,                :integer, default: 350
    field :tier,                 :string,  default: "pemula_aktif"
    field :is_cold_start,        :boolean, default: true
    field :payment_on_time_rate, :decimal, default: 0
    field :cancellation_rate,    :decimal, default: 0
    field :dispute_ratio,        :decimal, default: 0
    field :longevity,            :decimal, default: 0
    field :on_time_count,        :integer, default: 0
    field :late_count,           :integer, default: 0
    field :cancel_count,         :integer, default: 0
    field :total_order_count,    :integer, default: 0
    field :dispute_raised,       :integer, default: 0
    field :dispute_lost,         :integer, default: 0
    field :cold_start_ends_at,   :date
    field :last_recalculated_at, :utc_datetime

    belongs_to :user, TrenurangCore.Schema.User

    timestamps()
  end

  @valid_tiers ~w(belum_teruji pemula_aktif pedagang_tumbuh pedagang_andal juragan)

  def changeset(ts, attrs) do
    ts
    |> cast(attrs, [:user_id, :score, :tier, :is_cold_start,
                    :payment_on_time_rate, :cancellation_rate, :dispute_ratio, :longevity,
                    :on_time_count, :late_count, :cancel_count, :total_order_count,
                    :dispute_raised, :dispute_lost, :cold_start_ends_at, :last_recalculated_at])
    |> validate_required([:user_id, :score, :tier, :is_cold_start, :cold_start_ends_at])
    |> validate_inclusion(:tier, @valid_tiers)
    |> validate_number(:score, greater_than_or_equal_to: 0, less_than_or_equal_to: 1000)
    |> unique_constraint(:user_id)
    |> foreign_key_constraint(:user_id)
  end
end
