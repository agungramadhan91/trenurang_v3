defmodule TrenurangCore.Location.BoundingBoxTest do
  use ExUnit.Case, async: true

  alias TrenurangCore.Location.BoundingBox

  test "koordinat Jakarta dalam Indonesia" do
    assert BoundingBox.indonesia?(-6.2088, 106.8456)
  end

  test "koordinat Bandung dalam Indonesia" do
    assert BoundingBox.indonesia?(-6.9175, 107.6191)
  end

  test "koordinat Paris di luar Indonesia" do
    refute BoundingBox.indonesia?(48.8566, 2.3522)
  end

  test "koordinat Sydney di luar Indonesia" do
    refute BoundingBox.indonesia?(-33.8688, 151.2093)
  end

  test "input non-number" do
    refute BoundingBox.indonesia?("abc", "def")
  end
end
