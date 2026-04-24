defmodule TrenurangAdapter.Handlers.ProfileHandler do
  @moduledoc "Handler untuk /profile — Fase 6."
  def handle(_session, _chat_id), do: {:ok, :profile}
  def handle(_action, _session, _chat_id), do: {:ok, :profile}
end
