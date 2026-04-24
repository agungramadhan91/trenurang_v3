defmodule TrenurangCore.Context.RelationTest do
  use ExUnit.Case, async: false

  alias TrenurangCore.Repo
  alias TrenurangCore.Schema.{User, Store}
  alias TrenurangCore.Context.Relation

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  end

  # ---- Helpers ----

  defp insert_user do
    n = System.unique_integer([:positive])
    {:ok, user} =
      %User{}
      |> User.changeset(%{name: "Owner", username: "owner#{n}", lang: "id"})
      |> Repo.insert()
    user
  end

  defp insert_store(owner_id) do
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
    store
  end

  defp insert_relation(supplier_id, receiver_id, type \\ "konsinyasi") do
    {:ok, r} = Relation.create_relation(supplier_id, receiver_id, type)
    r
  end

  # ---- create_relation/3 ----

  @tag :db
  test "create_relation/3 — sukses buat relasi baru" do
    u1 = insert_user()
    u2 = insert_user()
    s1 = insert_store(u1.id)
    s2 = insert_store(u2.id)

    assert {:ok, relation} = Relation.create_relation(s1.id, s2.id, "konsinyasi")
    assert relation.supplier_id == s1.id
    assert relation.receiver_id == s2.id
    assert relation.type == "konsinyasi"
    assert String.length(relation.code) == 6
    assert String.match?(relation.code, ~r/^[A-Z0-9]{6}$/)
  end

  @tag :db
  test "create_relation/3 — {:error, :already_exists} jika relasi sama sudah ada" do
    u1 = insert_user()
    u2 = insert_user()
    s1 = insert_store(u1.id)
    s2 = insert_store(u2.id)

    insert_relation(s1.id, s2.id, "konsinyasi")
    assert {:error, :already_exists} = Relation.create_relation(s1.id, s2.id, "konsinyasi")
  end

  @tag :db
  test "create_relation/3 — {:error, :already_exists} jika posisi supplier/receiver dibalik" do
    u1 = insert_user()
    u2 = insert_user()
    s1 = insert_store(u1.id)
    s2 = insert_store(u2.id)

    insert_relation(s1.id, s2.id, "beli_putus")
    assert {:error, :already_exists} = Relation.create_relation(s2.id, s1.id, "beli_putus")
  end

  @tag :db
  test "create_relation/3 — tipe berbeda pada pasang toko yang sama diizinkan" do
    u1 = insert_user()
    u2 = insert_user()
    s1 = insert_store(u1.id)
    s2 = insert_store(u2.id)

    assert {:ok, _} = Relation.create_relation(s1.id, s2.id, "konsinyasi")
    assert {:ok, _} = Relation.create_relation(s1.id, s2.id, "kontrak_jasa")
  end

  @tag :db
  test "create_relation/3 — {:error, changeset} jika type tidak valid" do
    u1 = insert_user()
    u2 = insert_user()
    s1 = insert_store(u1.id)
    s2 = insert_store(u2.id)

    assert {:error, changeset} = Relation.create_relation(s1.id, s2.id, "invalid_type")
    assert changeset.errors != []
  end

  @tag :db
  test "create_relation/3 — code unik untuk setiap relasi" do
    u1 = insert_user()
    u2 = insert_user()
    u3 = insert_user()
    s1 = insert_store(u1.id)
    s2 = insert_store(u2.id)
    s3 = insert_store(u3.id)

    {:ok, r1} = Relation.create_relation(s1.id, s2.id, "konsinyasi")
    {:ok, r2} = Relation.create_relation(s1.id, s3.id, "konsinyasi")

    refute r1.code == r2.code
  end

  # ---- get_relation/1 ----

  @tag :db
  test "get_relation/1 — return relasi jika ada" do
    u1 = insert_user()
    u2 = insert_user()
    s1 = insert_store(u1.id)
    s2 = insert_store(u2.id)
    r  = insert_relation(s1.id, s2.id)

    assert fetched = Relation.get_relation(r.id)
    assert fetched.id == r.id
  end

  @tag :db
  test "get_relation/1 — return nil jika tidak ada" do
    assert nil == Relation.get_relation(999_999_999)
  end

  # ---- get_relation_by_code/1 ----

  @tag :db
  test "get_relation_by_code/1 — return relasi berdasarkan kode" do
    u1 = insert_user()
    u2 = insert_user()
    s1 = insert_store(u1.id)
    s2 = insert_store(u2.id)
    r  = insert_relation(s1.id, s2.id)

    assert fetched = Relation.get_relation_by_code(r.code)
    assert fetched.id == r.id
  end

  @tag :db
  test "get_relation_by_code/1 — case-insensitive" do
    u1 = insert_user()
    u2 = insert_user()
    s1 = insert_store(u1.id)
    s2 = insert_store(u2.id)
    r  = insert_relation(s1.id, s2.id)

    assert fetched = Relation.get_relation_by_code(String.downcase(r.code))
    assert fetched.id == r.id
  end

  @tag :db
  test "get_relation_by_code/1 — return nil jika tidak ada" do
    assert nil == Relation.get_relation_by_code("ZZZZZZ")
  end

  # ---- list_relations_by_store/1 ----

  @tag :db
  test "list_relations_by_store/1 — return relasi sebagai supplier" do
    u1 = insert_user()
    u2 = insert_user()
    s1 = insert_store(u1.id)
    s2 = insert_store(u2.id)
    r  = insert_relation(s1.id, s2.id)

    result = Relation.list_relations_by_store(s1.id)
    ids = Enum.map(result, & &1.id)
    assert r.id in ids
  end

  @tag :db
  test "list_relations_by_store/1 — return relasi sebagai receiver" do
    u1 = insert_user()
    u2 = insert_user()
    s1 = insert_store(u1.id)
    s2 = insert_store(u2.id)
    r  = insert_relation(s1.id, s2.id)

    result = Relation.list_relations_by_store(s2.id)
    ids = Enum.map(result, & &1.id)
    assert r.id in ids
  end

  @tag :db
  test "list_relations_by_store/1 — tidak return relasi toko lain" do
    u1 = insert_user()
    u2 = insert_user()
    u3 = insert_user()
    s1 = insert_store(u1.id)
    s2 = insert_store(u2.id)
    s3 = insert_store(u3.id)
    r_others = insert_relation(s1.id, s2.id)

    result = Relation.list_relations_by_store(s3.id)
    ids = Enum.map(result, & &1.id)
    refute r_others.id in ids
  end

  @tag :db
  test "list_relations_by_store/1 — return [] jika belum ada relasi" do
    u1 = insert_user()
    s1 = insert_store(u1.id)
    assert [] == Relation.list_relations_by_store(s1.id)
  end

  # ---- update_agreement/2 ----

  @tag :db
  test "update_agreement/2 — sukses update teks agreement" do
    u1 = insert_user()
    u2 = insert_user()
    s1 = insert_store(u1.id)
    s2 = insert_store(u2.id)
    r  = insert_relation(s1.id, s2.id)

    agreement = "Konsinyasi 30 hari, margin 15%, settle tiap Jumat."
    assert {:ok, updated} = Relation.update_agreement(r, agreement)
    assert updated.agreement == agreement
  end

  # ---- add_settlement/2 & list_settlements/1 ----

  @tag :db
  test "add_settlement/2 — sukses tambah settlement" do
    u1 = insert_user()
    u2 = insert_user()
    s1 = insert_store(u1.id)
    s2 = insert_store(u2.id)
    r  = insert_relation(s1.id, s2.id)

    assert {:ok, settlement} = Relation.add_settlement(r.id, %{
      amount: Decimal.new("500000"),
      notes:  "Bayar minggu ini"
    })
    assert settlement.relation_id == r.id
    assert settlement.status == "pending"
  end

  @tag :db
  test "list_settlements/1 — return semua settlement milik relasi" do
    u1 = insert_user()
    u2 = insert_user()
    s1 = insert_store(u1.id)
    s2 = insert_store(u2.id)
    r  = insert_relation(s1.id, s2.id)

    {:ok, s1_rec} = Relation.add_settlement(r.id, %{amount: Decimal.new("100000")})
    {:ok, s2_rec} = Relation.add_settlement(r.id, %{amount: Decimal.new("200000")})

    result = Relation.list_settlements(r.id)
    ids = Enum.map(result, & &1.id)
    assert s1_rec.id in ids
    assert s2_rec.id in ids
  end

  @tag :db
  test "list_settlements/1 — return [] jika belum ada settlement" do
    u1 = insert_user()
    u2 = insert_user()
    s1 = insert_store(u1.id)
    s2 = insert_store(u2.id)
    r  = insert_relation(s1.id, s2.id)

    assert [] == Relation.list_settlements(r.id)
  end
end
