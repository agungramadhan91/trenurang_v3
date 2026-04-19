defmodule TrenurangCore.Schema.StoreOrder do
  use Ecto.Schema
  import Ecto.Changeset

  schema "store_orders" do
    field :type,          :string
    field :status,        :string, default: "pending"
    field :need_delivery, :boolean, default: false

    belongs_to :buyer,    TrenurangCore.Schema.User
    belongs_to :seller,   TrenurangCore.Schema.User
    belongs_to :relation, TrenurangCore.Schema.StoreRelation
    has_many   :items,    TrenurangCore.Schema.StoreOrderItem,   foreign_key: :order_id
    has_one    :payment,  TrenurangCore.Schema.StoreOrderPayment, foreign_key: :order_id
    timestamps()
  end

  @valid_types ~w(b2c walkin konsinyasi beli_putus kontrak_jasa)
  @valid_statuses ~w(pending confirmed completed disputed cancelled)

  def changeset(order, attrs) do
    order
    |> cast(attrs, [:type, :buyer_id, :seller_id, :relation_id, :status, :need_delivery])
    |> validate_required([:type, :seller_id])
    |> validate_inclusion(:type, @valid_types)
    |> validate_inclusion(:status, @valid_statuses)
    |> validate_buyer_required()
  end

  defp validate_buyer_required(changeset) do
    case get_field(changeset, :type) do
      "b2c" ->
        validate_required(changeset, [:buyer_id])
      _ ->
        changeset
    end
  end
end
