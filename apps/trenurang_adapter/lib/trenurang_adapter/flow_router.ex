defmodule TrenurangAdapter.FlowRouter do
  @moduledoc """
  Routing berdasarkan state active_flow di session.

  Dua jalur:
    1. Ada active_flow → cek apakah input adalah step/button atau free text
    2. Tidak ada active_flow → teruskan ke CommandRouter

  Untuk free text di tengah active_flow:
    → kirim ke Intelligence untuk klasifikasi
    → {:command, route} = interrupt (tampilkan konfirmasi)
    → {:answer, reply}  = jawab langsung, flow tetap berjalan
    → {:fallback, _}    = teruskan ke flow handler seolah input biasa
  """

  @doc """
  Route input berdasarkan session state.

  Return values:
    {:command, normalized_input}           — tidak ada active_flow, dispatch ke CommandRouter
    {:flow_step, flow, normalized_input}   — ada active_flow, input adalah step/button
    {:flow_free_text, flow, text}          — ada active_flow, input adalah free text
  """
  @spec route(map(), String.t()) ::
          {:command, String.t()}
          | {:flow_step, map(), String.t()}
          | {:flow_free_text, map(), String.t()}
  def route(%{active_flow: nil}, normalized_input) do
    {:command, normalized_input}
  end

  def route(%{active_flow: flow}, normalized_input) do
    if free_text?(normalized_input) do
      {:flow_free_text, flow, normalized_input}
    else
      {:flow_step, flow, normalized_input}
    end
  end

  # Fallback jika session tidak punya key active_flow
  def route(_session, normalized_input) do
    {:command, normalized_input}
  end

  # Input dianggap free text jika:
  # - lebih dari satu kata, ATAU
  # - tidak match format command/route (tidak ada "/" dan bukan satu kata pendek)
  defp free_text?(input) do
    words = String.split(input, " ", trim: true)
    length(words) > 1 or String.length(input) > 20
  end
end
