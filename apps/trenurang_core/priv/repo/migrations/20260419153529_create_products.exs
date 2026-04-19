defmodule TrenurangCore.Repo.Migrations.CreateProducts do
  use Ecto.Migration

  def change do
    create table(:products) do
      add :store_id,    references(:stores, on_delete: :delete_all), null: false
      add :type,        :string, null: false
      add :name,        :string, null: false
      add :description, :text
      add :unit,        :string, null: false
      add :size,        :map, default: %{}
      add :stock,       :integer
      add :need_po,     :boolean, null: false, default: false
      add :price,       :decimal, null: false
      add :currency,    :string, null: false, default: "idr"
      add :status,      :string, null: false, default: "active"

      timestamps()
    end

    create index(:products, [:store_id])
  end
end
