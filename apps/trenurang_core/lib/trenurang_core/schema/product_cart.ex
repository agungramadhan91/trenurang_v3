defmodule TrenurangCore.Schema.ProductCart do
  use Ecto.Schema
  import Ecto.Changeset

  schema "product_carts" do
    field :quantity, :integer

    belongs_to :user,    TrenurangCore.Schema.User
    belongs_to :product, TrenurangCore.Schema.Product

    timestamps()
  end

  def changeset(cart, attrs) do
    cart
    |> cast(attrs, [:user_id, :product_id, :quantity])
    |> validate_required([:user_id, :product_id, :quantity])
    |> validate_number(:quantity, greater_than: 0)
    |> unique_constraint(:product_id, name: :product_carts_user_id_product_id_index)
  end
end
