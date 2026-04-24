defmodule TrenurangAdapter.Handlers.StoreHandler do
  @moduledoc "Handler untuk /store — Fase 6."
  def handle(_session, _chat_id), do: {:ok, :store}
  def handle(_action, _session, _chat_id), do: {:ok, :store}
end
