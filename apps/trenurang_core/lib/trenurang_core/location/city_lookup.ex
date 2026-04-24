defmodule TrenurangCore.Location.CityLookup do
  @moduledoc """
  Lookup koordinat dari nama kota/kecamatan.
  Coverage: DKI Jakarta + Jawa Barat.
  """

  @cities %{
    # DKI Jakarta
    "jakarta" => {-6.2088, 106.8456},
    "jakarta pusat" => {-6.1862, 106.8342},
    "jakarta utara" => {-6.1215, 106.9057},
    "jakarta barat" => {-6.1679, 106.7609},
    "jakarta selatan" => {-6.2615, 106.8106},
    "jakarta timur" => {-6.2250, 106.9004},
    "kepulauan seribu" => {-5.6110, 106.5711},
    # Kota & Kabupaten Jawa Barat
    "bandung" => {-6.9175, 107.6191},
    "kota bandung" => {-6.9175, 107.6191},
    "kabupaten bandung" => {-7.0051, 107.5608},
    "bandung barat" => {-6.8421, 107.4581},
    "bogor" => {-6.5971, 106.8060},
    "kota bogor" => {-6.5971, 106.8060},
    "kabupaten bogor" => {-6.5007, 106.8042},
    "depok" => {-6.4025, 106.7942},
    "bekasi" => {-6.2383, 106.9756},
    "kota bekasi" => {-6.2383, 106.9756},
    "kabupaten bekasi" => {-6.3044, 107.1696},
    "karawang" => {-6.3222, 107.3381},
    "purwakarta" => {-6.5567, 107.4394},
    "subang" => {-6.5756, 107.7617},
    "cirebon" => {-6.7320, 108.5523},
    "kota cirebon" => {-6.7320, 108.5523},
    "kabupaten cirebon" => {-6.7810, 108.4824},
    "indramayu" => {-6.3277, 108.3212},
    "majalengka" => {-6.8373, 108.2271},
    "kuningan" => {-6.9759, 108.4754},
    "garut" => {-7.2111, 107.9051},
    "tasikmalaya" => {-7.3274, 108.2207},
    "kota tasikmalaya" => {-7.3274, 108.2207},
    "ciamis" => {-7.3302, 108.3461},
    "pangandaran" => {-7.6885, 108.6504},
    "banjar" => {-7.3683, 108.5402},
    "sukabumi" => {-6.9211, 106.9277},
    "kota sukabumi" => {-6.9211, 106.9277},
    "kabupaten sukabumi" => {-6.9249, 106.5971},
    "cianjur" => {-6.8182, 107.1435},
    "sumedang" => {-6.8583, 107.9177},
    "tangerang" => {-6.1781, 106.6300},
    "kota tangerang" => {-6.1781, 106.6300},
    "tangerang selatan" => {-6.2890, 106.7111}
  }

  @doc """
  Lookup nama kota ke koordinat.
  Input diubah ke lowercase + trim sebelum dicek.
  Returns {:ok, {lat, lng}} atau {:error, :not_found}
  """
  @spec lookup(String.t()) :: {:ok, {float(), float()}} | {:error, :not_found}
  def lookup(city_name) when is_binary(city_name) do
    key = city_name |> String.downcase() |> String.trim()

    case Map.get(@cities, key) do
      nil -> {:error, :not_found}
      coords -> {:ok, coords}
    end
  end

  @doc """
  Daftar semua nama kota yang didukung.
  """
  @spec supported() :: [String.t()]
  def supported, do: Map.keys(@cities)
end
