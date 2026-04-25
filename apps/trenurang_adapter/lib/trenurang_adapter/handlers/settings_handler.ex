defmodule TrenurangAdapter.Handlers.SettingsHandler do
  @moduledoc "Handler untuk /settings — Fase 6."
  def handle(_session, _chat_id), do: {:ok, :settings}
  def handle(_action, _session, _chat_id), do: {:ok, :settings}
end
