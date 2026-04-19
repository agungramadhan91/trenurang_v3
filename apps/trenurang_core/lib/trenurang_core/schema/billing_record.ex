defmodule TrenurangCore.Schema.BillingRecord do
  use Ecto.Schema
  import Ecto.Changeset

  schema "billing_records" do
    field :type,   :string
    field :amount, :decimal
    field :status, :string, default: "pending"

    belongs_to :store, TrenurangCore.Schema.Store
    belongs_to :order, TrenurangCore.Schema.StoreOrder

    timestamps()
  end

  @valid_types ~w(commission contact_unlock subscription)
  @valid_statuses ~w(pending paid)

  def changeset(record, attrs) do
    record
    |> cast(attrs, [:store_id, :order_id, :type, :amount, :status])
    |> validate_required([:store_id, :type, :amount])
    |> validate_inclusion(:type, @valid_types)
    |> validate_inclusion(:status, @valid_statuses)
    |> validate_number(:amount, greater_than: 0)
  end
end
