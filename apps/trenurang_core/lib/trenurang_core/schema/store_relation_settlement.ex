defmodule TrenurangCore.Schema.StoreRelationSettlement do
  use Ecto.Schema
  import Ecto.Changeset

  schema "store_relation_settlements" do
    field :amount,      :decimal
    field :status,      :string, default: "pending"
    field :notes,       :string
    field :settled_at,  :utc_datetime

    belongs_to :relation, TrenurangCore.Schema.StoreRelation

    timestamps()
  end

  @valid_statuses ~w(pending paid cancelled)

  def changeset(settlement, attrs) do
    settlement
    |> cast(attrs, [:relation_id, :amount, :status, :notes, :settled_at])
    |> validate_required([:relation_id, :amount])
    |> validate_number(:amount, greater_than: 0)
    |> validate_inclusion(:status, @valid_statuses)
  end
end
