defmodule TrenurangCore.Session.ETSServer do
  @moduledoc """
  GenServer owner untuk semua ETS tables session dan trust score cache.

  Tables yang dikelola:
    - :trenurang_sessions
    - :trenurang_user_trust_scores
    - :trenurang_store_trust_scores
  """

  use GenServer

  @tables [
    :trenurang_sessions,
    :trenurang_user_trust_scores,
    :trenurang_store_trust_scores
  ]

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    Enum.each(@tables, fn table ->
      :ets.new(table, [:set, :public, :named_table, read_concurrency: true, write_concurrency: true])
    end)

    {:ok, %{}}
  end
end
