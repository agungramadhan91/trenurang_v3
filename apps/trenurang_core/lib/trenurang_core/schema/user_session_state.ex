defmodule TrenurangCore.Schema.UserSessionState do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_session_states" do
    field :active_flow,    :map
    field :route_current,  :string
    field :route_previous, :string

    belongs_to :user, TrenurangCore.Schema.User

    timestamps()
  end

  def changeset(state, attrs) do
    state
    |> cast(attrs, [:user_id, :active_flow, :route_current, :route_previous])
    |> validate_required([:user_id])
    |> unique_constraint(:user_id)
  end
end
