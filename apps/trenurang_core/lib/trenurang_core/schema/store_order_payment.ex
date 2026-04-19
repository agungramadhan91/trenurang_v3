defmodule TrenurangCore.Schema.StoreOrderPayment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "store_order_payment" do
    field :method,   :string
    field :via,      :string
    field :due_date, :utc_datetime
    field :status,   :string, default: "pending"

    belongs_to :order,   TrenurangCore.Schema.StoreOrder
    belongs_to :send_to, TrenurangCore.Schema.User

    timestamps()
  end

  @valid_methods ~w(cash hutang transfer ewallet)
  @valid_statuses ~w(pending paid overdue cancelled)

  def changeset(payment, attrs) do
    payment
    |> cast(attrs, [:order_id, :method, :via, :send_to_id, :due_date, :status])
    |> validate_required([:order_id, :method, :send_to_id])
    |> validate_inclusion(:method, @valid_methods)
    |> validate_inclusion(:status, @valid_statuses)
    |> validate_hutang_due_date()
  end

  defp validate_hutang_due_date(changeset) do
    case get_field(changeset, :method) do
      "hutang" -> validate_required(changeset, [:due_date])
      _ -> changeset
    end
  end
end
