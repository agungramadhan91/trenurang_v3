defmodule TrenurangAdapter.UpdateHandlerLocaleTest do
  use ExUnit.Case, async: true

  alias TrenurangCore.Locale

  @doc """
  Test ini memastikan semua key locale yang digunakan update_handler
  tersedia di :id dan :en — sehingga tidak ada string hardcoded
  yang bocor ke user saat gate error atau unknown command.
  """

  @gate_keys [:error_gate_l1, :error_gate_l2, :error_gate_l3, :error_gate_l4, :error_unknown_command]

  for key <- @gate_keys do
    test "#{key} tersedia dan non-empty di :id" do
      result = Locale.t(unquote(key), :id)
      assert is_binary(result)
      assert String.length(result) > 0
    end

    test "#{key} tersedia dan non-empty di :en" do
      result = Locale.t(unquote(key), :en)
      assert is_binary(result)
      assert String.length(result) > 0
    end
  end
end
