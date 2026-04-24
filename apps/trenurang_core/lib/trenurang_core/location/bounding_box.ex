defmodule TrenurangCore.Location.BoundingBox do
  @moduledoc """
  Validasi koordinat geografis berdasarkan batas wilayah.
  """

  # Batas geografis Indonesia (approx)
  @indonesia_lat_min -11.0
  @indonesia_lat_max 6.0
  @indonesia_lng_min 95.0
  @indonesia_lng_max 141.0

  @doc """
  Cek apakah koordinat berada dalam batas wilayah Indonesia.
  """
  @spec indonesia?(float(), float()) :: boolean()
  def indonesia?(lat, lng)
      when is_number(lat) and is_number(lng) do
    lat >= @indonesia_lat_min and lat <= @indonesia_lat_max and
      lng >= @indonesia_lng_min and lng <= @indonesia_lng_max
  end

  def indonesia?(_, _), do: false
end
