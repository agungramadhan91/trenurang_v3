defmodule TrenurangCore.Schema.ChatBlock do
  use Ecto.Schema
  import Ecto.Changeset

  schema "chat_blocks" do
    belongs_to :user,          TrenurangCore.Schema.User
    belongs_to :blocked_store, TrenurangCore.Schema.Store

    timestamps()
  end

  def changeset(block, attrs) do
    block
    |> cast(attrs, [:user_id, :blocked_store_id])
    |> validate_required([:user_id])
  end
end
