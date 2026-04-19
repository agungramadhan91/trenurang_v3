defmodule TrenurangCore.Schema.StoreOrderItem do
  use Ecto.Schema
  import Ecto.Changeset

  schema "store_order_items" do
    field :qty,    :integer
    field :price,  :decimal
    field :status, :string, default: "sold"

    belongs_to :order,   TrenurangCore.Schema.StoreOrder
    belongs_to :product, TrenurangCore.Schema.Product

    timestamps()
  end

  @valid_statuses ~w(sold returned)

  def changeset(item, attrs) do
    item
    |> cast(attrs, [:order_id, :product_id, :qty, :price, :status])
    |> validate_required([:order_id, :product_id, :qty, :price])
    |> validate_number(:qty, greater_than: 0)
    |> validate_number(:price, greater_than_or_equal_to: 0)
    |> validate_inclusion(:status, @valid_statuses)
  end
end
