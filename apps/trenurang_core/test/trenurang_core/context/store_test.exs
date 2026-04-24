defmodule TrenurangCore.Context.StoreTest do
  use ExUnit.Case, async: false

  alias TrenurangCore.Repo
  alias TrenurangCore.Schema.{User, Store, StoreLocation, Product}
  alias TrenurangCore.Context.Store, as: StoreContext

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  end

  # ---- Helpers ----

  defp insert_user() do
    n = System.unique_integer([:positive])
    {:ok, user} =
      %User{}
      |> User.changeset(%{name: "Owner", username: "owner#{n}", lang: "id"})
      |> Repo.insert()
    user
  end

  defp insert_store(owner_id, attrs \\ %{}) do
    n = System.unique_integer([:positive])
    defaults = %{
      owner_id:  owner_id,
      type:      "good",
      name:      "Toko #{n}",
      storename: "toko#{n}_store",
      status:    "active"
    }
    {:ok, store} =
      %Store{}
      |> Store.changeset(Map.merge(defaults, attrs))
      |> Repo.insert()
    store
  end

  defp insert_store_location(store_id) do
    {:ok, loc} =
      %StoreLocation{}
      |> StoreLocation.changeset(%{
        store_id:      store_id,
        label:         "Lokasi Utama",
        coordinates:   %Geo.Point{coordinates: {106.8456, -6.2088}, srid: 4326},
        duration_type: "permanent"
      })
      |> Repo.insert()
    loc
  end

  defp insert_product(store_id, attrs \\ %{}) do
    n = System.unique_integer([:positive])
    defaults = %{
      store_id:   store_id,
      type:       "good",
      name:       "Produk #{n}",
      unit:       "pcs",
      price:      Decimal.new("10000"),
      stock:      10,
      stock_type: "limited",
      status:     "active"
    }
    {:ok, product} =
      %Product{}
      |> Product.changeset(Map.merge(defaults, attrs))
      |> Repo.insert()
    product
  end

  # ---- create_store/2 ----

  @tag :db
  test "create_store/2 — sukses buat toko baru" do
    user = insert_user()
    assert {:ok, store} = StoreContext.create_store(user.id, %{
      type: "good", name: "Toko Saya", storename: "tokosaya_store"
    })
    assert store.owner_id == user.id
    assert store.status == "active"
  end

  @tag :db
  test "create_store/2 — gagal jika storename sudah dipakai" do
    user = insert_user()
    insert_store(user.id, %{storename: "duplikat_store"})
    assert {:error, :storename_taken} = StoreContext.create_store(user.id, %{
      type: "good", name: "Toko Lain", storename: "duplikat_store"
    })
  end

  @tag :db
  test "create_store/2 — gagal jika attrs tidak valid" do
    user = insert_user()
    assert {:error, changeset} = StoreContext.create_store(user.id, %{name: "Toko"})
    assert changeset.errors != []
  end

  # ---- list_stores_by_owner/1 ----

  @tag :db
  test "list_stores_by_owner/1 — return semua toko milik owner" do
    user = insert_user()
    s1 = insert_store(user.id)
    s2 = insert_store(user.id, %{status: "inactive"})

    result = StoreContext.list_stores_by_owner(user.id)
    ids = Enum.map(result, & &1.id)
    assert s1.id in ids
    assert s2.id in ids
  end

  @tag :db
  test "list_stores_by_owner/1 — return [] jika owner tidak punya toko" do
    user = insert_user()
    assert [] == StoreContext.list_stores_by_owner(user.id)
  end

  @tag :db
  test "list_stores_by_owner/1 — tidak return toko milik owner lain" do
    user1 = insert_user()
    user2 = insert_user()
    store_user2 = insert_store(user2.id)

    result = StoreContext.list_stores_by_owner(user1.id)
    ids = Enum.map(result, & &1.id)
    refute store_user2.id in ids
  end

  # ---- update_store/2 ----

  @tag :db
  test "update_store/2 — sukses update nama toko" do
    user  = insert_user()
    store = insert_store(user.id)
    assert {:ok, updated} = StoreContext.update_store(store, %{name: "Nama Baru"})
    assert updated.name == "Nama Baru"
  end

  @tag :db
  test "update_store/2 — gagal jika storename baru sudah dipakai" do
    user   = insert_user()
    store1 = insert_store(user.id, %{storename: "milikku_store"})
    store2 = insert_store(user.id)
    assert {:error, :storename_taken} = StoreContext.update_store(store2, %{storename: store1.storename})
  end

  # ---- deactivate_store/1 ----

  @tag :db
  test "deactivate_store/1 — set status ke inactive" do
    user  = insert_user()
    store = insert_store(user.id)
    assert {:ok, updated} = StoreContext.deactivate_store(store)
    assert updated.status == "inactive"
  end

  # ---- add_store_location/2 ----

  @tag :db
  test "add_store_location/2 — sukses tambah lokasi toko" do
    user  = insert_user()
    store = insert_store(user.id)
    attrs = %{
      label:         "Gudang",
      coordinates:   %Geo.Point{coordinates: {106.8456, -6.2088}, srid: 4326},
      duration_type: "permanent"
    }
    assert {:ok, loc} = StoreContext.add_store_location(store.id, attrs)
    assert loc.store_id == store.id
    assert loc.is_active == true
  end

  @tag :db
  test "add_store_location/2 — gagal jika attrs tidak valid" do
    user  = insert_user()
    store = insert_store(user.id)
    assert {:error, changeset} = StoreContext.add_store_location(store.id, %{label: "X"})
    assert changeset.errors != []
  end

  # ---- list_store_locations/1 ----

  @tag :db
  test "list_store_locations/1 — return hanya lokasi aktif" do
    user  = insert_user()
    store = insert_store(user.id)
    loc1  = insert_store_location(store.id)
    loc2  = insert_store_location(store.id)

    StoreContext.deactivate_store_location(loc2.id, store.id)

    result = StoreContext.list_store_locations(store.id)
    ids = Enum.map(result, & &1.id)
    assert loc1.id in ids
    refute loc2.id in ids
  end

  # ---- deactivate_store_location/2 ----

  @tag :db
  test "deactivate_store_location/2 — sukses nonaktifkan lokasi" do
    user  = insert_user()
    store = insert_store(user.id)
    loc   = insert_store_location(store.id)
    assert {:ok, updated} = StoreContext.deactivate_store_location(loc.id, store.id)
    assert updated.is_active == false
  end

  @tag :db
  test "deactivate_store_location/2 — {:error, :not_found} jika store_id tidak cocok" do
    user   = insert_user()
    store1 = insert_store(user.id)
    store2 = insert_store(user.id)
    loc    = insert_store_location(store1.id)
    assert {:error, :not_found} = StoreContext.deactivate_store_location(loc.id, store2.id)
  end

  # ---- add_product/2 ----

  @tag :db
  test "add_product/2 — sukses tambah produk" do
    user    = insert_user()
    store   = insert_store(user.id)
    attrs   = %{type: "good", name: "Beras 5kg", unit: "kg", price: Decimal.new("60000"), stock: 20, stock_type: "limited"}
    assert {:ok, product} = StoreContext.add_product(store.id, attrs)
    assert product.store_id == store.id
    assert product.status == "active"
  end

  @tag :db
  test "add_product/2 — gagal jika attrs tidak valid" do
    user  = insert_user()
    store = insert_store(user.id)
    assert {:error, changeset} = StoreContext.add_product(store.id, %{name: "Tanpa Harga"})
    assert changeset.errors != []
  end

  # ---- list_products/1 ----

  @tag :db
  test "list_products/1 — return semua produk termasuk inactive (seller view)" do
    user    = insert_user()
    store   = insert_store(user.id)
    aktif   = insert_product(store.id)
    nonaktif = insert_product(store.id, %{status: "inactive"})

    result = StoreContext.list_products(store.id)
    ids = Enum.map(result, & &1.id)
    assert aktif.id in ids
    assert nonaktif.id in ids
  end

  @tag :db
  test "list_products/1 — return [] jika toko tidak punya produk" do
    user  = insert_user()
    store = insert_store(user.id)
    assert [] == StoreContext.list_products(store.id)
  end

  # ---- update_product/2 ----

  @tag :db
  test "update_product/2 — sukses update harga produk" do
    user    = insert_user()
    store   = insert_store(user.id)
    product = insert_product(store.id)
    assert {:ok, updated} = StoreContext.update_product(product, %{price: Decimal.new("99000")})
    assert Decimal.equal?(updated.price, Decimal.new("99000"))
  end

  # ---- deactivate_product/2 ----

  @tag :db
  test "deactivate_product/2 — sukses nonaktifkan produk" do
    user    = insert_user()
    store   = insert_store(user.id)
    product = insert_product(store.id)
    assert {:ok, updated} = StoreContext.deactivate_product(product.id, store.id)
    assert updated.status == "inactive"
  end

  @tag :db
  test "deactivate_product/2 — {:error, :not_found} jika store_id tidak cocok" do
    user    = insert_user()
    store1  = insert_store(user.id)
    store2  = insert_store(user.id)
    product = insert_product(store1.id)
    assert {:error, :not_found} = StoreContext.deactivate_product(product.id, store2.id)
  end
end
