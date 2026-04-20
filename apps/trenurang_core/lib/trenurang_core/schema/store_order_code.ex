defmodule TrenurangCore.Schema.StoreOrderCode do
  use Ecto.Schema
  import Ecto.Changeset

  schema "store_order_codes" do
    field :code,       :string
    field :valid_date, :date
    field :used_at,    :utc_datetime
    field :is_golden, :boolean, default: false

    belongs_to :reward, TrenurangCore.Schema.StoreReward
    belongs_to :store, TrenurangCore.Schema.Store
    belongs_to :order, TrenurangCore.Schema.StoreOrder

    timestamps()
  end

  def changeset(code, attrs) do
    code
    |> cast(attrs, [:store_id, :code, :valid_date, :used_at, :order_id, :is_golden, :reward_id])
    |> validate_required([:store_id, :code, :valid_date])
    |> validate_length(:code, is: 6)
    |> unique_constraint(:code, name: :store_order_codes_store_id_code_valid_date_index)
    |> foreign_key_constraint(:reward_id)
  end
end
