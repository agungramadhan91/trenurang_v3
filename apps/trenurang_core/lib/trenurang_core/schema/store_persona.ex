defmodule TrenurangCore.Schema.StorePersona do
  use Ecto.Schema
  import Ecto.Changeset

  schema "store_persona" do
    field :info,        :map, default: %{}
    field :notes,       :map, default: %{}
    field :schedule,    {:array, :map}, default: []
    field :transaction, {:array, :map}, default: []
    field :profit,      {:array, :map}, default: []
    field :liabilities, {:array, :map}, default: []

    belongs_to :store, TrenurangCore.Schema.Store

    timestamps()
  end

  def changeset(persona, attrs) do
    persona
    |> cast(attrs, [:store_id, :info, :notes, :schedule, :transaction, :profit, :liabilities])
    |> validate_required([:store_id])
  end
end
