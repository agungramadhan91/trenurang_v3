defmodule TrenurangCore.Schema.Product do
  use Ecto.Schema
  import Ecto.Changeset

  schema "products" do
    field :type,        :string
    field :name,        :string
    field :description, :string
    field :unit,        :string
    field :size,        :map, default: %{}
    field :stock,       :integer
    field :stock_type,  :string, default: "limited"
    field :need_po,     :boolean, default: false
    field :price,       :decimal
    field :currency,    :string, default: "idr"
    field :status,      :string, default: "active"

    belongs_to :store, TrenurangCore.Schema.Store

    timestamps()
  end

  @valid_types ~w(good service)
  @valid_stock_types ~w(limited free unlimited)
  @valid_statuses ~w(active inactive)

  def changeset(product, attrs) do
    product
    |> cast(attrs, [:store_id, :type, :name, :description, :unit, :size, :stock,
                    :stock_type, :need_po, :price, :currency, :status])
    |> validate_required([:store_id, :type, :name, :unit, :price])
    |> validate_inclusion(:type, @valid_types)
    |> validate_inclusion(:stock_type, @valid_stock_types)
    |> validate_inclusion(:status, @valid_statuses)
    |> validate_stock()
    |> validate_number(:price, greater_than: 0)
  end

  defp validate_stock(changeset) do
    case get_field(changeset, :stock_type) do
      "limited" ->
        validate_required(changeset, [:stock])
        |> validate_number(:stock, greater_than_or_equal_to: 0)
      _ ->
        changeset
    end
  end
end
