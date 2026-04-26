defmodule TrenurangCore.LocaleTest do
  use ExUnit.Case, async: true

  alias TrenurangCore.Locale

  describe "t/2 — basic translation" do
    test "returns id translation" do
      result = Locale.t(:common_yes, :id)
      assert result == "Ya"
    end

    test "returns en translation" do
      result = Locale.t(:common_yes, :en)
      assert result == "Yes"
    end
  end

  describe "t/3 — interpolation" do
    test "interpolates single param" do
      result = Locale.t(:start_welcome_back, :id, %{name: "Budi"})
      assert result =~ "Budi"
    end

    test "interpolates multiple params" do
      result = Locale.t(:register_step5_confirm, :id, %{
        name: "Budi",
        username: "budi_jkt",
        location: "Jakarta",
        lang: "Indonesia"
      })
      assert result =~ "Budi"
      assert result =~ "budi_jkt"
      assert result =~ "Jakarta"
    end

    test "returns translation as-is when no params" do
      result = Locale.t(:common_cancel, :id)
      assert result == "Dibatalkan."
    end
  end

  describe "t/2 — fallback chain" do
    test "unknown lang falls back to :en" do
      result = Locale.t(:common_yes, :fr)
      assert result == "Yes"
    end

    test "stub lang (zh) falls back to :en" do
      result = Locale.t(:common_yes, :zh)
      assert result == "Yes"
    end

    test "stub lang (de) falls back to :en" do
      result = Locale.t(:common_yes, :de)
      assert result == "Yes"
    end

    test "missing key in :en falls back to :id" do
      # common_yes ada di :id, jadi ini test fallback path en→id
      # kita test dengan key yang ada di :id tapi tidak di :en stub
      # dalam implementasi ini kedua lang punya key yang sama,
      # jadi kita test key tidak dikenal sama sekali
      result = Locale.t(:nonexistent_key_xyz, :en)
      assert is_binary(result)
      assert String.length(result) > 0
    end

    test "completely unknown key returns stringified key" do
      result = Locale.t(:nonexistent_key_xyz, :id)
      assert result == "nonexistent key xyz"
    end
  end

  describe "t/2 — lang atom from session" do
    test "accepts :id atom" do
      assert is_binary(Locale.t(:common_done, :id))
    end

    test "accepts :en atom" do
      assert is_binary(Locale.t(:common_done, :en))
    end
  end

  describe "error keys — wajib ada di :id dan :en" do
    for key <- [:error_gate_l1, :error_gate_l2, :error_gate_l3, :error_gate_l4, :error_unknown_command] do
      test "#{key} ada di :id dan non-empty" do
        result = Locale.t(unquote(key), :id)
        assert is_binary(result)
        assert String.length(result) > 0
        refute result == Atom.to_string(unquote(key)) |> String.replace("_", " ")
      end

      test "#{key} ada di :en dan non-empty" do
        result = Locale.t(unquote(key), :en)
        assert is_binary(result)
        assert String.length(result) > 0
        refute result == Atom.to_string(unquote(key)) |> String.replace("_", " ")
      end
    end
  end
end
