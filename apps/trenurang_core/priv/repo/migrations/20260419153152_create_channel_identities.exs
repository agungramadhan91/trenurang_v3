defmodule TrenurangCore.Repo.Migrations.CreateChannelIdentities do
  use Ecto.Migration

  def change do
    create table(:channel_identities) do
      add :channel,      :string,   null: false
      add :channel_id,   :string,   null: false
      add :user_id,      references(:users, on_delete: :nilify_all)
      add :first_seen_at, :utc_datetime, null: false
      add :last_seen_at,  :utc_datetime, null: false

      timestamps()
    end

    create unique_index(:channel_identities, [:channel, :channel_id])
    create index(:channel_identities, [:user_id])
  end
end
