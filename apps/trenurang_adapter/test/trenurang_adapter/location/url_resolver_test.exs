defmodule TrenurangAdapter.Location.UrlResolverTest do
  use ExUnit.Case, async: true

  alias TrenurangAdapter.Location.UrlResolver

  describe "short_url?/1" do
    test "goo.gl/maps adalah short URL" do
      assert UrlResolver.short_url?("https://goo.gl/maps/abc123")
    end

    test "maps.app.goo.gl adalah short URL" do
      assert UrlResolver.short_url?("https://maps.app.goo.gl/xyz")
    end

    test "google.com/maps bukan short URL" do
      refute UrlResolver.short_url?("https://www.google.com/maps/place/Jakarta/@-6.2088,106.8456,12z")
    end

    test "string random bukan short URL" do
      refute UrlResolver.short_url?("bandung")
    end

    test "non-string return false" do
      refute UrlResolver.short_url?(nil)
      refute UrlResolver.short_url?(123)
    end
  end

  describe "resolve/1 — network error handling" do
    test "URL tidak valid return http_error" do
      # URL tidak bisa dikoneksi — test error handling path
      result = UrlResolver.resolve("https://goo.gl/maps/invalid_test_url_xyz")
      assert {:error, _reason} = result
    end
  end
end
