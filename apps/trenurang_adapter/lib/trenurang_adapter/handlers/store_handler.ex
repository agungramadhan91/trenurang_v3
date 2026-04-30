defmodule TrenurangAdapter.Handlers.StoreHandler do
  @moduledoc "Handler untuk /store — stub MVP 1 (slice-1: :list dapat 'segera hadir', sisanya stub untuk slice depan)."

  alias TrenurangAdapter.ResponseFormatter
  alias TrenurangAdapter.Telegram.Sender
  alias TrenurangCore.Locale

  def handle(:list, session, chat_id) do
    lang = Map.get(session, :lang, :id)
    Sender.send(ResponseFormatter.text(chat_id, Locale.t(:common_coming_soon, lang)))
    {:ok, :coming_soon}
  end

  def handle(:walkin_generate, _session, _chat_id), do: {:ok, :store_walkin_generate}
  def handle(:walkin_record, _session, _chat_id),   do: {:ok, :store_walkin_record}
  def handle(_action, _session, _chat_id),          do: {:ok, :store}
  def handle(_session, _chat_id),                   do: {:ok, :store}
end
