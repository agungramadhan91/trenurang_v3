defmodule TrenurangCore.Repo.Migrations.CreateUserLocations do
  use Ecto.Migration

  def change do
    create table(:user_locations) do
      add :user_id,        references(:users, on_delete: :delete_all), null: false
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

    create index(:user_locations, [:user_id])
  end
end
