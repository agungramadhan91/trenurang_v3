defmodule TrenurangCore.Repo.Migrations.CreateProductSales do
  use Ecto.Migration

  def change do
    create table(:product_sales) do
      add :store_id,   references(:stores, on_delete: :delete_all), null: false
      add :product_id, references(:products, on_delete: :delete_all), null: false
      add :qty,        :integer, null: false

      timestamps()
    end

    create index(:product_sales, [:store_id])
    create index(:product_sales, [:product_id])
  end
end
