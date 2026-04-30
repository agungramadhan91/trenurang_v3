defmodule TrenurangAdapter.Handlers.MarketHandler do
  @moduledoc "Handler untuk /market — stub MVP 1, kirim 'segera hadir'."

  alias TrenurangAdapter.ResponseFormatter
  alias TrenurangAdapter.Telegram.Sender
  alias TrenurangCore.Locale

  def handle(_session, _chat_id), do: {:ok, :market}

  def handle(_action, session, chat_id) do
    lang = Map.get(session, :lang, :id)
    Sender.send(ResponseFormatter.text(chat_id, Locale.t(:common_coming_soon, lang)))
    {:ok, :coming_soon}
  end
end
