defmodule TrenurangCore.Schema.UserPersona do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_persona" do
    field :activity_log, {:array, :map}, default: []

    belongs_to :user, TrenurangCore.Schema.User

    timestamps()
  end

  def changeset(persona, attrs) do
    persona
    |> cast(attrs, [:user_id, :activity_log])
    |> validate_required([:user_id])
  end
end
