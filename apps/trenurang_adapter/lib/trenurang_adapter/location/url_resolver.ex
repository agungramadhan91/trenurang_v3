defmodule TrenurangAdapter.Location.UrlResolver do
  @moduledoc """
  Resolve Google Maps short URLs ke koordinat.

  Short URLs (goo.gl/maps, maps.app.goo.gl) tidak mengandung koordinat —
  harus di-resolve via HTTP redirect ke long URL, baru di-parse.

  Flow:
    short URL → follow redirect → long URL → Parser.parse/1 → {:ok, %{lat, lng}}
  """

  alias TrenurangCore.Location.Parser

  @finch_name TrenurangAdapter.Finch
  @max_redirects 5
  @timeout_ms 5_000

  @short_url_hosts ["goo.gl", "maps.app.goo.gl"]

  @doc """
  Cek apakah URL adalah short URL yang perlu di-resolve.
  """
  @spec short_url?(String.t()) :: boolean()
  def short_url?(url) when is_binary(url) do
    Enum.any?(@short_url_hosts, &String.contains?(url, &1))
  end

  def short_url?(_), do: false

  @doc """
  Resolve short URL ke koordinat via HTTP redirect.
  Returns {:ok, %{lat, lng}} atau {:error, reason}
  """
  @spec resolve(String.t()) :: {:ok, %{lat: float(), lng: float()}} | {:error, atom()}
  def resolve(url) when is_binary(url) do
    case follow_redirects(url, @max_redirects) do
      {:ok, final_url} -> Parser.parse(final_url)
      {:error, reason} -> {:error, reason}
    end
  end

  # --- Private ---

  defp follow_redirects(_url, 0), do: {:error, :too_many_redirects}

  defp follow_redirects(url, remaining) do
    request = Finch.build(:head, url)

    case Finch.request(request, @finch_name, receive_timeout: @timeout_ms) do
      {:ok, %Finch.Response{status: status, headers: headers}}
      when status in [301, 302, 303, 307, 308] ->
        case get_location(headers) do
          nil -> {:error, :redirect_no_location}
          location -> follow_redirects(location, remaining - 1)
        end

      {:ok, %Finch.Response{status: 200}} ->
        {:ok, url}

      {:ok, %Finch.Response{status: status}} ->
        {:error, {:http_unexpected_status, status}}

      {:error, %{reason: reason}} ->
        {:error, {:http_error, reason}}

      {:error, reason} ->
        {:error, {:http_error, reason}}
    end
  end

  defp get_location(headers) do
    case List.keyfind(headers, "location", 0) do
      {_, location} -> location
      nil -> nil
    end
  end
end
