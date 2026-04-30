defmodule TrenurangAdapter.Handlers.OrderHandler do
  @moduledoc "Handler untuk order flow — stub MVP 1 (slice-1: :list dapat 'segera hadir', sisanya stub untuk slice depan)."

  alias TrenurangAdapter.ResponseFormatter
  alias TrenurangAdapter.Telegram.Sender
  alias TrenurangCore.Locale

  def handle(:list, session, chat_id) do
    lang = Map.get(session, :lang, :id)
    Sender.send(ResponseFormatter.text(chat_id, Locale.t(:common_coming_soon, lang)))
    {:ok, :coming_soon}
  end

  def handle(:create, _session, _chat_id),         do: {:ok, :order_create}
  def handle(:status, _session, _chat_id),         do: {:ok, :order_status}
  def handle(:confirm_price, _session, _chat_id),  do: {:ok, :order_confirm_price}
  def handle(:cancel, _session, _chat_id),         do: {:ok, :order_cancel}
end
