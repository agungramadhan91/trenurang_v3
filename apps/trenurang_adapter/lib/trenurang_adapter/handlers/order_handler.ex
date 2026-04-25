defmodule TrenurangAdapter.Handlers.OrderHandler do
  @moduledoc "Handler untuk order flow — Fase 6."

  def handle(:list, _session, _chat_id),           do: {:ok, :order_list}
  def handle(:create, _session, _chat_id),         do: {:ok, :order_create}
  def handle(:status, _session, _chat_id),         do: {:ok, :order_status}
  def handle(:confirm_price, _session, _chat_id),  do: {:ok, :order_confirm_price}
  def handle(:cancel, _session, _chat_id),         do: {:ok, :order_cancel}
end
