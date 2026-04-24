defmodule TrenurangAdapter.Handlers.HomeHandler do
  @moduledoc "Handler untuk home — Fase 6."
  def handle(_session, _chat_id), do: {:ok, :home}
  def handle(_action, _session, _chat_id), do: {:ok, :home}
end
