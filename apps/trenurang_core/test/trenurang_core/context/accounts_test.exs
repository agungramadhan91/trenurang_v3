defmodule TrenurangCore.Context.AccountsTest do
  use ExUnit.Case, async: false

  alias TrenurangCore.Repo
  alias TrenurangCore.Schema.{User, UserLocation, ChannelIdentity}
  alias TrenurangCore.Context.Accounts

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  end

  # ---- Helpers ----

  defp insert_user(attrs \\ %{}) do
    n = System.unique_integer([:positive])

    defaults = %{
      name:     "Test User",
      username: "testuser#{n}",
      lang:     "id",
      status:   "active"
    }

    {:ok, user} =
      %User{}
      |> User.changeset(Map.merge(defaults, attrs))
      |> Repo.insert()

    user
  end

  defp insert_location(user_id) do
    {:ok, loc} =
      %UserLocation{}
      |> UserLocation.changeset(%{
        user_id:       user_id,
        label:         "Rumah",
        coordinates:   %Geo.Point{coordinates: {106.8456, -6.2088}, srid: 4326},
        duration_type: "permanent"
      })
      |> Repo.insert()

    loc
  end

  defp insert_channel_identity() do
    n = System.unique_integer([:positive])
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    {:ok, ci} =
      %ChannelIdentity{}
      |> ChannelIdentity.changeset(%{
        channel:       "telegram",
        channel_id:    "tg_#{n}",
        first_seen_at: now,
        last_seen_at:  now
      })
      |> Repo.insert()

    ci
  end

  # ---- register_user/1 ----

  @tag :db
  test "register_user/1 — sukses dengan data valid" do
    assert {:ok, user} = Accounts.register_user(%{name: "Budi", username: "budi123", lang: "id"})
    assert user.id != nil
    assert user.username == "budi123"
  end

  @tag :db
  test "register_user/1 — gagal jika username sudah dipakai" do
    insert_user(%{username: "duplikat"})
    assert {:error, :username_taken} = Accounts.register_user(%{name: "Lain", username: "duplikat", lang: "id"})
  end

  @tag :db
  test "register_user/1 — gagal jika email sudah dipakai" do
    insert_user(%{email: "sama@email.com"})
    assert {:error, :email_taken} = Accounts.register_user(%{name: "Budi", username: "budi_baru", email: "sama@email.com", lang: "id"})
  end

  @tag :db
  test "register_user/1 — gagal jika data tidak valid (changeset error)" do
    assert {:error, changeset} = Accounts.register_user(%{name: "X"})
    assert changeset.errors != []
  end

  # ---- get_user/1 ----

  @tag :db
  test "get_user/1 — return user jika ditemukan" do
    user = insert_user()
    assert fetched = Accounts.get_user(user.id)
    assert fetched.id == user.id
  end

  @tag :db
  test "get_user/1 — return nil jika tidak ada" do
    assert nil == Accounts.get_user(999_999_999)
  end

  # ---- get_user_by_username/1 ----

  @tag :db
  test "get_user_by_username/1 — return user jika ditemukan" do
    user = insert_user(%{username: "cariaku"})
    assert fetched = Accounts.get_user_by_username("cariaku")
    assert fetched.id == user.id
  end

  @tag :db
  test "get_user_by_username/1 — return nil jika tidak ada" do
    assert nil == Accounts.get_user_by_username("tidakada_xyz")
  end

  # ---- check_username_available/1 ----

  @tag :db
  test "check_username_available/1 — :available jika belum dipakai" do
    assert :available == Accounts.check_username_available("username_fresh_#{System.unique_integer([:positive])}")
  end

  @tag :db
  test "check_username_available/1 — :taken jika sudah dipakai" do
    user = insert_user()
    assert :taken == Accounts.check_username_available(user.username)
  end

  # ---- update_profile/2 ----

  @tag :db
  test "update_profile/2 — sukses update nama" do
    user = insert_user()
    assert {:ok, updated} = Accounts.update_profile(user, %{name: "Nama Baru"})
    assert updated.name == "Nama Baru"
  end

  @tag :db
  test "update_profile/2 — sukses update username ke yang tersedia" do
    user = insert_user()
    new_username = "newusername#{System.unique_integer([:positive])}"
    assert {:ok, updated} = Accounts.update_profile(user, %{username: new_username})
    assert updated.username == new_username
  end

  @tag :db
  test "update_profile/2 — gagal jika username baru sudah dipakai" do
    user1 = insert_user(%{username: "existing_one"})
    user2 = insert_user()
    assert {:error, :username_taken} = Accounts.update_profile(user2, %{username: user1.username})
  end

  # ---- add_location/2 ----

  @tag :db
  test "add_location/2 — sukses simpan lokasi permanen" do
    user = insert_user()

    attrs = %{
      label:         "Pasar",
      coordinates:   %Geo.Point{coordinates: {106.8456, -6.2088}, srid: 4326},
      duration_type: "permanent"
    }

    assert {:ok, loc} = Accounts.add_location(user.id, attrs)
    assert loc.user_id == user.id
    assert loc.label == "Pasar"
    assert loc.is_active == true
  end

  @tag :db
  test "add_location/2 — gagal jika attrs tidak valid" do
    user = insert_user()
    assert {:error, changeset} = Accounts.add_location(user.id, %{label: "X"})
    assert changeset.errors != []
  end

  # ---- list_locations/1 ----

  @tag :db
  test "list_locations/1 — return hanya lokasi aktif" do
    user = insert_user()
    loc1 = insert_location(user.id)
    loc2 = insert_location(user.id)

    # nonaktifkan loc2
    {:ok, _} = Accounts.deactivate_location(loc2.id, user.id)

    result = Accounts.list_locations(user.id)
    ids = Enum.map(result, & &1.id)

    assert loc1.id in ids
    refute loc2.id in ids
  end

  @tag :db
  test "list_locations/1 — return [] jika tidak ada lokasi" do
    user = insert_user()
    assert [] == Accounts.list_locations(user.id)
  end

  # ---- deactivate_location/2 ----

  @tag :db
  test "deactivate_location/2 — sukses nonaktifkan lokasi" do
    user = insert_user()
    loc  = insert_location(user.id)

    assert {:ok, updated} = Accounts.deactivate_location(loc.id, user.id)
    assert updated.is_active == false
  end

  @tag :db
  test "deactivate_location/2 — {:error, :not_found} jika loc tidak ada" do
    user = insert_user()
    assert {:error, :not_found} = Accounts.deactivate_location(999_999_999, user.id)
  end

  @tag :db
  test "deactivate_location/2 — {:error, :not_found} jika user_id tidak cocok (ownership check)" do
    user1 = insert_user()
    user2 = insert_user()
    loc   = insert_location(user1.id)

    assert {:error, :not_found} = Accounts.deactivate_location(loc.id, user2.id)
  end

  # ---- link_channel_identity/2 ----

  @tag :db
  test "link_channel_identity/2 — sukses link user ke channel identity" do
    user = insert_user()
    ci   = insert_channel_identity()

    assert {:ok, updated} = Accounts.link_channel_identity(ci.id, user.id)
    assert updated.user_id == user.id
  end

  @tag :db
  test "link_channel_identity/2 — {:error, :not_found} jika channel identity tidak ada" do
    user = insert_user()
    assert {:error, :not_found} = Accounts.link_channel_identity(999_999_999, user.id)
  end

  describe "upsert_channel_identity/2" do
    test "insert baru saat channel_id belum ada" do
      assert {:ok, ci} = Accounts.upsert_channel_identity("telegram", "tg_99001")
      assert ci.channel == "telegram"
      assert ci.channel_id == "tg_99001"
      assert is_nil(ci.user_id)
    end

    test "update last_seen_at saat channel_id sudah ada" do
      {:ok, first} = Accounts.upsert_channel_identity("telegram", "tg_99002")
      :timer.sleep(1000)
      {:ok, second} = Accounts.upsert_channel_identity("telegram", "tg_99002")

      assert second.id == first.id
      assert DateTime.compare(second.last_seen_at, first.last_seen_at) == :gt
    end
  end
end
