defmodule TrenurangAdapter.Handlers.ChatHandler do
  @moduledoc "Handler untuk /chat — Fase 6."
  def handle(_session, _chat_id), do: {:ok, :chat}
  def handle(_action, _session, _chat_id), do: {:ok, :chat}
end
