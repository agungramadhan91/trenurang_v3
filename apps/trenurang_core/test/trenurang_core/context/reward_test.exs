defmodule TrenurangCore.Context.RewardTest do
  use ExUnit.Case, async: false

  alias TrenurangCore.Repo
  alias TrenurangCore.Schema.{User, Store, StoreReward}
  alias TrenurangCore.Context.Reward

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

  defp insert_reward(store_id, attrs \\ %{}) do
    defaults = %{
      type:           "discount",
      description:    "Diskon 10%",
      value:          %{"percent" => 10},
      claim_deadline: Date.add(Date.utc_today(), 30),
      total_codes:    5,
      batch_date:     Date.utc_today(),
      status:         "active"
    }
    {:ok, r} =
      %StoreReward{}
      |> StoreReward.changeset(Map.merge(defaults, Map.merge(%{store_id: store_id}, attrs)))
      |> Repo.insert()
    r
  end

  # ---- create_reward/2 ----

  @tag :db
  test "create_reward/2 — sukses dengan attrs valid" do
    owner = insert_user()
    store = insert_store(owner.id)

    attrs = %{
      type:           "discount",
      description:    "Diskon 15%",
      value:          %{"percent" => 15},
      claim_deadline: Date.add(Date.utc_today(), 14),
      total_codes:    10,
      batch_date:     Date.utc_today()
    }

    assert {:ok, reward} = Reward.create_reward(store.id, attrs)
    assert reward.store_id == store.id
    assert reward.type == "discount"
    assert reward.total_codes == 10
    assert reward.claimed_count == 0
    assert reward.status == "active"
  end

  @tag :db
  test "create_reward/2 — gagal jika total_codes 0" do
    owner = insert_user()
    store = insert_store(owner.id)

    attrs = %{
      type:           "discount",
      description:    "X",
      value:          %{},
      claim_deadline: Date.add(Date.utc_today(), 7),
      total_codes:    0,
      batch_date:     Date.utc_today()
    }

    assert {:error, cs} = Reward.create_reward(store.id, attrs)
    assert cs.errors[:total_codes]
  end

  # ---- get_reward/1 ----

  @tag :db
  test "get_reward/1 — return reward jika ada" do
    owner  = insert_user()
    store  = insert_store(owner.id)
    reward = insert_reward(store.id)

    assert %StoreReward{} = Reward.get_reward(reward.id)
  end

  @tag :db
  test "get_reward/1 — return nil jika tidak ada" do
    assert nil == Reward.get_reward(0)
  end

  # ---- list_store_rewards/1 ----

  @tag :db
  test "list_store_rewards/1 — return semua reward toko" do
    owner = insert_user()
    store = insert_store(owner.id)
    insert_reward(store.id)
    insert_reward(store.id)

    result = Reward.list_store_rewards(store.id)
    assert length(result) == 2
  end

  # ---- list_active_rewards/1 ----

  @tag :db
  test "list_active_rewards/1 — hanya return yang active" do
    owner = insert_user()
    store = insert_store(owner.id)
    insert_reward(store.id, %{status: "active"})
    insert_reward(store.id, %{status: "expired"})
    insert_reward(store.id, %{status: "exhausted"})

    result = Reward.list_active_rewards(store.id)
    assert length(result) == 1
    assert hd(result).status == "active"
  end

  # ---- claim_reward/1 ----

  @tag :db
  test "claim_reward/1 — increment claimed_count" do
    owner  = insert_user()
    store  = insert_store(owner.id)
    reward = insert_reward(store.id, %{total_codes: 5, claimed_count: 0})

    assert {:ok, updated} = Reward.claim_reward(reward.id)
    assert updated.claimed_count == 1
    assert updated.status == "active"
  end

  @tag :db
  test "claim_reward/1 — status exhausted saat klaim terakhir" do
    owner  = insert_user()
    store  = insert_store(owner.id)
    reward = insert_reward(store.id, %{total_codes: 2, claimed_count: 1})

    assert {:ok, updated} = Reward.claim_reward(reward.id)
    assert updated.claimed_count == 2
    assert updated.status == "exhausted"
  end

  @tag :db
  test "claim_reward/1 — gagal jika reward expired" do
    owner  = insert_user()
    store  = insert_store(owner.id)
    reward = insert_reward(store.id, %{status: "expired"})

    assert {:error, :reward_not_claimable} = Reward.claim_reward(reward.id)
  end

  @tag :db
  test "claim_reward/1 — gagal jika reward exhausted" do
    owner  = insert_user()
    store  = insert_store(owner.id)
    reward = insert_reward(store.id, %{status: "exhausted"})

    assert {:error, :reward_not_claimable} = Reward.claim_reward(reward.id)
  end

  # ---- expire_overdue_rewards/0 ----

  @tag :db
  test "expire_overdue_rewards/0 — expire reward yang sudah lewat deadline" do
    owner = insert_user()
    store = insert_store(owner.id)

    # Deadline kemarin → harus di-expire
    insert_reward(store.id, %{claim_deadline: Date.add(Date.utc_today(), -1)})
    # Deadline besok → tidak di-expire
    insert_reward(store.id, %{claim_deadline: Date.add(Date.utc_today(), 1)})

    assert {:ok, 1} = Reward.expire_overdue_rewards()

    all = Reward.list_store_rewards(store.id)
    expired   = Enum.filter(all, &(&1.status == "expired"))
    still_active = Enum.filter(all, &(&1.status == "active"))
    assert length(expired) == 1
    assert length(still_active) == 1
  end

  @tag :db
  test "expire_overdue_rewards/0 — return 0 jika tidak ada yang expire" do
    owner = insert_user()
    store = insert_store(owner.id)
    insert_reward(store.id, %{claim_deadline: Date.add(Date.utc_today(), 7)})

    assert {:ok, 0} = Reward.expire_overdue_rewards()
  end
end
