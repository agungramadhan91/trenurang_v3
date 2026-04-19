defmodule TrenurangCore.Repo.Migrations.CreateChatBlocks do
  use Ecto.Migration

  def change do
    create table(:chat_blocks) do
      add :user_id,         references(:users, on_delete: :delete_all), null: false
      add :blocked_store_id, references(:stores, on_delete: :delete_all)

      timestamps()
    end

    create index(:chat_blocks, [:user_id, :blocked_store_id])
  end
end
