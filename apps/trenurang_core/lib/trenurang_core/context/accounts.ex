defmodule TrenurangCore.Context.Accounts do
  @moduledoc """
  Context untuk manajemen akun: registrasi user, profil, dan lokasi.
  """

  import Ecto.Query
  alias TrenurangCore.Repo
  alias TrenurangCore.Schema.{User, UserLocation, ChannelIdentity}

  # ---- User ----

  @doc "Buat user baru. Translate unique constraint → atom error."
  def register_user(attrs) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
    |> translate_unique_errors()
  end

  @doc "Get user by ID. Nil jika tidak ada."
  def get_user(id), do: Repo.get(User, id)

  @doc "Get user by username. Nil jika tidak ada."
  def get_user_by_username(username), do: Repo.get_by(User, username: username)

  @doc "Cek ketersediaan username. :available | :taken"
  def check_username_available(username) do
    if get_user_by_username(username), do: :taken, else: :available
  end

  @doc "Update profil user (name, username, email, lang)."
  def update_profile(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
    |> translate_unique_errors()
  end

  # ---- Location ----

  @doc "Tambah lokasi permanen ke DB."
  def add_location(user_id, attrs) do
    %UserLocation{}
    |> UserLocation.changeset(Map.put(attrs, :user_id, user_id))
    |> Repo.insert()
  end

  @doc "List semua lokasi aktif milik user."
  def list_locations(user_id) do
    UserLocation
    |> where([l], l.user_id == ^user_id and l.is_active == true)
    |> Repo.all()
  end

  @doc "Nonaktifkan lokasi (soft delete). Cek ownership via user_id."
  def deactivate_location(loc_id, user_id) do
    case Repo.get_by(UserLocation, id: loc_id, user_id: user_id) do
      nil -> {:error, :not_found}
      loc -> loc |> UserLocation.changeset(%{is_active: false}) |> Repo.update()
    end
  end

  @doc """
  Upsert channel_identity — insert saat pertama kali contact, update last_seen_at saat berikutnya.
  Atomic via ON CONFLICT — aman untuk concurrent requests.
  """
  def upsert_channel_identity(channel, channel_id) when is_binary(channel) and is_binary(channel_id) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    %ChannelIdentity{}
    |> ChannelIdentity.changeset(%{
      channel: channel,
      channel_id: channel_id,
      first_seen_at: now,
      last_seen_at: now
    })
    |> Repo.insert(
      on_conflict: [set: [last_seen_at: now, updated_at: now]],
      conflict_target: [:channel, :channel_id],
      returning: true
    )
  end

  # ---- Channel Identity ----

  @doc "Link channel_identity ke user setelah registrasi selesai (Step 5)."
  def link_channel_identity(channel_identity_id, user_id) do
    case Repo.get(ChannelIdentity, channel_identity_id) do
      nil -> {:error, :not_found}
      ci  -> ci |> ChannelIdentity.changeset(%{user_id: user_id}) |> Repo.update()
    end
  end

  # ---- Private ----

  defp translate_unique_errors({:ok, _} = result), do: result

  defp translate_unique_errors({:error, changeset}) do
    cond do
      unique_error?(changeset, :username) -> {:error, :username_taken}
      unique_error?(changeset, :email)    -> {:error, :email_taken}
      true                                -> {:error, changeset}
    end
  end

  defp unique_error?(changeset, field) do
    Enum.any?(changeset.errors, fn
      {^field, {_, [constraint: :unique, constraint_name: _]}} -> true
      _                                                         -> false
    end)
  end
end
