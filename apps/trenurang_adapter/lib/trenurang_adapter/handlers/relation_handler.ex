defmodule TrenurangAdapter.Handlers.RelationHandler do
  @moduledoc "Handler untuk /relation — Fase 6."
  def handle(_session, _chat_id), do: {:ok, :relation}
  def handle(_action, _session, _chat_id), do: {:ok, :relation}
end
