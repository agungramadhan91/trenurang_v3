defmodule TrenurangCore.Context.ChatTest do
  use ExUnit.Case, async: false

  alias TrenurangCore.Repo
  alias TrenurangCore.Schema.{User, Store, StoreOrder, StoreRelation}
  alias TrenurangCore.Context.Chat

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  end

  # ---- Helpers ----

  defp insert_user do
    n = System.unique_integer([:positive])
    {:ok, u} =
      %User{}
      |> User.changeset(%{name: "User", username: "user#{n}", lang: "id"})
      |> Repo.insert()
    u
  end

  defp insert_store(owner_id) do
    n = System.unique_integer([:positive])
    {:ok, s} =
      %Store{}
      |> Store.changeset(%{
        owner_id:  owner_id,
        type:      "good",
        name:      "Toko #{n}",
        storename: "toko#{n}_store",
        status:    "active"
      })
      |> Repo.insert()
    s
  end

  defp insert_order(buyer_id, seller_id, status) do
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

  defp insert_relation(supplier_id, receiver_id) do
    n = System.unique_integer([:positive])
    {:ok, r} =
      %StoreRelation{}
      |> StoreRelation.changeset(%{
        supplier_id: supplier_id,
        receiver_id: receiver_id,
        type:        "konsinyasi",
        code:        "R#{n}XYZ" |> String.slice(0, 6) |> String.upcase()
      })
      |> Repo.insert()
    r
  end

  # ---- send_b2c_message/4 ----

  @tag :db
  test "send_b2c_message/4 — sukses jika ada completed transaction" do
    seller     = insert_user()
    buyer      = insert_user()
    owner      = insert_user()
    store      = insert_store(owner.id)
    insert_order(buyer.id, seller.id, "completed")

    assert {:ok, chat} = Chat.send_b2c_message(seller.id, buyer.id, store.id, "Halo!")
    assert chat.message == "Halo!"
    assert chat.sender_id == seller.id
    assert chat.receiver_id == buyer.id
  end

  @tag :db
  test "send_b2c_message/4 — {:error, :no_completed_transaction} jika tidak ada transaksi selesai" do
    seller = insert_user()
    buyer  = insert_user()
    owner  = insert_user()
    store  = insert_store(owner.id)

    assert {:error, :no_completed_transaction} =
      Chat.send_b2c_message(seller.id, buyer.id, store.id, "Halo!")
  end

  @tag :db
  test "send_b2c_message/4 — {:error, :no_completed_transaction} jika transaksi masih pending" do
    seller = insert_user()
    buyer  = insert_user()
    owner  = insert_user()
    store  = insert_store(owner.id)
    insert_order(buyer.id, seller.id, "pending")

    assert {:error, :no_completed_transaction} =
      Chat.send_b2c_message(seller.id, buyer.id, store.id, "Halo!")
  end

  @tag :db
  test "send_b2c_message/4 — {:error, :blocked} jika buyer blokir toko seller" do
    seller = insert_user()
    buyer  = insert_user()
    owner  = insert_user()
    store  = insert_store(owner.id)
    insert_order(buyer.id, seller.id, "completed")
    Chat.block_store(buyer.id, store.id)

    assert {:error, :blocked} =
      Chat.send_b2c_message(seller.id, buyer.id, store.id, "Halo!")
  end

  @tag :db
  test "send_b2c_message/4 — {:error, :blocked} jika buyer aktifkan global block" do
    seller = insert_user()
    buyer  = insert_user()
    owner  = insert_user()
    store  = insert_store(owner.id)
    insert_order(buyer.id, seller.id, "completed")
    Chat.block_all_sellers(buyer.id)

    assert {:error, :blocked} =
      Chat.send_b2c_message(seller.id, buyer.id, store.id, "Halo!")
  end

  # ---- send_b2b_message/4 ----

  @tag :db
  test "send_b2b_message/4 — sukses kirim pesan B2B" do
    u1       = insert_user()
    u2       = insert_user()
    s1       = insert_store(u1.id)
    s2       = insert_store(u2.id)
    relation = insert_relation(s1.id, s2.id)

    assert {:ok, chat} = Chat.send_b2b_message(u1.id, u2.id, relation.id, "Deal konsinyasi?")
    assert chat.relation_id == relation.id
    assert chat.sender_id == u1.id
  end

  # ---- list_order_chat/1 & list_relation_chat/1 ----

  @tag :db
  test "list_order_chat/1 — return chat dalam order urut ascending" do
    seller = insert_user()
    buyer  = insert_user()
    owner  = insert_user()
    store  = insert_store(owner.id)
    order  = insert_order(buyer.id, seller.id, "completed")
    insert_order(buyer.id, seller.id, "completed")

    {:ok, _} = Chat.send_b2c_message(seller.id, buyer.id, store.id, "Pesan 1")
    # Tambahkan langsung dengan order_id untuk list test
    {:ok, _} =
      %TrenurangCore.Schema.StoreChat{}
      |> TrenurangCore.Schema.StoreChat.changeset(%{
        sender_id:   seller.id,
        receiver_id: buyer.id,
        order_id:    order.id,
        message:     "Pesan dengan order"
      })
      |> Repo.insert()

    result = Chat.list_order_chat(order.id)
    assert length(result) >= 1
    assert hd(result).order_id == order.id
  end

  @tag :db
  test "list_relation_chat/1 — return chat dalam relasi" do
    u1       = insert_user()
    u2       = insert_user()
    s1       = insert_store(u1.id)
    s2       = insert_store(u2.id)
    relation = insert_relation(s1.id, s2.id)

    {:ok, _} = Chat.send_b2b_message(u1.id, u2.id, relation.id, "Pesan B2B")
    result = Chat.list_relation_chat(relation.id)
    assert length(result) == 1
    assert hd(result).message == "Pesan B2B"
  end

  # ---- block_store/2 ----

  @tag :db
  test "block_store/2 — sukses blokir toko" do
    buyer = insert_user()
    owner = insert_user()
    store = insert_store(owner.id)

    assert {:ok, block} = Chat.block_store(buyer.id, store.id)
    assert block.user_id == buyer.id
    assert block.blocked_store_id == store.id
  end

  @tag :db
  test "block_store/2 — idempotent jika sudah diblokir" do
    buyer = insert_user()
    owner = insert_user()
    store = insert_store(owner.id)

    {:ok, b1} = Chat.block_store(buyer.id, store.id)
    {:ok, b2} = Chat.block_store(buyer.id, store.id)
    assert b1.id == b2.id
  end

  # ---- block_all_sellers/1 ----

  @tag :db
  test "block_all_sellers/1 — sukses aktifkan global block" do
    buyer = insert_user()

    assert {:ok, block} = Chat.block_all_sellers(buyer.id)
    assert block.user_id == buyer.id
    assert is_nil(block.blocked_store_id)
  end

  @tag :db
  test "block_all_sellers/1 — idempotent" do
    buyer = insert_user()
    {:ok, b1} = Chat.block_all_sellers(buyer.id)
    {:ok, b2} = Chat.block_all_sellers(buyer.id)
    assert b1.id == b2.id
  end

  # ---- unblock_store/2 ----

  @tag :db
  test "unblock_store/2 — sukses hapus blokir" do
    buyer = insert_user()
    owner = insert_user()
    store = insert_store(owner.id)
    Chat.block_store(buyer.id, store.id)

    assert {:ok, _} = Chat.unblock_store(buyer.id, store.id)
    refute Chat.blocked?(buyer.id, store.id)
  end

  @tag :db
  test "unblock_store/2 — {:error, :not_found} jika belum diblokir" do
    buyer = insert_user()
    owner = insert_user()
    store = insert_store(owner.id)

    assert {:error, :not_found} = Chat.unblock_store(buyer.id, store.id)
  end

  # ---- blocked?/2 ----

  @tag :db
  test "blocked?/2 — false jika tidak ada blokir" do
    buyer = insert_user()
    owner = insert_user()
    store = insert_store(owner.id)

    refute Chat.blocked?(buyer.id, store.id)
  end

  @tag :db
  test "blocked?/2 — true jika toko spesifik diblokir" do
    buyer = insert_user()
    owner = insert_user()
    store = insert_store(owner.id)
    Chat.block_store(buyer.id, store.id)

    assert Chat.blocked?(buyer.id, store.id)
  end

  @tag :db
  test "blocked?/2 — true jika global block aktif" do
    buyer = insert_user()
    owner = insert_user()
    store = insert_store(owner.id)
    Chat.block_all_sellers(buyer.id)

    assert Chat.blocked?(buyer.id, store.id)
  end

  @tag :db
  test "blocked?/2 — false setelah unblock" do
    buyer = insert_user()
    owner = insert_user()
    store = insert_store(owner.id)
    Chat.block_store(buyer.id, store.id)
    Chat.unblock_store(buyer.id, store.id)

    refute Chat.blocked?(buyer.id, store.id)
  end
end
