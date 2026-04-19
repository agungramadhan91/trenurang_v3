defmodule TrenurangCore.Repo.Migrations.AddStockTypeToProducts do
  use Ecto.Migration

  def change do
    alter table(:products) do
      add :stock_type, :string, null: false, default: "limited"
    end
  end
end
