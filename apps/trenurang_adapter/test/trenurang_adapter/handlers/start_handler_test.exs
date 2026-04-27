defmodule TrenurangAdapter.Handlers.StartHandlerTest do
  use ExUnit.Case, async: true

  alias TrenurangAdapter.Handlers.StartHandler

  defp guest(overrides \\ %{}) do
    Map.merge(
      %{
        user_id: "c999",
        lang: :id,
        active_flow: nil,
        is_registered: false,
        has_store: false,
        has_relation: false,
        is_buyer: false
      },
      overrides
    )
  end

  describe "handle/2" do
    test "guest tanpa active_flow → :ok (tampil welcome)" do
      assert :ok = StartHandler.handle(guest(), 999)
    end

    test "guest mid-register → :ok (tampil interrupted)" do
      flow = %{flow: :register, step: 2, data: %{}}
      assert :ok = StartHandler.handle(guest(%{active_flow: flow}), 999)
    end

    test "registered user → delegate ke HomeHandler → :ok" do
      session = guest(%{is_registered: true, username: "@budi"})
      assert :ok = StartHandler.handle(session, 999)
    end
  end

  describe "handle_help/2" do
    test "delegate ke handle/2 → :ok" do
      assert :ok = StartHandler.handle_help(guest(), 999)
    end
  end

  describe "handle_about/2" do
    test "return :ok" do
      assert :ok = StartHandler.handle_about(guest(), 999)
    end
  end
end
