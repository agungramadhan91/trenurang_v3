defmodule TrenurangAdapter.ChannelIdentityRecorderTest do
  use ExUnit.Case, async: false

  alias TrenurangAdapter.ChannelIdentityRecorder

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(TrenurangCore.Repo)
  end

  describe "record/1" do
    test "return :ok untuk channel_id baru" do
      assert :ok == ChannelIdentityRecorder.record("tg_rec_001")
    end

    test "return :ok untuk channel_id yang sudah ada (idempotent)" do
      assert :ok == ChannelIdentityRecorder.record("tg_rec_002")
      assert :ok == ChannelIdentityRecorder.record("tg_rec_002")
    end
  end

  describe "get_identity/1" do
    test "return {:ok, ci} dengan channel = telegram" do
      assert {:ok, ci} = ChannelIdentityRecorder.get_identity("tg_rec_003")
      assert ci.channel == "telegram"
      assert ci.channel_id == "tg_rec_003"
    end

    test "user_id nil sebelum registrasi" do
      assert {:ok, ci} = ChannelIdentityRecorder.get_identity("tg_rec_004")
      assert is_nil(ci.user_id)
    end
  end
end
