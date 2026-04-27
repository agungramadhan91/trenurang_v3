defmodule TrenurangAdapter.Handlers.StartHandler do
  @moduledoc "Handler untuk /start, /help, /about."

  alias TrenurangAdapter.ResponseFormatter
  alias TrenurangAdapter.Telegram.Sender
  alias TrenurangCore.Locale

  def handle(%{is_registered: true} = session, chat_id) do
    TrenurangAdapter.Handlers.HomeHandler.handle(session, chat_id)
  end

  def handle(session, chat_id) do
    lang = Map.get(session, :lang, :id)

    case session.active_flow do
      %{flow: :register} ->
        text = Locale.t(:register_interrupted, lang)
        buttons = [
          ResponseFormatter.row([
            {Locale.t(:register_btn_resume, lang), "register/resume"},
            {Locale.t(:register_btn_restart, lang), "register/restart"}
          ])
        ]
        Sender.send(ResponseFormatter.text_with_keyboard(chat_id, text, buttons))

      _ ->
        text = Locale.t(:start_welcome_new, lang)
        buttons = [
          ResponseFormatter.row([
            {Locale.t(:start_btn_register, lang), "register"},
            {Locale.t(:start_btn_explore, lang), "market/browse"}
          ]),
          ResponseFormatter.row([
            {Locale.t(:start_btn_about, lang), "about"}
          ])
        ]
        Sender.send(ResponseFormatter.text_with_keyboard(chat_id, text, buttons))
    end
  end

  def handle_help(session, chat_id) do
    handle(session, chat_id)
  end

  def handle_about(session, chat_id) do
    lang = Map.get(session, :lang, :id)
    Sender.send(ResponseFormatter.text(chat_id, Locale.t(:about_text, lang)))
  end
end
