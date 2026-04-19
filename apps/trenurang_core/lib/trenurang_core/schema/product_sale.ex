defmodule TrenurangCore.Schema.ProductSale do
  use Ecto.Schema
  import Ecto.Changeset

  schema "product_sales" do
    field :qty, :integer

    belongs_to :store,   TrenurangCore.Schema.Store
    belongs_to :product, TrenurangCore.Schema.Product

    timestamps()
  end

  def changeset(sale, attrs) do
    sale
    |> cast(attrs, [:store_id, :product_id, :qty])
    |> validate_required([:store_id, :product_id, :qty])
    |> validate_number(:qty, greater_than: 0)
  end
end
