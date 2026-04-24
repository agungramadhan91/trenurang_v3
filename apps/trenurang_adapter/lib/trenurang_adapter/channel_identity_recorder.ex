defmodule TrenurangAdapter.ChannelIdentityRecorder do
  @moduledoc """
  Rekam setiap pesan masuk ke channel_identities.

  Dipanggil sebagai langkah PERTAMA di pipeline — sebelum normalizer,
  sebelum session hydrator. Setiap pesan tanpa kecuali harus ter-record.

  Tidak pernah crash pipeline — error di-log, proses tetap lanjut.
  """

  require Logger
  alias TrenurangCore.Context.Accounts

  @channel "telegram"

  @doc """
  Upsert channel_identity untuk pesan masuk.

  Selalu return :ok agar pipeline tidak terganggu walau DB error.
  """
  @spec record(String.t()) :: :ok
  def record(channel_id) when is_binary(channel_id) do
    case Accounts.upsert_channel_identity(@channel, channel_id) do
      {:ok, _ci} ->
        :ok

      {:error, reason} ->
        Logger.warning("[ChannelIdentityRecorder] Gagal upsert channel_id=#{channel_id}: #{inspect(reason)}")
        :ok
    end
  end

  @doc """
  Ambil channel_identity record untuk channel_id ini (untuk link ke user setelah registrasi).
  """
  @spec get_identity(String.t()) :: {:ok, map()} | {:error, :not_found}
  def get_identity(channel_id) when is_binary(channel_id) do
    case Accounts.upsert_channel_identity(@channel, channel_id) do
      {:ok, ci} -> {:ok, ci}
      {:error, _} -> {:error, :not_found}
    end
  end
end
