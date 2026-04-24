defmodule TrenurangCore.Context.Reward do
  @moduledoc """
  Context untuk store reward management.

  Flow reward:
  1. Seller buat reward via create_reward/2 (sebelum generate kode)
  2. Saat generate kode, Order context embed reward_id ke kode golden secara random
  3. Saat order confirmed dan is_golden, buyer klaim via claim_reward/1
  4. claimed_count increment — jika == total_codes, status berubah ke "exhausted"
  5. RewardCleanupWorker panggil expire_overdue_rewards/0 tiap tengah malam
  """

  import Ecto.Query
  alias TrenurangCore.Repo
  alias TrenurangCore.Schema.StoreReward

  # ---- Create ----

  @doc """
  Seller buat reward sebelum generate kode.
  total_codes harus <= kapasitas generate yang akan dipakai.
  """
  def create_reward(store_id, attrs) do
    %StoreReward{}
    |> StoreReward.changeset(Map.merge(attrs, %{store_id: store_id}))
    |> Repo.insert()
  end

  # ---- Read ----

  @doc "Ambil reward by ID."
  def get_reward(id), do: Repo.get(StoreReward, id)

  @doc "List semua reward milik sebuah toko."
  def list_store_rewards(store_id) do
    from(r in StoreReward,
      where: r.store_id == ^store_id,
      order_by: [desc: r.inserted_at]
    )
    |> Repo.all()
  end

  @doc "List reward aktif milik sebuah toko."
  def list_active_rewards(store_id) do
    from(r in StoreReward,
      where: r.store_id == ^store_id and r.status == "active",
      order_by: [desc: r.inserted_at]
    )
    |> Repo.all()
  end

  # ---- Claim ----

  @doc """
  Buyer klaim reward dari golden code yang di-confirm.
  Increment claimed_count.
  Jika claimed_count == total_codes → status: exhausted.
  Jika reward sudah expired/exhausted → {:error, :reward_not_claimable}.
  """
  def claim_reward(reward_id) do
    Repo.transaction(fn ->
      reward = Repo.get!(StoreReward, reward_id)

      if reward.status != "active" do
        Repo.rollback(:reward_not_claimable)
      end

      new_claimed = reward.claimed_count + 1

      new_status =
        if new_claimed >= reward.total_codes, do: "exhausted", else: "active"

      reward
      |> StoreReward.changeset(%{
        claimed_count: new_claimed,
        status:        new_status
      })
      |> Repo.update!()
    end)
  end

  # ---- Expire ----

  @doc """
  Batch expire semua reward aktif yang sudah lewat claim_deadline.
  Dipanggil oleh RewardCleanupWorker tiap tengah malam.
  Return: jumlah reward yang di-expire.
  """
  def expire_overdue_rewards do
    today = Date.utc_today()

    {count, _} =
      from(r in StoreReward,
        where: r.status == "active" and r.claim_deadline < ^today
      )
      |> Repo.update_all(set: [status: "expired"])

    {:ok, count}
  end
end
