defmodule TrenurangAdapter.Telegram.Sender do
  @moduledoc """
  Kirim response ke Telegram via Telegex.

  Menerima tuple dari ResponseFormatter dan mengeksekusi API call.
  Error dari Telegex di-log tapi tidak crash pipeline.
  """

  require Logger

  @doc "Kirim hasil format dari ResponseFormatter."
  @spec send({:text, integer(), String.t(), keyword()}) :: :ok
  def send({:text, chat_id, text, opts}) do
    send_text(chat_id, text, opts)
  end

  @doc "Kirim pesan teks langsung (bypass formatter)."
  @spec send_text(integer(), String.t(), keyword()) :: :ok
  def send_text(chat_id, text, opts \\ []) do
    case Telegex.send_message(chat_id, text, opts) do
      {:ok, _msg} ->
        :ok

      {:error, reason} ->
        Logger.warning("[Sender] Gagal kirim ke chat_id=#{chat_id}: #{inspect(reason)}")
        :ok
    end
  end
end
