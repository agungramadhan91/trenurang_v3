defmodule TrenurangCore.TrustScore.ETS do
  @moduledoc """
  CRUD operations untuk ETS cache trust score.

  Tables:
    - :trenurang_user_trust_scores  (key: user_id string "u#N")
    - :trenurang_store_trust_scores (key: store_id string "s@N")

  User trust score struct:
    %{user_id: "u#5", score: 480, tier: :pemula_aktif, updated_at: ~U[...]}

  Store trust score struct:
    %{store_id: "s@5", score: 412, tier: :pemula_aktif, capacity: 75, updated_at: ~U[...]}
  """

  @user_table  :trenurang_user_trust_scores
  @store_table :trenurang_store_trust_scores

  # --- User Trust Score ---

  @spec put_user(String.t(), map()) :: true
  def put_user(user_id, data) do
    :ets.insert(@user_table, {user_id, data})
  end

  @spec get_user(String.t()) :: map() | nil
  def get_user(user_id) do
    case :ets.lookup(@user_table, user_id) do
      [{^user_id, data}] -> data
      [] -> nil
    end
  end

  @spec delete_user(String.t()) :: true
  def delete_user(user_id) do
    :ets.delete(@user_table, user_id)
  end

  # --- Store Trust Score ---

  @spec put_store(String.t(), map()) :: true
  def put_store(store_id, data) do
    :ets.insert(@store_table, {store_id, data})
  end

  @spec get_store(String.t()) :: map() | nil
  def get_store(store_id) do
    case :ets.lookup(@store_table, store_id) do
      [{^store_id, data}] -> data
      [] -> nil
    end
  end

  @spec delete_store(String.t()) :: true
  def delete_store(store_id) do
    :ets.delete(@store_table, store_id)
  end
end
