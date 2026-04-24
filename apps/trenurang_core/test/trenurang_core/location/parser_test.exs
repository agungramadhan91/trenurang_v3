defmodule TrenurangCore.Location.ParserTest do
  use ExUnit.Case, async: true

  alias TrenurangCore.Location.Parser

  describe "parse/1 — Telegram GPS" do
    test "atom keys" do
      assert {:ok, %{lat: lat, lng: lng}} =
               Parser.parse(%{latitude: -6.2088, longitude: 106.8456})

      assert_in_delta lat, -6.2088, 0.0001
      assert_in_delta lng, 106.8456, 0.0001
    end

    test "string keys" do
      assert {:ok, %{lat: _, lng: _}} =
               Parser.parse(%{"latitude" => -6.2088, "longitude" => 106.8456})
    end

    test "koordinat di luar Indonesia ditolak" do
      assert {:error, :outside_indonesia} =
               Parser.parse(%{latitude: 48.8566, longitude: 2.3522})
    end
  end

  describe "parse/1 — string koordinat" do
    test "format lat, lng" do
      assert {:ok, %{lat: lat, lng: lng}} = Parser.parse("-6.175392, 106.827153")
      assert_in_delta lat, -6.175392, 0.0001
      assert_in_delta lng, 106.827153, 0.0001
    end

    test "format lat lng tanpa koma" do
      assert {:ok, %{lat: _, lng: _}} = Parser.parse("-6.175392 106.827153")
    end

    test "koordinat di luar Indonesia ditolak" do
      assert {:error, :outside_indonesia} = Parser.parse("48.8566, 2.3522")
    end
  end

  describe "parse/1 — Google Maps URL" do
    test "long URL dengan @lat,lng pattern" do
      url = "https://www.google.com/maps/place/Jakarta/@-6.2088,106.8456,12z"
      assert {:ok, %{lat: lat, lng: lng}} = Parser.parse(url)
      assert_in_delta lat, -6.2088, 0.0001
      assert_in_delta lng, 106.8456, 0.0001
    end

    test "URL dengan ?q=lat,lng" do
      url = "https://maps.google.com/?q=-6.9175,107.6191"
      assert {:ok, %{lat: lat, lng: lng}} = Parser.parse(url)
      assert_in_delta lat, -6.9175, 0.0001
      assert_in_delta lng, 107.6191, 0.0001
    end

    test "URL tidak valid gagal dengan error" do
      assert {:error, :url_parse_failed} =
               Parser.parse("https://www.google.com/maps/place/SomePlace")
    end
  end

  describe "parse/1 — nama kota" do
    test "nama kota dikenal" do
      assert {:ok, %{lat: _, lng: _}} = Parser.parse("Jakarta")
    end

    test "lowercase diterima" do
      assert {:ok, %{lat: _, lng: _}} = Parser.parse("bandung")
    end

    test "dengan spasi sebelum/sesudah" do
      assert {:ok, %{lat: _, lng: _}} = Parser.parse("  Bogor  ")
    end

    test "nama kota tidak dikenal" do
      assert {:error, :location_not_found} = Parser.parse("Atlantis")
    end
  end

  describe "parse/1 — format tidak didukung" do
    test "integer" do
      assert {:error, :unsupported_format} = Parser.parse(12345)
    end

    test "nil" do
      assert {:error, :unsupported_format} = Parser.parse(nil)
    end
  end

  describe "parse/1 — DMS coordinates" do
    test "format standar S/E" do
      assert {:ok, %{lat: lat, lng: lng}} =
               Parser.parse("6°10'32\"S 106°49'32\"E")

      assert_in_delta lat, -6.175, 0.01
      assert_in_delta lng, 106.825, 0.01
    end

    test "format dengan d/m/s" do
      assert {:ok, %{lat: lat, lng: lng}} =
               Parser.parse("6d10m32sS 106d49m32sE")

      assert_in_delta lat, -6.175, 0.01
      assert_in_delta lng, 106.825, 0.01
    end

    test "koordinat utara N" do
      # Sabang — paling utara Indonesia
      assert {:ok, %{lat: lat, lng: _}} =
               Parser.parse("5°53'0\"N 95°19'0\"E")

      assert lat > 0
    end

    test "koordinat di luar Indonesia ditolak" do
      assert {:error, :outside_indonesia} =
               Parser.parse("48°51'30\"N 2°21'8\"E")
    end
  end
end
