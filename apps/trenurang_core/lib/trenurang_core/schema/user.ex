defmodule TrenurangCore.Schema.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :name,        :string
    field :username,    :string
    field :email,       :string
    field :lang,        :string, default: "id"
    field :verified_at, :utc_datetime
    field :status,      :string, default: "active"

    has_one  :persona,          TrenurangCore.Schema.UserPersona
    has_many :locations,        TrenurangCore.Schema.UserLocation
    has_many :stores,           TrenurangCore.Schema.Store, foreign_key: :owner_id
    has_many :channel_identities, TrenurangCore.Schema.ChannelIdentity
    has_one  :user_trust_score, TrenurangCore.Schema.UserTrustScore
    has_one  :session_state,    TrenurangCore.Schema.UserSessionState

    timestamps()
  end

  @valid_langs ~w(id en zh de ar ru)
  @valid_statuses ~w(active inactive)

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :username, :email, :lang, :verified_at, :status])
    |> validate_required([:name, :username])
    |> validate_length(:name, min: 2, max: 30)
    |> validate_length(:username, min: 3, max: 30)
    |> validate_format(:username, ~r/^[a-z][a-z0-9_]*$/, message: "harus diawali huruf, hanya a-z/0-9/_")
    |> validate_no_double_underscore()
    |> validate_max_words(:name, 3)
    |> validate_not_reserved(:name)
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+\.[^\s]+$/, message: "format email tidak valid")
    |> validate_inclusion(:lang, @valid_langs)
    |> validate_inclusion(:status, @valid_statuses)
    |> unique_constraint(:username)
    |> unique_constraint(:email)
  end

  defp validate_no_double_underscore(changeset) do
    validate_change(changeset, :username, fn :username, val ->
      if String.contains?(val, "__"), do: [username: "tidak boleh mengandung __"], else: []
    end)
  end

  defp validate_max_words(changeset, field, max) do
    validate_change(changeset, field, fn ^field, val ->
      word_count = val |> String.split() |> length()
      if word_count > max, do: [{field, "maksimal #{max} kata"}], else: []
    end)
  end

  @reserved_words ~w(start halo hai help about admin trenurang test oke ok hey)
  defp validate_not_reserved(changeset, field) do
    validate_change(changeset, field, fn ^field, val ->
      if String.downcase(val) in @reserved_words,
        do: [{field, "nama tidak valid"}],
        else: []
    end)
  end
end
