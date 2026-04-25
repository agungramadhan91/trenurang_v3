defmodule TrenurangAdapter.Handlers.RegisterHandler do
  @moduledoc "Handler untuk /register — Fase 6."
  def handle(_session, _chat_id), do: {:ok, :register}
  def handle(_action, _session, _chat_id), do: {:ok, :register}
end
