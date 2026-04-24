defmodule TrenurangCore.Context.OrderTest do
  use ExUnit.Case, async: false
  import Ecto.Query

  alias TrenurangCore.Repo
  alias TrenurangCore.Schema.{
    User, Store, Product,
    StoreOrder, StoreOrderCode, StoreReward, StoreTrustScore
  }
  alias TrenurangCore.Context.Order, as: OrderContext

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  end

  # ---- Helpers ----

  defp insert_user do
    n = System.unique_integer([:positive])
    {:ok, user} =
      %User{}
      |> User.changeset(%{name: "User", username: "user#{n}", lang: "id"})
      |> Repo.insert()
    user
  end

  defp insert_store(owner_id, opts \\ []) do
    n = System.unique_integer([:positive])
    {:ok, store} =
      %Store{}
      |> Store.changeset(%{
        owner_id:  owner_id,
        type:      "good",
        name:      "Toko #{n}",
        storename: "toko#{n}_store",
        status:    "active"
      })
      |> Repo.insert()

    if days_ago = Keyword.get(opts, :created_days_ago) do
      past = DateTime.utc_now()
             |> DateTime.add(-days_ago * 86_400, :second)
             |> DateTime.truncate(:second)

      from(s in Store, where: s.id == ^store.id)
      |> Repo.update_all(set: [inserted_at: past])

      Repo.get(Store, store.id)
    else
      store
    end
  end

  defp insert_store_trust_score(store_id, tier) do
    score = %{
      "belum_teruji"    => 100,
      "pemula_aktif"    => 400,
      "pedagang_tumbuh" => 600,
      "pedagang_andal"  => 800,
      "juragan"         => 950
    }[tier]

    now = DateTime.utc_now() |> DateTime.truncate(:second)
    {:ok, ts} =
      %StoreTrustScore{}
      |> StoreTrustScore.changeset(%{
        store_id:             store_id,
        score:                score,
        tier:                 tier,
        is_cold_start:        true,
        cold_start_ends_at:   Date.add(Date.utc_today(), 90),
        last_recalculated_at: now
      })
      |> Repo.insert()
    ts
  end

  defp insert_product(store_id) do
    n = System.unique_integer([:positive])
    {:ok, p} =
      %Product{}
      |> Product.changeset(%{
        store_id:   store_id,
        type:       "good",
        name:       "Produk #{n}",
        unit:       "pcs",
        price:      Decimal.new("10000"),
        stock:      10,
        stock_type: "limited",
        status:     "active"
      })
      |> Repo.insert()
    p
  end

  defp insert_order_code(store_id, opts) do
    {:ok, oc} =
      %StoreOrderCode{}
      |> StoreOrderCode.changeset(%{
        store_id:   store_id,
        code:       Keyword.get(opts, :code, "AAAAAA"),
        valid_date: Keyword.get(opts, :valid_date, Date.utc_today()),
        used_at:    Keyword.get(opts, :used_at, nil),
        order_id:   Keyword.get(opts, :order_id, nil)
      })
      |> Repo.insert()
    oc
  end

  defp insert_reward(store_id, total_codes) do
    today = Date.utc_today()
    {:ok, r} =
      %StoreReward{}
      |> StoreReward.changeset(%{
        store_id:       store_id,
        type:           "discount",
        description:    "Diskon 10%",
        value:          %{percent: 10},
        claim_deadline: Date.add(today, 30),
        total_codes:    total_codes,
        batch_date:     today,
        status:         "active"
      })
      |> Repo.insert()
    r
  end

  defp insert_b2c_order(buyer_id, seller_id, status \\ "pending") do
    {:ok, o} =
      %StoreOrder{}
      |> StoreOrder.changeset(%{
        type:      "b2c",
        buyer_id:  buyer_id,
        seller_id: seller_id,
        status:    status
      })
      |> Repo.insert()
    o
  end

  # ---- Cart ----

  @tag :db
  test "add_to_cart/3 — tambah produk baru" do
    user    = insert_user()
    owner   = insert_user()
    store   = insert_store(owner.id)
    product = insert_product(store.id)

    assert {:ok, cart} = OrderContext.add_to_cart(user.id, product.id, 2)
    assert cart.quantity == 2
  end

  @tag :db
  test "add_to_cart/3 — qty terakumulasi jika produk sudah ada" do
    user    = insert_user()
    owner   = insert_user()
    store   = insert_store(owner.id)
    product = insert_product(store.id)

    OrderContext.add_to_cart(user.id, product.id, 2)
    assert {:ok, cart} = OrderContext.add_to_cart(user.id, product.id, 3)
    assert cart.quantity == 5
  end

  @tag :db
  test "list_cart/1 — return items dengan produk ter-preload" do
    user    = insert_user()
    owner   = insert_user()
    store   = insert_store(owner.id)
    product = insert_product(store.id)

    OrderContext.add_to_cart(user.id, product.id, 1)
    result = OrderContext.list_cart(user.id)

    assert length(result) == 1
    assert %Product{} = hd(result).product
  end

  @tag :db
  test "clear_cart/1 — hapus semua item" do
    user    = insert_user()
    owner   = insert_user()
    store   = insert_store(owner.id)
    p1      = insert_product(store.id)
    p2      = insert_product(store.id)

    OrderContext.add_to_cart(user.id, p1.id, 1)
    OrderContext.add_to_cart(user.id, p2.id, 2)

    assert :ok == OrderContext.clear_cart(user.id)
    assert [] == OrderContext.list_cart(user.id)
  end

  # ---- B2C Order ----

  @tag :db
  test "create_b2c_order/4 — sukses buat order + payment" do
    buyer   = insert_user()
    seller  = insert_user()
    owner   = insert_user()
    store   = insert_store(owner.id)
    product = insert_product(store.id)

    items   = [%{product_id: product.id, qty: 2, price: Decimal.new("10000")}]
    payment = %{method: "cash"}

    assert {:ok, {order, payment_rec}} =
      OrderContext.create_b2c_order(buyer.id, seller.id, items, payment)

    assert order.type == "b2c"
    assert order.status == "pending"
    assert payment_rec.method == "cash"
    assert payment_rec.send_to_id == seller.id
  end

  @tag :db
  test "create_b2c_order/4 — gagal jika payment method tidak valid" do
    buyer   = insert_user()
    seller  = insert_user()
    owner   = insert_user()
    store   = insert_store(owner.id)
    product = insert_product(store.id)

    items   = [%{product_id: product.id, qty: 1, price: Decimal.new("5000")}]
    payment = %{method: "gopay"}

    assert {:error, _} = OrderContext.create_b2c_order(buyer.id, seller.id, items, payment)
  end

  @tag :db
  test "get_order/1 — return order jika ada" do
    buyer  = insert_user()
    seller = insert_user()
    order  = insert_b2c_order(buyer.id, seller.id)

    assert fetched = OrderContext.get_order(order.id)
    assert fetched.id == order.id
  end

  @tag :db
  test "get_order/1 — return nil jika tidak ada" do
    assert nil == OrderContext.get_order(999_999_999)
  end

  @tag :db
  test "list_orders_by_buyer/1 — return order milik buyer saja" do
    buyer  = insert_user()
    seller = insert_user()
    other  = insert_user()
    order  = insert_b2c_order(buyer.id, seller.id)
    _other = insert_b2c_order(other.id, seller.id)

    result = OrderContext.list_orders_by_buyer(buyer.id)
    ids    = Enum.map(result, & &1.id)

    assert order.id in ids
    assert length(result) == 1
  end

  @tag :db
  test "list_orders_by_seller/1 — return order masuk ke seller" do
    buyer  = insert_user()
    seller = insert_user()
    order  = insert_b2c_order(buyer.id, seller.id)

    result = OrderContext.list_orders_by_seller(seller.id)
    ids    = Enum.map(result, & &1.id)

    assert order.id in ids
  end

  @tag :db
  test "cancel_order/1 — sukses cancel order pending" do
    buyer  = insert_user()
    seller = insert_user()
    order  = insert_b2c_order(buyer.id, seller.id, "pending")

    assert {:ok, updated} = OrderContext.cancel_order(order.id)
    assert updated.status == "cancelled"
  end

  @tag :db
  test "cancel_order/1 — {:error, :cannot_cancel} jika sudah confirmed" do
    buyer  = insert_user()
    seller = insert_user()
    order  = insert_b2c_order(buyer.id, seller.id, "confirmed")

    assert {:error, :cannot_cancel} = OrderContext.cancel_order(order.id)
  end

  @tag :db
  test "cancel_order/1 — {:error, :not_found} jika tidak ada" do
    assert {:error, :not_found} = OrderContext.cancel_order(999_999_999)
  end

  # ---- Walk-in Code Lookup ----

  @tag :db
  test "lookup_walkin_code/2 — {:ok, code} untuk kode valid" do
    owner = insert_user()
    store = insert_store(owner.id)
    insert_order_code(store.id, code: "ABCDEF", valid_date: Date.utc_today())

    assert {:ok, code} = OrderContext.lookup_walkin_code(store.id, "ABCDEF")
    assert code.code == "ABCDEF"
  end

  @tag :db
  test "lookup_walkin_code/2 — case-insensitive (input lowercase)" do
    owner = insert_user()
    store = insert_store(owner.id)
    insert_order_code(store.id, code: "XKZR45", valid_date: Date.utc_today())

    assert {:ok, _} = OrderContext.lookup_walkin_code(store.id, "xkzr45")
  end

  @tag :db
  test "lookup_walkin_code/2 — {:error, :invalid_code} jika tidak ditemukan" do
    owner = insert_user()
    store = insert_store(owner.id)

    assert {:error, :invalid_code} = OrderContext.lookup_walkin_code(store.id, "ZZZZZZ")
  end

  @tag :db
  test "lookup_walkin_code/2 — {:error, :code_expired} jika valid_date lewat" do
    owner     = insert_user()
    store     = insert_store(owner.id)
    yesterday = Date.add(Date.utc_today(), -1)
    insert_order_code(store.id, code: "EXPIRY", valid_date: yesterday)

    assert {:error, :code_expired} = OrderContext.lookup_walkin_code(store.id, "EXPIRY")
  end

  @tag :db
  test "lookup_walkin_code/2 — {:error, :code_already_used} jika kode sudah dipakai" do
    owner = insert_user()
    store = insert_store(owner.id)
    now   = DateTime.utc_now() |> DateTime.truncate(:second)
    insert_order_code(store.id, code: "USEDXX", valid_date: Date.utc_today(), used_at: now)

    assert {:error, :code_already_used} = OrderContext.lookup_walkin_code(store.id, "USEDXX")
  end

  # ---- Generate Order Codes ----

  @tag :db
  test "generate_order_codes/2 — starter boost: toko baru + punya produk → 100 kode" do
    owner = insert_user()
    store = insert_store(owner.id)
    insert_product(store.id)

    assert {:ok, codes} = OrderContext.generate_order_codes(store.id)
    assert length(codes) == 100
  end

  @tag :db
  test "generate_order_codes/2 — starter boost: toko baru tanpa produk → :no_products" do
    owner = insert_user()
    store = insert_store(owner.id)

    assert {:error, :no_products} = OrderContext.generate_order_codes(store.id)
  end

  @tag :db
  test "generate_order_codes/2 — starter boost sudah dipakai → cek threshold normal" do
    owner = insert_user()
    store = insert_store(owner.id)
    insert_product(store.id)
    insert_store_trust_score(store.id, "pemula_aktif")

    {:ok, _} = OrderContext.generate_order_codes(store.id)

    # Boost habis, kode lama 0% confirmed → threshold not met
    assert {:error, {:threshold_not_met, 0, 100}} =
      OrderContext.generate_order_codes(store.id)
  end

  @tag :db
  test "generate_order_codes/2 — toko > 7 hari, tier pemula_aktif → 75 kode" do
    owner = insert_user()
    store = insert_store(owner.id, created_days_ago: 8)
    insert_store_trust_score(store.id, "pemula_aktif")

    assert {:ok, codes} = OrderContext.generate_order_codes(store.id)
    assert length(codes) == 75
  end

  @tag :db
  test "generate_order_codes/2 — tier belum_teruji → 50 kode" do
    owner = insert_user()
    store = insert_store(owner.id, created_days_ago: 8)
    insert_store_trust_score(store.id, "belum_teruji")

    assert {:ok, codes} = OrderContext.generate_order_codes(store.id)
    assert length(codes) == 50
  end

  @tag :db
  test "generate_order_codes/2 — tier pedagang_andal → 150 kode" do
    owner = insert_user()
    store = insert_store(owner.id, created_days_ago: 8)
    insert_store_trust_score(store.id, "pedagang_andal")

    assert {:ok, codes} = OrderContext.generate_order_codes(store.id)
    assert length(codes) == 150
  end

  @tag :db
  test "generate_order_codes/2 — tier juragan → 250 kode" do
    owner = insert_user()
    store = insert_store(owner.id, created_days_ago: 8)
    insert_store_trust_score(store.id, "juragan")

    assert {:ok, codes} = OrderContext.generate_order_codes(store.id)
    assert length(codes) == 250
  end

  @tag :db
  test "generate_order_codes/2 — threshold belum terpenuhi (30% confirmed)" do
    owner  = insert_user()
    buyer  = insert_user()
    store  = insert_store(owner.id, created_days_ago: 8)
    insert_store_trust_score(store.id, "pemula_aktif")

    {:ok, first_batch} = OrderContext.generate_order_codes(store.id)
    total          = length(first_batch)
    confirmed_count = trunc(total * 0.30)  # 30% < 50% threshold

    first_batch
    |> Enum.take(confirmed_count)
    |> Enum.each(fn entry ->
      order      = insert_b2c_order(buyer.id, owner.id, "confirmed")
      code_record = Repo.get_by(StoreOrderCode, code: entry.code, store_id: store.id)
      OrderContext.use_walkin_code(code_record, order.id)
    end)

    assert {:error, {:threshold_not_met, ^confirmed_count, ^total}} =
      OrderContext.generate_order_codes(store.id)
  end

  @tag :db
  test "generate_order_codes/2 — threshold terpenuhi (>50% confirmed) → generate batch baru" do
    owner  = insert_user()
    buyer  = insert_user()
    store  = insert_store(owner.id, created_days_ago: 8)
    insert_store_trust_score(store.id, "pemula_aktif")  # 75 kode

    {:ok, first_batch} = OrderContext.generate_order_codes(store.id)
    total           = length(first_batch)
    confirmed_count  = div(total, 2) + 1  # 38/75 = 50.7% ≥ 50%

    first_batch
    |> Enum.take(confirmed_count)
    |> Enum.each(fn entry ->
      order      = insert_b2c_order(buyer.id, owner.id, "confirmed")
      code_record = Repo.get_by(StoreOrderCode, code: entry.code, store_id: store.id)
      OrderContext.use_walkin_code(code_record, order.id)
    end)

    assert {:ok, new_codes} = OrderContext.generate_order_codes(store.id)
    assert length(new_codes) == 75
  end

  @tag :db
  test "generate_order_codes/2 — kode hanya berisi A-Z0-9, panjang 6" do
    owner = insert_user()
    store = insert_store(owner.id, created_days_ago: 8)
    insert_store_trust_score(store.id, "belum_teruji")

    {:ok, codes} = OrderContext.generate_order_codes(store.id)
    assert Enum.all?(codes, fn c -> String.match?(c.code, ~r/^[A-Z0-9]{6}$/) end)
  end

  @tag :db
  test "generate_order_codes/2 — tanpa reward: semua is_golden false" do
    owner = insert_user()
    store = insert_store(owner.id, created_days_ago: 8)
    insert_store_trust_score(store.id, "belum_teruji")

    {:ok, codes} = OrderContext.generate_order_codes(store.id)
    assert Enum.all?(codes, fn c -> c.is_golden == false end)
    assert Enum.all?(codes, fn c -> is_nil(c.reward_id) end)
  end

  @tag :db
  test "generate_order_codes/2 — dengan reward: N kode is_golden, reward_id terisi" do
    owner  = insert_user()
    store  = insert_store(owner.id, created_days_ago: 8)
    insert_store_trust_score(store.id, "belum_teruji")  # 50 kode
    reward = insert_reward(store.id, 5)

    {:ok, codes} = OrderContext.generate_order_codes(store.id, reward_id: reward.id)

    golden     = Enum.filter(codes, & &1.is_golden)
    non_golden = Enum.reject(codes, & &1.is_golden)

    assert length(golden) == 5
    assert Enum.all?(golden, fn c -> c.reward_id == reward.id end)
    assert Enum.all?(non_golden, fn c -> is_nil(c.reward_id) end)
  end

  @tag :db
  test "generate_order_codes/2 — {:error, :trust_score_not_found} jika trust score belum ada" do
    owner = insert_user()
    store = insert_store(owner.id, created_days_ago: 8)

    assert {:error, :trust_score_not_found} = OrderContext.generate_order_codes(store.id)
  end
end
