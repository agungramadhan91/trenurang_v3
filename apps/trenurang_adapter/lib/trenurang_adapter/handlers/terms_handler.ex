defmodule TrenurangAdapter.Handlers.TermsHandler do
  @moduledoc "Handler untuk /terms — Fase 6."
  def handle(_session, _chat_id), do: {:ok, :terms}
  def handle(_action, _session, _chat_id), do: {:ok, :terms}
end
