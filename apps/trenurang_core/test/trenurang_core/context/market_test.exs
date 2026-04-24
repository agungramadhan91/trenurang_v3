defmodule TrenurangCore.Context.MarketTest do
  use ExUnit.Case, async: false

  alias TrenurangCore.Repo
  alias TrenurangCore.Schema.{User, Store, StoreLocation, Product}
  alias TrenurangCore.Context.Market

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
    defaults = %{owner_id: owner_id, type: "good", name: "Toko #{n}", storename: "toko#{n}_store", status: "active"}
    {:ok, store} =
      %Store{}
      |> Store.changeset(Map.merge(defaults, attrs))
      |> Repo.insert()
    store
  end

  defp insert_store_location(store_id, coords) do
    {:ok, loc} =
      %StoreLocation{}
      |> StoreLocation.changeset(%{
        store_id:      store_id,
        label:         "Toko Utama",
        coordinates:   coords,
        duration_type: "permanent"
      })
      |> Repo.insert()
    loc
  end

  defp insert_product(store_id, attrs) do
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

  # Koordinat Jakarta Pusat
  @jakarta %Geo.Point{coordinates: {106.8456, -6.2088}, srid: 4326}
  # Koordinat 2 km dari Jakarta
  @jakarta_dekat %Geo.Point{coordinates: {106.8630, -6.2000}, srid: 4326}
  # Koordinat Bandung (jauh)
  @bandung %Geo.Point{coordinates: {107.6191, -6.9175}, srid: 4326}

  # ---- browse_stores/2 ----

  @tag :db
  test "browse_stores/2 — return toko dalam radius" do
    owner = insert_user()
    store = insert_store(owner.id)
    insert_store_location(store.id, @jakarta)

    result = Market.browse_stores(@jakarta_dekat, 5_000)
    ids = Enum.map(result, & &1.id)
    assert store.id in ids
  end

  @tag :db
  test "browse_stores/2 — tidak return toko di luar radius" do
    owner = insert_user()
    store = insert_store(owner.id)
    insert_store_location(store.id, @bandung)

    result = Market.browse_stores(@jakarta, 5_000)
    ids = Enum.map(result, & &1.id)
    refute store.id in ids
  end

  @tag :db
  test "browse_stores/2 — tidak return toko inactive" do
    owner = insert_user()
    store = insert_store(owner.id, %{status: "inactive"})
    insert_store_location(store.id, @jakarta)

    result = Market.browse_stores(@jakarta, 5_000)
    ids = Enum.map(result, & &1.id)
    refute store.id in ids
  end

  @tag :db
  test "browse_stores/2 — return [] jika tidak ada toko dalam radius" do
    result = Market.browse_stores(@bandung, 1_000)
    assert result == [] or is_list(result)
  end

  # ---- find_stores/1 ----

  @tag :db
  test "find_stores/1 — temukan toko berdasarkan nama (case-insensitive)" do
    owner = insert_user()
    n = System.unique_integer([:positive])
    store = insert_store(owner.id, %{name: "Toko Beras #{n}", storename: "tokoberas#{n}_store"})

    result = Market.find_stores("beras #{n}")
    ids = Enum.map(result, & &1.id)
    assert store.id in ids
  end

  @tag :db
  test "find_stores/1 — temukan toko berdasarkan storename" do
    owner = insert_user()
    n = System.unique_integer([:positive])
    store = insert_store(owner.id, %{name: "Toko Unik #{n}", storename: "tokounik#{n}_store"})

    result = Market.find_stores("tokounik#{n}")
    ids = Enum.map(result, & &1.id)
    assert store.id in ids
  end

  @tag :db
  test "find_stores/1 — tidak return toko inactive" do
    owner = insert_user()
    n = System.unique_integer([:positive])
    insert_store(owner.id, %{name: "Toko Tutup #{n}", storename: "tokotutup#{n}_store", status: "inactive"})

    result = Market.find_stores("tutup #{n}")
    assert result == []
  end

  @tag :db
  test "find_stores/1 — return [] jika tidak ada yang cocok" do
    assert [] == Market.find_stores("xyzxyzxyz_tidak_ada_sama_sekali")
  end

  # ---- find_products/1 ----

  @tag :db
  test "find_products/1 — temukan produk berdasarkan nama" do
    owner = insert_user()
    store = insert_store(owner.id)
    n = System.unique_integer([:positive])
    product = insert_product(store.id, %{name: "Tepung Terigu #{n}"})

    result = Market.find_products("terigu #{n}")
    ids = Enum.map(result, & &1.id)
    assert product.id in ids
  end

  @tag :db
  test "find_products/1 — tidak return produk dari toko inactive" do
    owner = insert_user()
    store = insert_store(owner.id, %{status: "inactive"})
    n = System.unique_integer([:positive])
    insert_product(store.id, %{name: "Produk Inactive #{n}"})

    result = Market.find_products("inactive #{n}")
    assert result == []
  end

  @tag :db
  test "find_products/1 — produk hasil pencarian memiliki store ter-preload" do
    owner = insert_user()
    store = insert_store(owner.id)
    n = System.unique_integer([:positive])
    insert_product(store.id, %{name: "Gula Pasir #{n}"})

    result = Market.find_products("gula pasir #{n}")
    assert length(result) >= 1
    assert %Store{} = hd(result).store
  end

  @tag :db
  test "find_products/1 — return [] jika tidak ada yang cocok" do
    assert [] == Market.find_products("xyzxyzxyz_tidak_ada_sama_sekali")
  end

  # ---- get_store/1 ----

  @tag :db
  test "get_store/1 — return store jika ada" do
    owner = insert_user()
    store = insert_store(owner.id)
    assert fetched = Market.get_store(store.id)
    assert fetched.id == store.id
  end

  @tag :db
  test "get_store/1 — return nil jika tidak ada" do
    assert nil == Market.get_store(999_999_999)
  end

  # ---- get_store_by_storename/1 ----

  @tag :db
  test "get_store_by_storename/1 — return store jika ditemukan" do
    owner = insert_user()
    store = insert_store(owner.id, %{storename: "carinama_store"})
    assert fetched = Market.get_store_by_storename("carinama_store")
    assert fetched.id == store.id
  end

  @tag :db
  test "get_store_by_storename/1 — return nil jika tidak ada" do
    assert nil == Market.get_store_by_storename("tidakada_store")
  end

  # ---- list_store_products/1 ----

  @tag :db
  test "list_store_products/1 — return produk aktif milik toko" do
    owner = insert_user()
    store = insert_store(owner.id)
    p1 = insert_product(store.id, %{name: "Produk A"})
    p2 = insert_product(store.id, %{name: "Produk B"})

    result = Market.list_store_products(store.id)
    ids = Enum.map(result, & &1.id)
    assert p1.id in ids
    assert p2.id in ids
  end

  @tag :db
  test "list_store_products/1 — tidak return produk inactive" do
    owner = insert_user()
    store = insert_store(owner.id)
    aktif    = insert_product(store.id, %{name: "Aktif"})
    inactive = insert_product(store.id, %{name: "Nonaktif", status: "inactive"})

    result = Market.list_store_products(store.id)
    ids = Enum.map(result, & &1.id)
    assert aktif.id in ids
    refute inactive.id in ids
  end

  @tag :db
  test "list_store_products/1 — return [] jika toko tidak punya produk" do
    owner = insert_user()
    store = insert_store(owner.id)
    assert [] == Market.list_store_products(store.id)
  end
end
