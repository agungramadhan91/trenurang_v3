defmodule TrenurangCore.Schema.StoreReward do
  use Ecto.Schema
  import Ecto.Changeset

  schema "store_rewards" do
    field :type,          :string
    field :description,   :string
    field :value,         :map
    field :claim_deadline, :date
    field :total_codes,   :integer
    field :claimed_count, :integer, default: 0
    field :batch_date,    :date
    field :status,        :string, default: "active"

    belongs_to :store, TrenurangCore.Schema.Store

    timestamps()
  end

  @valid_types ~w(discount referral cashback early_access badge)
  @valid_statuses ~w(active expired exhausted)

  def changeset(reward, attrs) do
    reward
    |> cast(attrs, [:store_id, :type, :description, :value, :claim_deadline,
                    :total_codes, :claimed_count, :batch_date, :status])
    |> validate_required([:store_id, :type, :description, :value,
                          :claim_deadline, :total_codes, :batch_date])
    |> validate_inclusion(:type, @valid_types)
    |> validate_inclusion(:status, @valid_statuses)
    |> validate_number(:total_codes, greater_than: 0)
    |> validate_number(:claimed_count, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:store_id)
  end
end
