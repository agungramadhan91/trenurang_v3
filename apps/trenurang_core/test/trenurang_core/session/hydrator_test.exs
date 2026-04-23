defmodule TrenurangCore.Session.HydratorTest do
  use ExUnit.Case, async: false

  alias TrenurangCore.Repo
  alias TrenurangCore.Session.Hydrator
  alias TrenurangCore.Schema.{
    User,
    Store,
    StoreOrder,
    StoreRelation,
    UserLocation,
    UserSessionState
  }

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    :ets.delete_all_objects(:trenurang_sessions)
    :ok
  end

  # --- Helpers ---

  defp insert_user(attrs \\ %{}) do
    n = System.unique_integer([:positive])
    defaults = %{
      name:     "Test User",
      username: "testuser#{n}",
      lang:     "id",
      status:   "active"
    }
    Repo.insert!(User.changeset(%User{}, Map.merge(defaults, attrs)))
  end

  defp insert_store(user, attrs \\ %{}) do
    n = System.unique_integer([:positive])
    defaults = %{
      owner_id:  user.id,
      type:      "good",
      name:      "Toko Test",
      storename: "toko#{n}_store",
      status:    "active"
    }
    Repo.insert!(Store.changeset(%Store{}, Map.merge(defaults, attrs)))
  end

  defp insert_completed_order(buyer, seller) do
    Repo.insert!(%StoreOrder{
      buyer_id:  buyer.id,
      seller_id: seller.id,
      type:      "b2c",
      status:    "completed"
    })
  end

  defp insert_relation(supplier_store, receiver_store) do
    n = System.unique_integer([:positive])
    Repo.insert!(%StoreRelation{
      code:        "R#{n}",
      supplier_id: supplier_store.id,
      receiver_id: receiver_store.id,
      type:        "konsinyasi"
    })
  end

  defp insert_location(user, attrs) do
    defaults = %{
      user_id:       user.id,
      label:         "Rumah",
      coordinates:   %Geo.Point{coordinates: {106.827_153, -6.175_392}, srid: 4326},
      days:          ["senin", "selasa"],
      hours_start:   8,
      hours_end:     17,
      duration_type: "permanent",
      is_active:     true
    }
    Repo.insert!(UserLocation.changeset(%UserLocation{}, Map.merge(defaults, attrs)))
  end

  defp insert_session_state(user, attrs) do
    Repo.insert!(%UserSessionState{
      user_id:        user.id,
      active_flow:    attrs[:active_flow],
      route_current:  attrs[:route_current] || "/start",
      route_previous: attrs[:route_previous]
    })
  end

  # --- Tests ---

  test "user tidak ada di DB mengembalikan {:error, :not_found}" do
    assert {:error, :not_found} = Hydrator.hydrate(999_999)
  end

  test "user baru tanpa order/store/relation menghasilkan session fresh" do
    user = insert_user()

    assert {:ok, session} = Hydrator.hydrate(user.id)

    assert session.user_id        == "u##{user.id}"
    assert session.username       == "@#{user.username}"
    assert session.lang           == :id
    assert session.is_registered  == true
    assert session.is_buyer       == false
    assert session.has_store      == false
    assert session.has_relation   == false
    assert session.locations      == []
    assert session.active_location == 0
    assert session.active_flow    == nil
    assert session.route          == %{current: "/start", previous: nil}
  end

  test "hydrate kedua kali return dari ETS — tidak hit DB" do
    user = insert_user()

    {:ok, session_first} = Hydrator.hydrate(user.id)
    Repo.delete!(user)

    assert {:ok, session_second} = Hydrator.hydrate(user.id)
    assert session_first == session_second
  end

  test "is_buyer: true ketika ada completed order sebagai buyer" do
    buyer  = insert_user()
    seller = insert_user()
    insert_completed_order(buyer, seller)

    assert {:ok, session} = Hydrator.hydrate(buyer.id)
    assert session.is_buyer == true
  end

  test "is_buyer: false ketika order ada tapi status bukan completed" do
    buyer  = insert_user()
    seller = insert_user()

    Repo.insert!(%StoreOrder{
      buyer_id:  buyer.id,
      seller_id: seller.id,
      type:      "b2c",
      status:    "pending"
    })

    assert {:ok, session} = Hydrator.hydrate(buyer.id)
    assert session.is_buyer == false
  end

  test "has_store: true ketika user punya toko aktif" do
    user = insert_user()
    insert_store(user)

    assert {:ok, session} = Hydrator.hydrate(user.id)
    assert session.has_store == true
  end

  test "has_store: false ketika toko ada tapi status inactive" do
    user = insert_user()
    n    = System.unique_integer([:positive])

    Repo.insert!(Store.changeset(%Store{}, %{
      owner_id:  user.id,
      type:      "good",
      name:      "Toko Test",
      storename: "toko#{n}_store",
      status:    "inactive"
    }))

    assert {:ok, session} = Hydrator.hydrate(user.id)
    assert session.has_store == false
  end

  test "has_relation: true ketika toko user menjadi supplier" do
    supplier_user  = insert_user()
    receiver_user  = insert_user()
    supplier_store = insert_store(supplier_user)
    receiver_store = insert_store(receiver_user)
    insert_relation(supplier_store, receiver_store)

    assert {:ok, session} = Hydrator.hydrate(supplier_user.id)
    assert session.has_relation == true
  end

  test "has_relation: true ketika toko user menjadi receiver" do
    supplier_user  = insert_user()
    receiver_user  = insert_user()
    supplier_store = insert_store(supplier_user)
    receiver_store = insert_store(receiver_user)
    insert_relation(supplier_store, receiver_store)

    assert {:ok, session} = Hydrator.hydrate(receiver_user.id)
    assert session.has_relation == true
  end

  test "has_relation: false ketika user tidak punya toko dalam relasi apapun" do
    user = insert_user()
    insert_store(user)

    assert {:ok, session} = Hydrator.hydrate(user.id)
    assert session.has_relation == false
  end

  test "locations dimuat — hanya yang is_active: true" do
    user = insert_user()
    insert_location(user, %{label: "Rumah", is_active: true})
    insert_location(user, %{label: "Gudang", is_active: false})

    assert {:ok, session} = Hydrator.hydrate(user.id)
    assert length(session.locations) == 1
    assert hd(session.locations).label == "Rumah"
  end

  test "route dimuat dari user_session_states jika ada" do
    user = insert_user()
    insert_session_state(user, %{route_current: "/home", route_previous: "/start"})

    assert {:ok, session} = Hydrator.hydrate(user.id)
    assert session.route == %{current: "/home", previous: "/start"}
  end

  test "active_flow nil ketika session_state tidak ada" do
    user = insert_user()

    assert {:ok, session} = Hydrator.hydrate(user.id)
    assert session.active_flow == nil
  end

  test "active_flow nil ketika session_state ada tapi active_flow nil" do
    user = insert_user()
    insert_session_state(user, %{active_flow: nil})

    assert {:ok, session} = Hydrator.hydrate(user.id)
    assert session.active_flow == nil
  end

  test "lang non-default dimuat sebagai atom yang benar" do
    user = insert_user(%{lang: "en"})

    assert {:ok, session} = Hydrator.hydrate(user.id)
    assert session.lang == :en
  end

  test "active_flow dimuat dari session_state ketika terisi" do
    user = insert_user()
    insert_session_state(user, %{
      active_flow: %{"flow" => "register", "step" => 2, "data" => %{"name" => "Ahmad"}}
    })

    assert {:ok, session} = Hydrator.hydrate(user.id)
    assert session.active_flow == %{flow: :register, step: 2, data: %{"name" => "Ahmad"}}
  end
end
