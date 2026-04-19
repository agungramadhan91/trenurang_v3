defmodule TrenurangCore.Schema.Store do
  use Ecto.Schema
  import Ecto.Changeset

  schema "stores" do
    field :type,        :string
    field :name,        :string
    field :storename,   :string
    field :tier,        :string
    field :verified_at, :utc_datetime
    field :status,      :string, default: "active"

    belongs_to :owner, TrenurangCore.Schema.User
    has_one    :persona,   TrenurangCore.Schema.StorePersona
    has_many   :locations, TrenurangCore.Schema.StoreLocation
    has_many   :products,  TrenurangCore.Schema.Product

    timestamps()
  end

  @valid_types ~w(good service mix)
  @valid_statuses ~w(active inactive)

  def changeset(store, attrs) do
    store
    |> cast(attrs, [:owner_id, :type, :name, :storename, :tier, :verified_at, :status])
    |> validate_required([:owner_id, :type, :name, :storename])
    |> validate_inclusion(:type, @valid_types)
    |> validate_inclusion(:status, @valid_statuses)
    |> validate_length(:storename, min: 3, max: 35)
    |> validate_format(:storename, ~r/^[a-z][a-z0-9_]*_store$/, message: "format: nama_store")
    |> unique_constraint(:storename)
  end
end
