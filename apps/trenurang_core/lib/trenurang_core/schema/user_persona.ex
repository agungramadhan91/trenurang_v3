defmodule TrenurangCore.Schema.UserPersona do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_persona" do
    field :roles,           {:array, :map}, default: []
    field :needs,           {:array, :map}, default: []
    field :skills,          {:array, :string}, default: []
    field :budget_range,    :map, default: %{}
    field :prompted_fields, {:array, :string}, default: []
    field :persona_consent, :boolean, default: false
    field :activity_log,    {:array, :map}, default: []

    belongs_to :user, TrenurangCore.Schema.User

    timestamps()
  end

  @permitted [:user_id, :roles, :needs, :skills, :budget_range,
              :prompted_fields, :persona_consent, :activity_log]

  def changeset(persona, attrs) do
    persona
    |> cast(attrs, @permitted)
    |> validate_required([:user_id])
  end
end
