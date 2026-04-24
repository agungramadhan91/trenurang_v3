defmodule TrenurangAdapter.ResponseFormatterTest do
  use ExUnit.Case, async: true

  alias TrenurangAdapter.ResponseFormatter

  describe "text/2" do
    test "return tuple {:text, chat_id, content, []}" do
      assert {:text, 123, "halo", []} = ResponseFormatter.text(123, "halo")
    end
  end

  describe "text_with_keyboard/3" do
    test "return tuple dengan reply_markup JSON" do
      buttons = [ResponseFormatter.row([{"OK", "ok"}])]
      assert {:text, 123, "pilih:", opts} = ResponseFormatter.text_with_keyboard(123, "pilih:", buttons)
      assert Keyword.has_key?(opts, :reply_markup)
      assert {:ok, decoded} = Jason.decode(opts[:reply_markup])
      assert Map.has_key?(decoded, "inline_keyboard")
    end
  end

  describe "row/1" do
    test "konversi list tuple ke list map button" do
      row = ResponseFormatter.row([{"Ya", "yes"}, {"Tidak", "no"}])
      assert [%{text: "Ya", callback_data: "yes"}, %{text: "Tidak", callback_data: "no"}] = row
    end
  end
end
