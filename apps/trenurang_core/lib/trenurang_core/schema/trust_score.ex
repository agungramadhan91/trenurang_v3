defmodule TrenurangCore.Schema.TrustScore do
  use Ecto.Schema
  import Ecto.Changeset

  schema "trust_scores" do
    field :score,          :decimal, default: 5.0
    field :on_time_count,  :integer, default: 0
    field :late_count,     :integer, default: 0
    field :dispute_raised, :integer, default: 0
    field :dispute_lost,   :integer, default: 0

    belongs_to :user, TrenurangCore.Schema.User

    timestamps()
  end

  def changeset(ts, attrs) do
    ts
    |> cast(attrs, [:user_id, :score, :on_time_count, :late_count, :dispute_raised, :dispute_lost])
    |> validate_required([:user_id, :score])
    |> validate_number(:score, greater_than_or_equal_to: 0, less_than_or_equal_to: 10)
    |> unique_constraint(:user_id)
  end
end
