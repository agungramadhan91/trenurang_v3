defmodule TrenurangCore.Repo.Migrations.CreateStoreLocations do
  use Ecto.Migration

  def change do
    create table(:store_locations) do
      add :store_id,       references(:stores, on_delete: :delete_all), null: false
      add :label,          :string, null: false
      add :coordinates,    :geometry
      add :days,           {:array, :string}, default: []
      add :hours_start,    :integer
      add :hours_end,      :integer
      add :duration_type,  :string, null: false, default: "permanent"
      add :duration_value, :integer
      add :is_active,      :boolean, null: false, default: true

      timestamps()
    end

    create index(:store_locations, [:store_id])
  end
end
