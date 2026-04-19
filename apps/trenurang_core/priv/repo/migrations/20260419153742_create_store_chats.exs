defmodule TrenurangCore.Repo.Migrations.CreateStoreChats do
  use Ecto.Migration

  def change do
    create table(:store_chats) do
      add :sender_id,   references(:users, on_delete: :delete_all), null: false
      add :receiver_id, references(:users, on_delete: :delete_all), null: false
      add :order_id,    references(:store_orders, on_delete: :nilify_all)
      add :relation_id, references(:store_relations, on_delete: :nilify_all)
      add :message,     :text, null: false

      timestamps()
    end

    create index(:store_chats, [:sender_id])
    create index(:store_chats, [:receiver_id])
    create index(:store_chats, [:order_id])
  end
end
