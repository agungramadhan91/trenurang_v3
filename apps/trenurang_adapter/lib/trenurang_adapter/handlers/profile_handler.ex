defmodule TrenurangAdapter.Handlers.ProfileHandler do
  @moduledoc "Handler untuk /profile — stub MVP 1, kirim 'segera hadir'."

  alias TrenurangAdapter.ResponseFormatter
  alias TrenurangAdapter.Telegram.Sender
  alias TrenurangCore.Locale

  def handle(session, chat_id) do
    lang = Map.get(session, :lang, :id)
    Sender.send(ResponseFormatter.text(chat_id, Locale.t(:common_coming_soon, lang)))
    {:ok, :coming_soon}
  end

  def handle(_action, session, chat_id), do: handle(session, chat_id)
end
