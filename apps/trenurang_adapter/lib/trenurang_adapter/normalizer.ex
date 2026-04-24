defmodule TrenurangAdapter.Normalizer do
  @moduledoc """
  Normalisasi input sebelum diproses pipeline.

  Proses: strip `/` → trim → lowercase → resolve alias.
  Murni fungsi — tidak ada side effect, tidak ada DB call.
  """

  @alias_map %{
    "halo"  => "start",
    "hai"   => "start",
    "hello" => "start",
    "hi"    => "start",
    "mulai" => "start",
    "menu"  => "home"
  }

  @doc """
  Normalisasi satu input string.

      iex> TrenurangAdapter.Normalizer.normalize("/Start")
      "start"

      iex> TrenurangAdapter.Normalizer.normalize("halo")
      "start"

      iex> TrenurangAdapter.Normalizer.normalize("  /MARKET/browse  ")
      "market/browse"
  """
  @spec normalize(String.t()) :: String.t()
  def normalize(input) when is_binary(input) do
    input
    |> String.trim()
    |> String.trim_leading("/")
    |> String.downcase()
    |> resolve_alias()
  end

  def normalize(_), do: ""

  @doc "Kembalikan alias map (untuk testing dan introspection)."
  @spec alias_map() :: map()
  def alias_map, do: @alias_map

  defp resolve_alias(text), do: Map.get(@alias_map, text, text)
end
