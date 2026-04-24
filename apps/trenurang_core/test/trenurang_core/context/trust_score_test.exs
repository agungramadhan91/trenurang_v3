defmodule TrenurangCore.Context.TrustScoreTest do
  use ExUnit.Case, async: false

  alias TrenurangCore.Repo
  alias TrenurangCore.Schema.{User, Store, UserTrustScore, StoreTrustScore}
  alias TrenurangCore.Context.TrustScore
  alias TrenurangCore.TrustScore.ETS, as: TrustScoreETS

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    :ets.delete_all_objects(:trenurang_user_trust_scores)
    :ets.delete_all_objects(:trenurang_store_trust_scores)
    :ok
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

  defp insert_user_trust_score(user_id, attrs \\ %{}) do
    defaults = %{
      user_id:           user_id,
      score:             350,
      tier:              "pemula_aktif",
      is_cold_start:     true,
      cold_start_ends_at: Date.add(Date.utc_today(), 90)
    }
    {:ok, ts} =
      %UserTrustScore{}
      |> UserTrustScore.changeset(Map.merge(defaults, attrs))
      |> Repo.insert()
    ts
  end

  defp insert_store_trust_score(store_id, attrs \\ %{}) do
    defaults = %{
      store_id:           store_id,
      score:              350,
      tier:               "pemula_aktif",
      is_cold_start:      true,
      cold_start_ends_at: Date.add(Date.utc_today(), 90)
    }
    {:ok, ts} =
      %StoreTrustScore{}
      |> StoreTrustScore.changeset(Map.merge(defaults, attrs))
      |> Repo.insert()
    ts
  end

  # ---- tier_for_score/1 ----

  test "tier_for_score/1 — mapping benar" do
    assert TrustScore.tier_for_score(1000) == "juragan"
    assert TrustScore.tier_for_score(900)  == "juragan"
    assert TrustScore.tier_for_score(899)  == "pedagang_andal"
    assert TrustScore.tier_for_score(750)  == "pedagang_andal"
    assert TrustScore.tier_for_score(749)  == "pedagang_tumbuh"
    assert TrustScore.tier_for_score(550)  == "pedagang_tumbuh"
    assert TrustScore.tier_for_score(549)  == "pemula_aktif"
    assert TrustScore.tier_for_score(350)  == "pemula_aktif"
    assert TrustScore.tier_for_score(349)  == "belum_teruji"
    assert TrustScore.tier_for_score(0)    == "belum_teruji"
  end

  # ---- capacity_for_tier/1 ----

  test "capacity_for_tier/1 — mapping benar" do
    assert TrustScore.capacity_for_tier("juragan")         == 250
    assert TrustScore.capacity_for_tier("pedagang_andal")  == 150
    assert TrustScore.capacity_for_tier("pedagang_tumbuh") == 100
    assert TrustScore.capacity_for_tier("pemula_aktif")    == 75
    assert TrustScore.capacity_for_tier("belum_teruji")    == 50
  end

  # ---- recalculate_user/1 ----

  @tag :db
  test "recalculate_user/1 — score naik dengan riwayat baik" do
    user = insert_user()
    insert_user_trust_score(user.id, %{
      on_time_count:    10,
      late_count:       0,
      cancel_count:     0,
      total_order_count: 10,
      dispute_raised:   0,
      dispute_lost:     0
    })

    assert {:ok, updated} = TrustScore.recalculate_user(user.id)
    # payment 100%, cancel 0%, dispute 0%, longevity minimal
    # score sekitar (0.40 + 0.25 + 0.20) * 1000 = 850 (tanpa longevity karena baru)
    assert updated.score >= 800
    assert updated.tier in ["pedagang_andal", "juragan", "pedagang_tumbuh"]
    refute is_nil(updated.last_recalculated_at)
  end

  @tag :db
  test "recalculate_user/1 — score rendah dengan riwayat buruk" do
    user = insert_user()
    insert_user_trust_score(user.id, %{
      on_time_count:    0,
      late_count:       10,
      cancel_count:     8,
      total_order_count: 10,
      dispute_raised:   5,
      dispute_lost:     5
    })

    assert {:ok, updated} = TrustScore.recalculate_user(user.id)
    # payment 0%, cancel 80%, dispute 100%
    assert updated.score < 200
    assert updated.tier == "belum_teruji"
  end

  @tag :db
  test "recalculate_user/1 — zero transaksi, score dari (1-0)*0.25 + (1-0)*0.20 = 450" do
    user = insert_user()
    insert_user_trust_score(user.id)

    assert {:ok, updated} = TrustScore.recalculate_user(user.id)
    # payment=0 (0/0), cancel=0 (0/0), dispute=0 (0/1), longevity=~0
    # score = (0*0.40 + 1*0.25 + 1*0.20 + 0*0.15) * 1000 = 450
    assert updated.score == 450
    assert updated.tier == "pemula_aktif"
  end

  @tag :db
  test "recalculate_user/1 — is_cold_start false setelah cold_start_ends_at lewat" do
    user = insert_user()
    insert_user_trust_score(user.id, %{
      is_cold_start:     true,
      cold_start_ends_at: Date.add(Date.utc_today(), -1)  # sudah lewat
    })

    assert {:ok, updated} = TrustScore.recalculate_user(user.id)
    assert updated.is_cold_start == false
  end

  @tag :db
  test "recalculate_user/1 — is_cold_start tetap true jika belum lewat" do
    user = insert_user()
    insert_user_trust_score(user.id, %{
      is_cold_start:     true,
      cold_start_ends_at: Date.add(Date.utc_today(), 30)
    })

    assert {:ok, updated} = TrustScore.recalculate_user(user.id)
    assert updated.is_cold_start == true
  end

  @tag :db
  test "recalculate_user/1 — ETS diinvalidate setelah recalculate" do
    user = insert_user()
    insert_user_trust_score(user.id)

    # Isi ETS dengan data lama
    TrustScoreETS.put_user("u##{user.id}", %{score: 999, tier: :juragan})

    assert {:ok, _} = TrustScore.recalculate_user(user.id)

    # ETS harus sudah dihapus
    assert TrustScoreETS.get_user("u##{user.id}") == nil
  end

  @tag :db
  test "recalculate_user/1 — return :not_found jika trust score tidak ada" do
    user = insert_user()
    assert {:error, :not_found} = TrustScore.recalculate_user(user.id)
  end

  # ---- recalculate_store/1 ----

  @tag :db
  test "recalculate_store/1 — cold start pakai bobot 5 komponen" do
    owner = insert_user()
    store = insert_store(owner.id)
    insert_store_trust_score(store.id, %{
      is_cold_start:      true,
      cold_start_ends_at: Date.add(Date.utc_today(), 60),
      completed_count:    10,
      cancelled_count:    0,
      on_time_count:      5,
      late_count:         0,
      repeat_buyer_count: 3,
      total_unique_buyers: 5,
      dispute_raised:     0,
      dispute_lost:       0,
      unique_partners:    2
    })

    assert {:ok, updated} = TrustScore.recalculate_store(store.id)
    # pay_rel=1.0(30%) + fulfill=1.0(25%) + repeat=0.6(20%) + dispute=1.0(15%) + network=0.2(10%)
    # = 0.30 + 0.25 + 0.12 + 0.15 + 0.02 = 0.84 → 840
    assert updated.score == 840
    assert updated.tier == "pedagang_andal"
    assert updated.is_cold_start == true
  end

  @tag :db
  test "recalculate_store/1 — non cold start pakai bobot 7 komponen" do
    owner = insert_user()
    store = insert_store(owner.id)
    insert_store_trust_score(store.id, %{
      is_cold_start:      false,
      cold_start_ends_at: Date.add(Date.utc_today(), -1),
      completed_count:    10,
      cancelled_count:    0,
      on_time_count:      10,
      late_count:         0,
      repeat_buyer_count: 4,
      total_unique_buyers: 5,
      dispute_raised:     0,
      dispute_lost:       0,
      unique_partners:    5
      # longevity dan growth dari formula (longevity ~0 karena baru insert)
    })

    assert {:ok, updated} = TrustScore.recalculate_store(store.id)
    # Semua komponen baik tapi longevity ~0, growth=0
    # pay_rel=1(25%) + fulfill=1(20%) + repeat=0.8(20%) + dispute=1(15%) + network=0.5(10%) + longevity~0(7%) + growth=0(3%)
    # ≈ 0.25 + 0.20 + 0.16 + 0.15 + 0.05 + 0 + 0 = 0.81 → 810
    assert updated.score in 800..850
    assert updated.tier == "pedagang_andal"
    assert updated.is_cold_start == false
  end

  @tag :db
  test "recalculate_store/1 — cold start ends saat cold_start_ends_at lewat" do
    owner = insert_user()
    store = insert_store(owner.id)
    insert_store_trust_score(store.id, %{
      is_cold_start:      true,
      cold_start_ends_at: Date.add(Date.utc_today(), -1)
    })

    assert {:ok, updated} = TrustScore.recalculate_store(store.id)
    assert updated.is_cold_start == false
  end

  @tag :db
  test "recalculate_store/1 — ETS diinvalidate setelah recalculate" do
    owner = insert_user()
    store = insert_store(owner.id)
    insert_store_trust_score(store.id)

    TrustScoreETS.put_store("s@#{store.id}", %{score: 999, tier: :juragan, capacity: 250})

    assert {:ok, _} = TrustScore.recalculate_store(store.id)
    assert TrustScoreETS.get_store("s@#{store.id}") == nil
  end

  @tag :db
  test "recalculate_store/1 — return :not_found jika trust score tidak ada" do
    owner = insert_user()
    store = insert_store(owner.id)
    assert {:error, :not_found} = TrustScore.recalculate_store(store.id)
  end

  # ---- get_user_trust_score/1 ----

  @tag :db
  test "get_user_trust_score/1 — ambil dari DB jika ETS miss, populate ETS" do
    user = insert_user()
    insert_user_trust_score(user.id, %{score: 600, tier: "pedagang_tumbuh"})

    result = TrustScore.get_user_trust_score(user.id)
    assert result.score == 600
    assert result.tier == :pedagang_tumbuh

    # Sekarang harus ada di ETS
    cached = TrustScoreETS.get_user("u##{user.id}")
    assert cached.score == 600
  end

  @tag :db
  test "get_user_trust_score/1 — ambil dari ETS jika ada" do
    user = insert_user()
    TrustScoreETS.put_user("u##{user.id}", %{score: 777, tier: :pedagang_andal})

    result = TrustScore.get_user_trust_score(user.id)
    assert result.score == 777
  end

  @tag :db
  test "get_user_trust_score/1 — return nil jika tidak ada" do
    user = insert_user()
    assert nil == TrustScore.get_user_trust_score(user.id)
  end

  # ---- get_store_trust_score/1 ----

  @tag :db
  test "get_store_trust_score/1 — ambil dari DB jika ETS miss, populate ETS" do
    owner = insert_user()
    store = insert_store(owner.id)
    insert_store_trust_score(store.id, %{score: 800, tier: "pedagang_andal"})

    result = TrustScore.get_store_trust_score(store.id)
    assert result.score == 800
    assert result.capacity == 150

    cached = TrustScoreETS.get_store("s@#{store.id}")
    assert cached.score == 800
  end

  @tag :db
  test "get_store_trust_score/1 — return nil jika tidak ada" do
    owner = insert_user()
    store = insert_store(owner.id)
    assert nil == TrustScore.get_store_trust_score(store.id)
  end
end
