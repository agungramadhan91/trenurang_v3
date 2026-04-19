defmodule TrenurangCore.Repo.Migrations.CreateTrustScores do
  use Ecto.Migration

  def change do
    create table(:trust_scores) do
      add :user_id,        references(:users, on_delete: :delete_all), null: false
      add :score,          :decimal, null: false, default: 5.0
      add :on_time_count,  :integer, null: false, default: 0
      add :late_count,     :integer, null: false, default: 0
      add :dispute_raised, :integer, null: false, default: 0
      add :dispute_lost,   :integer, null: false, default: 0

      timestamps()
    end

    create unique_index(:trust_scores, [:user_id])
  end
end
