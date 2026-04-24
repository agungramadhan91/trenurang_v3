defmodule TrenurangAdapter.ResponseFormatter do
  @moduledoc """
  Format response sebelum dikirim ke Telegram.

  Output selalu berupa tuple yang dikonsumsi Sender:
    {:text, chat_id, text, opts}

  Keyboard menggunakan InlineKeyboardMarkup Telegram.
  Parse mode default: nil (plain text) — handler bisa override ke "HTML" atau "Markdown".
  """

  @doc "Format pesan teks biasa."
  @spec text(integer(), String.t()) :: {:text, integer(), String.t(), keyword()}
  def text(chat_id, content) do
    {:text, chat_id, content, []}
  end

  @doc "Format pesan teks dengan inline keyboard."
  @spec text_with_keyboard(integer(), String.t(), list(list(map()))) ::
          {:text, integer(), String.t(), keyword()}
  def text_with_keyboard(chat_id, content, button_rows) do
    keyboard = %{
      inline_keyboard: button_rows
    }
    {:text, chat_id, content, reply_markup: Jason.encode!(keyboard)}
  end

  @doc """
  Buat satu baris button.

  Contoh:
    row([{"✅ Konfirmasi", "confirm"}, {"❌ Batal", "cancel"}])
  """
  @spec row(list({String.t(), String.t()})) :: list(map())
  def row(buttons) do
    Enum.map(buttons, fn {label, data} ->
      %{text: label, callback_data: data}
    end)
  end
end
