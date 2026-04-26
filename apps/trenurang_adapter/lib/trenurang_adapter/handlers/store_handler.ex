defmodule TrenurangAdapter.Handlers.StoreHandler do
  @moduledoc "Handler untuk /store — Fase 6."

  def handle(:walkin_generate, _session, _chat_id), do: {:ok, :store_walkin_generate}
  def handle(:walkin_record, _session, _chat_id),   do: {:ok, :store_walkin_record}
  def handle(_action, _session, _chat_id),          do: {:ok, :store}
  def handle(_session, _chat_id),                   do: {:ok, :store}
end
