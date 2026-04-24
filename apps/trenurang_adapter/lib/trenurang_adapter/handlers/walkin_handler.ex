defmodule TrenurangAdapter.Handlers.WalkinHandler do
  @moduledoc "Handler untuk /order/walkin — Fase 6."
  def handle(_session, _chat_id), do: {:ok, :walkin}
  def handle(_action, _session, _chat_id), do: {:ok, :walkin}
end
