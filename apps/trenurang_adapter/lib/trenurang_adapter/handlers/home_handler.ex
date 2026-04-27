defmodule TrenurangAdapter.Handlers.HomeHandler do
  @moduledoc "Handler untuk /home — buyer view dan seller view."

  alias TrenurangAdapter.ResponseFormatter
  alias TrenurangAdapter.Telegram.Sender
  alias TrenurangCore.Locale

  def handle(%{is_registered: false} = session, chat_id) do
    TrenurangAdapter.Handlers.StartHandler.handle(session, chat_id)
  end

  def handle(%{has_store: true} = session, chat_id) do
    lang = Map.get(session, :lang, :id)
    name = session[:username] || Locale.t(:common_done, lang)
    store_name = get_store_name(session)

    text = Locale.t(:home_seller, lang, %{name: name, store_name: store_name})
    buttons = [
      ResponseFormatter.row([
        {Locale.t(:home_btn_store, lang), "store/list"},
        {Locale.t(:home_btn_orders, lang), "order/list"}
      ]),
      ResponseFormatter.row([
        {Locale.t(:home_btn_market, lang), "market/browse"},
        {Locale.t(:home_btn_profile, lang), "profile/show"}
      ])
    ]
    Sender.send(ResponseFormatter.text_with_keyboard(chat_id, text, buttons))
  end

  def handle(session, chat_id) do
    lang = Map.get(session, :lang, :id)
    name = session[:username] || ""

    text = Locale.t(:home_buyer, lang, %{name: name})
    buttons = [
      ResponseFormatter.row([
        {Locale.t(:home_btn_market, lang), "market/browse"},
        {Locale.t(:home_btn_orders, lang), "order/list"}
      ]),
      ResponseFormatter.row([
        {Locale.t(:home_btn_profile, lang), "profile/show"}
      ])
    ]
    Sender.send(ResponseFormatter.text_with_keyboard(chat_id, text, buttons))
  end

  defp get_store_name(%{stores: [%{name: name} | _]}), do: name
  defp get_store_name(_), do: "Toko Kamu"
end
