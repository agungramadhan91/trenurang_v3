defmodule TrenurangCoreTest do
  use ExUnit.Case
  doctest TrenurangCore

  test "greets the world" do
    assert TrenurangCore.hello() == :world
  end
end
