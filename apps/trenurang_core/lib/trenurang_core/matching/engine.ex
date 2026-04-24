defmodule TrenurangCore.Matching.Engine do
  @moduledoc """
  Rule-based supply-demand matching engine.

  Membaca persona tables (user_persona, store_persona), menghasilkan kandidat
  supply/demand berdasarkan kecocokan atribut ekonomi.

  **Status: DISABLED di MVP** — diaktifkan setelah massa kritis.

  Aturan keras:
  - Tidak boleh memanggil TrenurangIntelligence (murni rule-based query ke DB)
  - Semua keputusan matching berdasarkan data persona, bukan AI
  """

  @doc """
  Jalankan matching untuk user tertentu.

  Selalu return {:disabled} sampai diaktifkan via flag.
  """
  @spec run(user_id :: integer()) :: {:disabled} | {:ok, list()} | {:error, term()}
  def run(_user_id) do
    {:disabled}
  end

  @doc """
  Jalankan matching untuk store tertentu.

  Selalu return {:disabled} sampai diaktifkan via flag.
  """
  @spec run_for_store(store_id :: integer()) :: {:disabled} | {:ok, list()} | {:error, term()}
  def run_for_store(_store_id) do
    {:disabled}
  end
end
