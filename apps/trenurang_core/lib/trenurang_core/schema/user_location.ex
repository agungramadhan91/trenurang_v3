defmodule TrenurangCore.Schema.UserLocation do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_locations" do
    field :label,          :string
    field :coordinates,    Geo.PostGIS.Geometry
    field :days,           {:array, :string}, default: []
    field :hours_start,    :integer
    field :hours_end,      :integer
    field :duration_type,  :string, default: "permanent"
    field :duration_value, :integer
    field :is_active,      :boolean, default: true

    belongs_to :user, TrenurangCore.Schema.User

    timestamps()
  end

  @valid_days ~w(senin selasa rabu kamis jumat sabtu minggu)
  @valid_duration_types ~w(permanent weeks)

  def changeset(loc, attrs) do
    loc
    |> cast(attrs, [:user_id, :label, :coordinates, :days, :hours_start, :hours_end,
                    :duration_type, :duration_value, :is_active])
    |> validate_required([:user_id, :label, :coordinates, :duration_type])
    |> validate_subset(:days, @valid_days)
    |> validate_inclusion(:duration_type, @valid_duration_types)
    |> validate_number(:hours_start, greater_than_or_equal_to: 0, less_than: 24)
    |> validate_number(:hours_end, greater_than_or_equal_to: 0, less_than: 24)
  end
end
