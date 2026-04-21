defmodule TrenurangCore.Session.ETS do
  @moduledoc """
  CRUD operations untuk ETS table :trenurang_sessions.

  Key: user_id string (format "u#N")

  Session struct:
    %{
      user_id:         "u#2",
      username:        "@abc",
      lang:            :id,
      locations:       [],
      active_location: 0,
      route:           %{current: "/start", previous: nil},
      active_flow:     nil,
      is_registered:   false,
      is_buyer:        false,
      has_store:       false,
      has_relation:    false
    }
  """

  @table :trenurang_sessions

  @spec put(String.t(), map()) :: true
  def put(user_id, session) do
    :ets.insert(@table, {user_id, session})
  end

  @spec get(String.t()) :: map() | nil
  def get(user_id) do
    case :ets.lookup(@table, user_id) do
      [{^user_id, session}] -> session
      [] -> nil
    end
  end

  @spec delete(String.t()) :: true
  def delete(user_id) do
    :ets.delete(@table, user_id)
  end

  @spec update(String.t(), atom(), any()) :: :ok | {:error, :not_found}
  def update(user_id, key, value) do
    case get(user_id) do
      nil -> {:error, :not_found}
      session ->
        put(user_id, Map.put(session, key, value))
        :ok
    end
  end

  @spec count() :: non_neg_integer()
  def count do
    :ets.info(@table, :size)
  end
end
