defmodule TrenurangCore.Schema.StoreChat do
  use Ecto.Schema
  import Ecto.Changeset

  schema "store_chats" do
    field :message, :string

    belongs_to :sender,   TrenurangCore.Schema.User
    belongs_to :receiver, TrenurangCore.Schema.User
    belongs_to :order,    TrenurangCore.Schema.StoreOrder
    belongs_to :relation, TrenurangCore.Schema.StoreRelation

    timestamps()
  end

  def changeset(chat, attrs) do
    chat
    |> cast(attrs, [:sender_id, :receiver_id, :order_id, :relation_id, :message])
    |> validate_required([:sender_id, :receiver_id, :message])
    |> validate_length(:message, min: 1, max: 4000)
  end
end
