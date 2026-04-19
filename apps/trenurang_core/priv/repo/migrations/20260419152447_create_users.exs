defmodule TrenurangCore.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :name,        :string,  null: false
      add :username,    :string,  null: false
      add :email,       :string
      add :lang,        :string,  null: false, default: "id"
      add :verified_at, :utc_datetime
      add :status,      :string,  null: false, default: "active"

      timestamps()
    end

    create unique_index(:users, [:username])
    create unique_index(:users, [:email])
  end
end
