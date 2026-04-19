defmodule TrenurangCore.Repo.Migrations.CreateStores do
  use Ecto.Migration

  def change do
    create table(:stores) do
      add :owner_id,    references(:users, on_delete: :delete_all), null: false
      add :type,        :string, null: false
      add :name,        :string, null: false
      add :storename,   :string, null: false
      add :tier,        :string
      add :verified_at, :utc_datetime
      add :status,      :string, null: false, default: "active"

      timestamps()
    end

    create unique_index(:stores, [:storename])
    create index(:stores, [:owner_id])
  end
end
