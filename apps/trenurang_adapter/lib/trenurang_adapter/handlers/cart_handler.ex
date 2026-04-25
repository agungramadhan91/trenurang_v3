defmodule TrenurangAdapter.Handlers.CartHandler do
  @moduledoc "Handler untuk /cart — Fase 6."
  def handle(_session, _chat_id), do: {:ok, :cart}
  def handle(_action, _session, _chat_id), do: {:ok, :cart}
end
