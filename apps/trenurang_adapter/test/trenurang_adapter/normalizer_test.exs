defmodule TrenurangAdapter.NormalizerTest do
  use ExUnit.Case, async: true

  alias TrenurangAdapter.Normalizer

  describe "normalize/1" do
    test "strip leading slash" do
      assert Normalizer.normalize("/start") == "start"
    end

    test "lowercase" do
      assert Normalizer.normalize("START") == "start"
      assert Normalizer.normalize("/MARKET/browse") == "market/browse"
    end

    test "trim whitespace" do
      assert Normalizer.normalize("  /start  ") == "start"
    end

    test "alias: halo → start" do
      assert Normalizer.normalize("halo") == "start"
    end

    test "alias: hai → start" do
      assert Normalizer.normalize("hai") == "start"
    end

    test "alias: hello → start" do
      assert Normalizer.normalize("hello") == "start"
    end

    test "alias: mulai → start" do
      assert Normalizer.normalize("mulai") == "start"
    end

    test "alias: menu → home" do
      assert Normalizer.normalize("menu") == "home"
    end

    test "non-alias free text tetap utuh" do
      assert Normalizer.normalize("mau beli baju") == "mau beli baju"
    end

    test "non-binary input return empty string" do
      assert Normalizer.normalize(nil) == ""
      assert Normalizer.normalize(123) == ""
    end
  end
end
