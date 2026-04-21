defmodule TrenurangCore.TrustScore.ETSTest do
  use ExUnit.Case, async: false

  alias TrenurangCore.TrustScore.ETS, as: TrustScoreETS

  @tag :unit

  setup do
    :ets.delete_all_objects(:trenurang_user_trust_scores)
    :ets.delete_all_objects(:trenurang_store_trust_scores)
    :ok
  end

  defp user_score(user_id) do
    %{
      user_id:    user_id,
      score:      480,
      tier:       :pemula_aktif,
      updated_at: DateTime.utc_now()
    }
  end

  defp store_score(store_id) do
    %{
      store_id:   store_id,
      score:      412,
      tier:       :pemula_aktif,
      capacity:   75,
      updated_at: DateTime.utc_now()
    }
  end

  # User Trust Score
  test "put dan get user trust score" do
    data = user_score("u#5")
    TrustScoreETS.put_user("u#5", data)
    assert TrustScoreETS.get_user("u#5") == data
  end

  test "get user trust score yang tidak ada mengembalikan nil" do
    assert TrustScoreETS.get_user("u#999") == nil
  end

  test "delete user trust score" do
    TrustScoreETS.put_user("u#5", user_score("u#5"))
    TrustScoreETS.delete_user("u#5")
    assert TrustScoreETS.get_user("u#5") == nil
  end

  test "invalidate user trust score (delete) saat recalculate" do
    TrustScoreETS.put_user("u#5", user_score("u#5"))
    # Simulasi invalidate sebelum recalculate
    TrustScoreETS.delete_user("u#5")
    assert TrustScoreETS.get_user("u#5") == nil
    # Populate ulang dengan score baru
    new_data = %{user_score("u#5") | score: 550, tier: :pedagang_tumbuh}
    TrustScoreETS.put_user("u#5", new_data)
    assert TrustScoreETS.get_user("u#5").score == 550
  end

  # Store Trust Score
  test "put dan get store trust score" do
    data = store_score("s@5")
    TrustScoreETS.put_store("s@5", data)
    assert TrustScoreETS.get_store("s@5") == data
  end

  test "get store trust score yang tidak ada mengembalikan nil" do
    assert TrustScoreETS.get_store("s@999") == nil
  end

  test "delete store trust score" do
    TrustScoreETS.put_store("s@5", store_score("s@5"))
    TrustScoreETS.delete_store("s@5")
    assert TrustScoreETS.get_store("s@5") == nil
  end

  test "store trust score menyimpan capacity sesuai tier" do
    TrustScoreETS.put_store("s@5", store_score("s@5"))
    assert TrustScoreETS.get_store("s@5").capacity == 75
  end

  test "invalidate store trust score (delete) saat recalculate" do
    TrustScoreETS.put_store("s@5", store_score("s@5"))
    TrustScoreETS.delete_store("s@5")
    assert TrustScoreETS.get_store("s@5") == nil
    new_data = %{store_score("s@5") | score: 550, tier: :pedagang_andal, capacity: 150}
    TrustScoreETS.put_store("s@5", new_data)
    assert TrustScoreETS.get_store("s@5").capacity == 150
  end
end
