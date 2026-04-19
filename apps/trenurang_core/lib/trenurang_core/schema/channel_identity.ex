defmodule TrenurangCore.Schema.ChannelIdentity do
  use Ecto.Schema
  import Ecto.Changeset

  schema "channel_identities" do
    field :channel,       :string
    field :channel_id,    :string
    field :first_seen_at, :utc_datetime
    field :last_seen_at,  :utc_datetime

    belongs_to :user, TrenurangCore.Schema.User

    timestamps()
  end

  def changeset(identity, attrs) do
    identity
    |> cast(attrs, [:channel, :channel_id, :user_id, :first_seen_at, :last_seen_at])
    |> validate_required([:channel, :channel_id, :first_seen_at, :last_seen_at])
    |> unique_constraint(:channel_id, name: :channel_identities_channel_channel_id_index)
  end
end
