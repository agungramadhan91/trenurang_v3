defmodule TrenurangCore.Repo.Migrations.CreateUserSessionStates do
  use Ecto.Migration

  def change do
    create table(:user_session_states) do
      add :user_id,        references(:users, on_delete: :delete_all), null: false
      add :active_flow,    :map
      add :route_current,  :string
      add :route_previous, :string

      timestamps()
    end

    create unique_index(:user_session_states, [:user_id])
  end
end
