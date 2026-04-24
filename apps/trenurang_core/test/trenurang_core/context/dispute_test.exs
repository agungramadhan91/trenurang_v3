defmodule TrenurangCore.Context.DisputeTest do
  use ExUnit.Case, async: false

  alias TrenurangCore.Repo
  alias TrenurangCore.Schema.{User, Store, StoreOrder, Dispute}
  alias TrenurangCore.Context.Dispute, as: DisputeContext

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

  defp insert_order(buyer_id, seller_id, status \\ "completed") do
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

  defp insert_dispute(order_id, raised_by_id, against_id, status \\ "open") do
    {:ok, d} =
      %Dispute{}
      |> Dispute.changeset(%{
        order_id:     order_id,
        raised_by_id: raised_by_id,
        against_id:   against_id,
        reason:       "Barang tidak sesuai",
        status:       status
      })
      |> Repo.insert()
    d
  end

  # ---- open_dispute/5 ----

  @tag :db
  test "open_dispute/5 — sukses, order berubah ke disputed" do
    buyer  = insert_user()
    seller = insert_user()
    _store = insert_store(seller.id)
    order  = insert_order(buyer.id, seller.id, "confirmed")

    assert {:ok, dispute} =
      DisputeContext.open_dispute(order.id, buyer.id, seller.id, "Barang rusak")

    assert dispute.status == "open"
    assert dispute.reason == "Barang rusak"

    updated_order = Repo.get!(StoreOrder, order.id)
    assert updated_order.status == "disputed"
  end

  @tag :db
  test "open_dispute/5 — gagal jika order sudah cancelled" do
    buyer  = insert_user()
    seller = insert_user()
    order  = insert_order(buyer.id, seller.id, "cancelled")

    assert {:error, {:invalid_order_status, "cancelled"}} =
      DisputeContext.open_dispute(order.id, buyer.id, seller.id, "Test")
  end

  @tag :db
  test "open_dispute/5 — gagal jika order sudah disputed" do
    buyer  = insert_user()
    seller = insert_user()
    order  = insert_order(buyer.id, seller.id, "disputed")

    assert {:error, {:invalid_order_status, "disputed"}} =
      DisputeContext.open_dispute(order.id, buyer.id, seller.id, "Test")
  end

  @tag :db
  test "open_dispute/5 — gagal jika sudah ada dispute aktif untuk order" do
    buyer  = insert_user()
    seller = insert_user()
    order  = insert_order(buyer.id, seller.id, "confirmed")
    _d1    = insert_dispute(order.id, buyer.id, seller.id, "open")
    # Paksa order ke confirmed lagi supaya bisa uji cek duplikat
    Repo.update!(StoreOrder.changeset(order, %{status: "confirmed"}))

    assert {:error, :dispute_already_exists} =
      DisputeContext.open_dispute(order.id, buyer.id, seller.id, "Coba lagi")
  end

  @tag :db
  test "open_dispute/5 — bisa dengan evidence" do
    buyer  = insert_user()
    seller = insert_user()
    order  = insert_order(buyer.id, seller.id, "confirmed")

    evidence = [%{"type" => "foto", "url" => "http://example.com/foto.jpg"}]

    assert {:ok, dispute} =
      DisputeContext.open_dispute(order.id, buyer.id, seller.id, "Bukti ada", evidence)

    assert dispute.evidence == evidence
  end

  # ---- get_dispute/1 ----

  @tag :db
  test "get_dispute/1 — return dispute jika ada" do
    buyer  = insert_user()
    seller = insert_user()
    order  = insert_order(buyer.id, seller.id)
    d      = insert_dispute(order.id, buyer.id, seller.id)

    assert %Dispute{} = DisputeContext.get_dispute(d.id)
  end

  @tag :db
  test "get_dispute/1 — return nil jika tidak ada" do
    assert nil == DisputeContext.get_dispute(0)
  end

  # ---- get_dispute_by_order/1 ----

  @tag :db
  test "get_dispute_by_order/1 — return dispute terbaru untuk order" do
    buyer  = insert_user()
    seller = insert_user()
    order  = insert_order(buyer.id, seller.id)
    d      = insert_dispute(order.id, buyer.id, seller.id)

    result = DisputeContext.get_dispute_by_order(order.id)
    assert result.id == d.id
  end

  @tag :db
  test "get_dispute_by_order/1 — return nil jika tidak ada dispute" do
    buyer  = insert_user()
    seller = insert_user()
    order  = insert_order(buyer.id, seller.id)

    assert nil == DisputeContext.get_dispute_by_order(order.id)
  end

  # ---- list_disputes_raised_by/1 ----

  @tag :db
  test "list_disputes_raised_by/1 — return semua dispute yang diajukan user" do
    buyer  = insert_user()
    seller = insert_user()
    o1     = insert_order(buyer.id, seller.id)
    o2     = insert_order(buyer.id, seller.id)
    insert_dispute(o1.id, buyer.id, seller.id)
    insert_dispute(o2.id, buyer.id, seller.id)

    result = DisputeContext.list_disputes_raised_by(buyer.id)
    assert length(result) == 2
  end

  # ---- update_status/2 ----

  @tag :db
  test "update_status/2 — under_review sukses" do
    buyer  = insert_user()
    seller = insert_user()
    order  = insert_order(buyer.id, seller.id)
    d      = insert_dispute(order.id, buyer.id, seller.id)

    assert {:ok, updated} = DisputeContext.update_status(d.id, "under_review")
    assert updated.status == "under_review"
  end

  @tag :db
  test "update_status/2 — dismissed sukses" do
    buyer  = insert_user()
    seller = insert_user()
    order  = insert_order(buyer.id, seller.id)
    d      = insert_dispute(order.id, buyer.id, seller.id)

    assert {:ok, updated} = DisputeContext.update_status(d.id, "dismissed")
    assert updated.status == "dismissed"
  end

  @tag :db
  test "update_status/2 — return :not_found jika dispute tidak ada" do
    assert {:error, :not_found} = DisputeContext.update_status(0, "under_review")
  end

  # ---- resolve_dispute/2 ----

  @tag :db
  test "resolve_dispute/2 — sukses, order kembali ke completed" do
    buyer  = insert_user()
    seller = insert_user()
    order  = insert_order(buyer.id, seller.id, "disputed")
    d      = insert_dispute(order.id, buyer.id, seller.id)

    assert {:ok, resolved} = DisputeContext.resolve_dispute(d.id, "Sepakat dikembalikan")
    assert resolved.status == "resolved"
    assert resolved.resolution == "Sepakat dikembalikan"
    refute is_nil(resolved.resolved_at)

    updated_order = Repo.get!(StoreOrder, order.id)
    assert updated_order.status == "completed"
  end

  @tag :db
  test "resolve_dispute/2 — gagal jika sudah resolved" do
    buyer  = insert_user()
    seller = insert_user()
    order  = insert_order(buyer.id, seller.id, "disputed")
    d      = insert_dispute(order.id, buyer.id, seller.id, "resolved")

    assert {:error, :already_resolved} = DisputeContext.resolve_dispute(d.id, "Dup")
  end

  # ---- add_evidence/2 ----

  @tag :db
  test "add_evidence/2 — append evidence ke dispute" do
    buyer  = insert_user()
    seller = insert_user()
    order  = insert_order(buyer.id, seller.id)
    d      = insert_dispute(order.id, buyer.id, seller.id)

    e1 = [%{"type" => "foto", "url" => "http://example.com/1.jpg"}]
    e2 = [%{"type" => "chat", "log" => "lorem ipsum"}]

    {:ok, after_e1} = DisputeContext.add_evidence(d.id, e1)
    assert length(after_e1.evidence) == 1

    {:ok, after_e2} = DisputeContext.add_evidence(d.id, e2)
    assert length(after_e2.evidence) == 2
  end

  @tag :db
  test "add_evidence/2 — return :not_found jika dispute tidak ada" do
    assert {:error, :not_found} = DisputeContext.add_evidence(0, [%{"x" => "y"}])
  end
end
