defmodule TrenurangAdapter.Handlers.StartHandler do
  @moduledoc "Handler untuk /start dan /help — Fase 6."
  def handle(_session, _chat_id), do: {:ok, :start}
  def handle_help(_session, _chat_id), do: {:ok, :help}
end
