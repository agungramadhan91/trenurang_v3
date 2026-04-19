defmodule TrenurangCore.Repo.Migrations.CreateProductCarts do
  use Ecto.Migration

  def change do
    create table(:product_carts) do
      add :user_id,    references(:users, on_delete: :delete_all), null: false
      add :product_id, references(:products, on_delete: :delete_all), null: false
      add :quantity,   :integer, null: false

      timestamps()
    end

    create index(:product_carts, [:user_id])
    create unique_index(:product_carts, [:user_id, :product_id])
  end
end
