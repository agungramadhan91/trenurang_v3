defmodule TrenurangCore.Schema.Dispute do
  use Ecto.Schema
  import Ecto.Changeset

  schema "disputes" do
    field :reason,      :string
    field :evidence,    {:array, :map}, default: []
    field :status,      :string, default: "open"
    field :resolution,  :string
    field :resolved_at, :utc_datetime

    belongs_to :order,   TrenurangCore.Schema.StoreOrder
    belongs_to :raised_by, TrenurangCore.Schema.User
    belongs_to :against,   TrenurangCore.Schema.User

    timestamps()
  end

  @valid_statuses ~w(open under_review resolved dismissed)

  def changeset(dispute, attrs) do
    dispute
    |> cast(attrs, [:order_id, :raised_by_id, :against_id, :reason, :evidence, :status,
                    :resolution, :resolved_at])
    |> validate_required([:order_id, :raised_by_id, :against_id, :reason])
    |> validate_inclusion(:status, @valid_statuses)
  end
end
