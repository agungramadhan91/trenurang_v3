defmodule TrenurangCore.Location.Parser do
  @moduledoc """
  Parse berbagai format input lokasi ke koordinat standar.

  Format yang didukung:
  - Map Telegram GPS: %{"latitude" => lat, "longitude" => lng}
  - String koordinat desimal: "-6.175, 106.827"
  - Google Maps URL (long form, mengandung @lat,lng)
  - Nama kota (Jakarta & Jawa Barat) via CityLookup

  Returns {:ok, %{lat: float, lng: float}} atau {:error, atom}
  """

  alias TrenurangCore.Location.{BoundingBox, CityLookup}

  @type result :: {:ok, %{lat: float(), lng: float()}} | {:error, atom()}

  @doc """
  Parse input lokasi ke koordinat standar.
  """
  @spec parse(any()) :: result()

  # Telegram GPS — atom keys
  def parse(%{latitude: lat, longitude: lng}) do
    validate({lat, lng})
  end

  # Telegram GPS — string keys
  def parse(%{"latitude" => lat, "longitude" => lng}) do
    validate({lat, lng})
  end

  # String input
  def parse(input) when is_binary(input) do
    input = String.trim(input)

    cond do
      google_maps_url?(input) -> parse_google_maps_url(input)
      coordinate_string?(input) -> parse_coordinate_string(input)
      true -> parse_city_name(input)
    end
  end

  def parse(_), do: {:error, :unsupported_format}

  # --- Private ---

  defp validate({lat, lng}) when is_number(lat) and is_number(lng) do
    lat = lat / 1
    lng = lng / 1

    cond do
      not BoundingBox.indonesia?(lat, lng) -> {:error, :outside_indonesia}
      true -> {:ok, %{lat: lat, lng: lng}}
    end
  end

  defp validate(_), do: {:error, :invalid_coordinates}

  defp google_maps_url?(input) do
    String.contains?(input, "google.com/maps") or
      String.contains?(input, "maps.google.com") or
      String.contains?(input, "maps.app.goo.gl") or
      String.contains?(input, "goo.gl/maps")
  end

  # Parse Google Maps long URL — cari @lat,lng pattern
  defp parse_google_maps_url(url) do
    case Regex.run(~r/@(-?\d+\.?\d*),(-?\d+\.?\d*)/, url) do
      [_, lat_str, lng_str] ->
        parse_lat_lng_strings(lat_str, lng_str)

      nil ->
        # Coba format ?q=lat,lng
        case Regex.run(~r/[?&]q=(-?\d+\.?\d*),(-?\d+\.?\d*)/, url) do
          [_, lat_str, lng_str] -> parse_lat_lng_strings(lat_str, lng_str)
          nil -> {:error, :url_parse_failed}
        end
    end
  end

  defp coordinate_string?(input) do
    Regex.match?(~r/^-?\d+\.?\d*\s*[,\s]\s*-?\d+\.?\d*$/, input)
  end

  # Parse "lat, lng" atau "lat lng"
  defp parse_coordinate_string(input) do
    parts =
      input
      |> String.replace(",", " ")
      |> String.split()
      |> Enum.filter(&(String.length(&1) > 0))

    case parts do
      [lat_str, lng_str] -> parse_lat_lng_strings(lat_str, lng_str)
      _ -> {:error, :invalid_coordinates}
    end
  end

  defp parse_lat_lng_strings(lat_str, lng_str) do
    with {lat, ""} <- Float.parse(lat_str),
         {lng, ""} <- Float.parse(lng_str) do
      validate({lat, lng})
    else
      _ -> {:error, :invalid_coordinates}
    end
  end

  defp parse_city_name(name) do
    case CityLookup.lookup(name) do
      {:ok, {lat, lng}} -> {:ok, %{lat: lat, lng: lng}}
      {:error, :not_found} -> {:error, :location_not_found}
    end
  end
end
