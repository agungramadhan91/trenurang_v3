defmodule TrenurangAdapter.TranscriptLogger do
  @moduledoc """
  Logger khusus transkrip teks user — input & output yang user lihat.

  Catat semua aksi user (text biasa + callback button) dan respons bot
  (text + label tombol) dengan format konsisten agar mudah dibaca saat
  development.

  Berbeda dari Logger pipeline ([RECEIVER], [PIPELINE], [FLOW], [DISPATCH])
  yang fokus ke alur internal — modul ini fokus ke "apa yang user lihat".

  Format:
    [IN  → 123456789] /start
    [OUT ← 123456789] Selamat datang di Trenurang...
    [OUT ← 123456789] [🚀 Daftar] [🔍 Jelajah] [🌐 Atur Bahasa]
  """

  require Logger

  @doc """
  Log input dari user.

  `text` adalah hasil `extract/1` di UpdateHandler — bisa berupa:
    - text message biasa (e.g. "Ahmad", "/start")
    - callback button data (e.g. "register/resume")
    - lokasi GPS sebagai string "lat,lng"
  """
  @spec log_in(integer() | String.t(), String.t()) :: :ok
  def log_in(chat_id, text) when is_binary(text) do
    Logger.info("[IN  → #{chat_id}] #{text}")
    :ok
  end

  @doc """
  Log output bot ke user — teks pesan plus label tombol jika ada.

  `opts` adalah keyword list dari ResponseFormatter. Jika berisi
  `:reply_markup` (JSON-encoded inline keyboard), label tombol dilog
  di baris terpisah per row.
  """
  @spec log_out(integer() | String.t(), String.t(), keyword()) :: :ok
  def log_out(chat_id, text, opts \\ []) when is_binary(text) do
    Logger.info("[OUT ← #{chat_id}] #{text}")

    case Keyword.get(opts, :reply_markup) do
      nil -> :ok
      json when is_binary(json) -> log_buttons(chat_id, json)
      _ -> :ok
    end

    :ok
  end

  # ---- Private ----

  defp log_buttons(chat_id, json) do
    case Jason.decode(json) do
      {:ok, %{"inline_keyboard" => rows}} when is_list(rows) ->
        Enum.each(rows, fn row ->
          labels =
            row
            |> Enum.map(fn
              %{"text" => label} -> "[#{label}]"
              _ -> nil
            end)
            |> Enum.reject(&is_nil/1)
            |> Enum.join(" ")

          if labels != "", do: Logger.info("[OUT ← #{chat_id}] #{labels}")
        end)

      _ ->
        :ok
    end
  end
end
