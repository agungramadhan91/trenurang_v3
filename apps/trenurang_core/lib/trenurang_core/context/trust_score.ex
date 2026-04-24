defmodule TrenurangCore.Context.TrustScore do
  @moduledoc """
  Context untuk recalculate dan query trust score.

  Personal Trust Score formula (4 komponen):
    - payment_on_time_rate : bobot 40%
    - cancellation_rate    : bobot 25% (skor = 1 - rate)
    - dispute_ratio        : bobot 20% (skor = 1 - ratio)
    - longevity            : bobot 15% (dinormalisasi 24 bulan)

  Store Trust Score formula (7 komponen normal / 5 komponen cold start):
    Normal      : pay_rel(25%) + fulfill(20%) + repeat_buyer(20%) +
                  dispute(15%) + network(10%) + longevity(7%) + growth(3%)
    Cold start  : pay_rel(30%) + fulfill(25%) + repeat_buyer(20%) +
                  dispute(15%) + network(10%) — tanpa longevity dan growth

  Score range 0–1000. Tier ditentukan dari score.
  ETS diinvalidate setelah setiap recalculate.
  """

  alias TrenurangCore.Repo
  alias TrenurangCore.Schema.{User, Store, UserTrustScore, StoreTrustScore}
  alias TrenurangCore.TrustScore.ETS, as: TrustScoreETS

  @capacity_by_tier %{
    "juragan"          => 250,
    "pedagang_andal"   => 150,
    "pedagang_tumbuh"  => 100,
    "pemula_aktif"     => 75,
    "belum_teruji"     => 50
  }

  # ---- Public API ----

  @doc """
  Kembalikan tier string berdasarkan score.
  Pure function — digunakan di mana saja.
  """
  def tier_for_score(score) when score >= 900, do: "juragan"
  def tier_for_score(score) when score >= 750, do: "pedagang_andal"
  def tier_for_score(score) when score >= 550, do: "pedagang_tumbuh"
  def tier_for_score(score) when score >= 350, do: "pemula_aktif"
  def tier_for_score(_),                        do: "belum_teruji"

  @doc "Kembalikan kapasitas generate kode berdasarkan tier."
  def capacity_for_tier(tier), do: Map.fetch!(@capacity_by_tier, tier)

  @doc """
  Ambil personal trust score.
  ETS-first, fallback ke DB. Populate ETS jika miss.
  Return: map ETS struct | nil
  """
  def get_user_trust_score(user_id) do
    ets_key = "u##{user_id}"
    case TrustScoreETS.get_user(ets_key) do
      nil ->
        case Repo.get_by(UserTrustScore, user_id: user_id) do
          nil -> nil
          ts  ->
            data = user_ets_data(ets_key, ts)
            TrustScoreETS.put_user(ets_key, data)
            data
        end
      cached -> cached
    end
  end

  @doc """
  Ambil store trust score.
  ETS-first, fallback ke DB. Populate ETS jika miss.
  Return: map ETS struct | nil
  """
  def get_store_trust_score(store_id) do
    ets_key = "s@#{store_id}"
    case TrustScoreETS.get_store(ets_key) do
      nil ->
        case Repo.get_by(StoreTrustScore, store_id: store_id) do
          nil -> nil
          ts  ->
            data = store_ets_data(ets_key, ts)
            TrustScoreETS.put_store(ets_key, data)
            data
        end
      cached -> cached
    end
  end

  @doc """
  Recalculate personal trust score dari raw counters di DB.
  Update record, invalidate ETS.
  Return: {:ok, %UserTrustScore{}} | {:error, reason}
  """
  def recalculate_user(user_id) do
    with ts   when not is_nil(ts) <- Repo.get_by(UserTrustScore, user_id: user_id),
         user when not is_nil(user) <- Repo.get(User, user_id) do
      today    = Date.utc_today()
      is_cold  = check_user_cold_start(ts, today)
      months   = months_active(NaiveDateTime.to_date(user.inserted_at), today)

      payment  = safe_div(ts.on_time_count, ts.on_time_count + ts.late_count)
      cancel   = safe_div(ts.cancel_count, ts.total_order_count)
      dispute  = safe_div(ts.dispute_lost, max(ts.dispute_raised, 1))
      longevity_val = min(months / 24.0, 1.0)

      score =
        (payment * 0.40 +
         (1 - cancel) * 0.25 +
         (1 - dispute) * 0.20 +
         longevity_val * 0.15)
        |> Kernel.*(1000)
        |> round()
        |> clamp(0, 1000)

      tier = tier_for_score(score)

      attrs = %{
        score:                score,
        tier:                 tier,
        is_cold_start:        is_cold,
        payment_on_time_rate: Decimal.from_float(payment),
        cancellation_rate:    Decimal.from_float(cancel),
        dispute_ratio:        Decimal.from_float(dispute),
        longevity:            Decimal.from_float(longevity_val),
        last_recalculated_at: DateTime.utc_now() |> DateTime.truncate(:second)
      }

      case ts |> UserTrustScore.changeset(attrs) |> Repo.update() do
        {:ok, updated} ->
          # Invalidate ETS — next get akan fallback ke DB yang baru
          TrustScoreETS.delete_user("u##{user_id}")
          {:ok, updated}

        error -> error
      end
    else
      nil -> {:error, :not_found}
    end
  end

  @doc """
  Recalculate store trust score dari raw counters di DB.
  Handle cold start weighting. Update record, invalidate ETS.
  Return: {:ok, %StoreTrustScore{}} | {:error, reason}
  """
  def recalculate_store(store_id) do
    with ts    when not is_nil(ts) <- Repo.get_by(StoreTrustScore, store_id: store_id),
         store when not is_nil(store) <- Repo.get(Store, store_id) do
      today   = Date.utc_today()
      is_cold = check_store_cold_start(ts, today)
      months  = months_active(NaiveDateTime.to_date(store.inserted_at), today)

      pay_rel    = safe_div(ts.on_time_count, ts.on_time_count + ts.late_count)
      fulfill    = safe_div(ts.completed_count, ts.completed_count + ts.cancelled_count)
      repeat_b   = safe_div(ts.repeat_buyer_count, max(ts.total_unique_buyers, 1))
      dispute    = safe_div(ts.dispute_lost, max(ts.dispute_raised, 1))
      network    = min(ts.unique_partners / 10.0, 1.0)
      longevity_val = min(months / 24.0, 1.0)
      growth     = if ts.growth_trend, do: Decimal.to_float(ts.growth_trend), else: 0.0

      score =
        if is_cold do
          (pay_rel * 0.30 +
           fulfill  * 0.25 +
           repeat_b * 0.20 +
           (1 - dispute) * 0.15 +
           network  * 0.10)
        else
          (pay_rel  * 0.25 +
           fulfill  * 0.20 +
           repeat_b * 0.20 +
           (1 - dispute) * 0.15 +
           network  * 0.10 +
           longevity_val * 0.07 +
           growth   * 0.03)
        end
        |> Kernel.*(1000)
        |> round()
        |> clamp(0, 1000)

      tier = tier_for_score(score)

      attrs = %{
        score:               score,
        tier:                tier,
        is_cold_start:       is_cold,
        payment_reliability: Decimal.from_float(pay_rel),
        fulfillment_rate:    Decimal.from_float(fulfill),
        repeat_buyer_rate:   Decimal.from_float(repeat_b),
        dispute_ratio:       Decimal.from_float(dispute),
        network_breadth:     Decimal.from_float(network),
        longevity:           Decimal.from_float(longevity_val),
        last_recalculated_at: DateTime.utc_now() |> DateTime.truncate(:second)
      }

      case ts |> StoreTrustScore.changeset(attrs) |> Repo.update() do
        {:ok, updated} ->
          TrustScoreETS.delete_store("s@#{store_id}")
          {:ok, updated}

        error -> error
      end
    else
      nil -> {:error, :not_found}
    end
  end

  # ---- Private ----

  defp safe_div(_, 0), do: 0.0
  defp safe_div(num, den), do: num / den

  defp clamp(val, min_val, max_val), do: val |> max(min_val) |> min(max_val)

  defp months_active(from_date, to_date) do
    (to_date.year - from_date.year) * 12 + (to_date.month - from_date.month)
    |> max(0)
  end

  # Cold start berakhir jika cold_start_ends_at sudah lewat
  defp check_user_cold_start(ts, today) do
    ts.is_cold_start and Date.compare(ts.cold_start_ends_at, today) == :gt
  end

  defp check_store_cold_start(ts, today) do
    ts.is_cold_start and Date.compare(ts.cold_start_ends_at, today) == :gt
  end

  defp user_ets_data(ets_key, ts) do
    %{
      user_id:    ets_key,
      score:      ts.score,
      tier:       String.to_atom(ts.tier),
      updated_at: DateTime.utc_now()
    }
  end

  defp store_ets_data(ets_key, ts) do
    %{
      store_id:   ets_key,
      score:      ts.score,
      tier:       String.to_atom(ts.tier),
      capacity:   capacity_for_tier(ts.tier),
      updated_at: DateTime.utc_now()
    }
  end
end
