defmodule TrenurangCore.Location.CityLookupTest do
  use ExUnit.Case, async: true

  alias TrenurangCore.Location.CityLookup

  test "lookup kota dikenal" do
    assert {:ok, {lat, lng}} = CityLookup.lookup("jakarta")
    assert is_float(lat)
    assert is_float(lng)
  end

  test "case insensitive" do
    assert {:ok, _} = CityLookup.lookup("Jakarta")
    assert {:ok, _} = CityLookup.lookup("BANDUNG")
  end

  test "trim whitespace" do
    assert {:ok, _} = CityLookup.lookup("  bogor  ")
  end

  test "kota tidak dikenal" do
    assert {:error, :not_found} = CityLookup.lookup("Hogwarts")
  end

  test "supported/0 mengembalikan list" do
    list = CityLookup.supported()
    assert is_list(list)
    assert length(list) > 0
    assert "jakarta" in list
  end
end
