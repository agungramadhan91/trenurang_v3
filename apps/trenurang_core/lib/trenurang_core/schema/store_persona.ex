defmodule TrenurangCore.Schema.StorePersona do
  use Ecto.Schema
  import Ecto.Changeset

  schema "store_persona" do
    field :supply_needs,    {:array, :map}, default: []
    field :capacity,        :map, default: %{}
    field :target_customer, :map, default: %{}
    field :expansion_needs, {:array, :map}, default: []
    field :prompted_fields, {:array, :string}, default: []
    field :info,            :map, default: %{}
    field :notes,           :map, default: %{}
    field :schedule,        {:array, :map}, default: []
    field :transaction,     {:array, :map}, default: []
    field :profit,          {:array, :map}, default: []
    field :liabilities,     {:array, :map}, default: []

    belongs_to :store, TrenurangCore.Schema.Store

    timestamps()
  end

  @permitted [:store_id, :supply_needs, :capacity, :target_customer,
              :expansion_needs, :prompted_fields, :info, :notes,
              :schedule, :transaction, :profit, :liabilities]

  def changeset(persona, attrs) do
    persona
    |> cast(attrs, @permitted)
    |> validate_required([:store_id])
  end
end
