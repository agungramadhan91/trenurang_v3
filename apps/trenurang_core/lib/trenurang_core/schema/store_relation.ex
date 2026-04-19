defmodule TrenurangCore.Schema.StoreRelation do
  use Ecto.Schema
  import Ecto.Changeset

  schema "store_relations" do
    field :code,        :string
    field :type,        :string
    field :agreement,   :string
    field :transaction, :map, default: %{}

    belongs_to :supplier, TrenurangCore.Schema.Store
    belongs_to :receiver, TrenurangCore.Schema.Store
    has_many   :settlements, TrenurangCore.Schema.StoreRelationSettlement, foreign_key: :relation_id

    timestamps()
  end

  @valid_types ~w(konsinyasi beli_putus kontrak_jasa)

  def changeset(relation, attrs) do
    relation
    |> cast(attrs, [:code, :supplier_id, :receiver_id, :type, :agreement, :transaction])
    |> validate_required([:code, :supplier_id, :receiver_id, :type])
    |> validate_inclusion(:type, @valid_types)
    |> unique_constraint(:code)
  end
end
