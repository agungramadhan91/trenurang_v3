defmodule TrenurangAdapter.Handlers.MarketHandler do
  @moduledoc "Handler untuk /market — Fase 6."
  def handle(_session, _chat_id), do: {:ok, :market}
  def handle(_action, _session, _chat_id), do: {:ok, :market}
end
