defmodule TrenurangAdapter.Handlers.DisputeHandler do
  @moduledoc "Handler untuk /dispute — Fase 6."
  def handle(_session, _chat_id), do: {:ok, :dispute}
  def handle(_action, _session, _chat_id), do: {:ok, :dispute}
end
