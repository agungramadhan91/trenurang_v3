defmodule TrenurangAdapter.Handlers.HomeHandlerTest do
  use ExUnit.Case, async: true

  alias TrenurangAdapter.Handlers.HomeHandler

  defp session(overrides \\ %{}) do
    Map.merge(
      %{
        user_id: "u#1",
        username: "@budi",
        lang: :id,
        active_flow: nil,
        is_registered: true,
        is_buyer: false,
        has_store: false,
        has_relation: false
      },
      overrides
    )
  end

  describe "handle/2" do
    test "unregistered → delegate ke StartHandler → :ok" do
      assert :ok = HomeHandler.handle(session(%{is_registered: false}), 999)
    end

    test "buyer (no store) → :ok" do
      assert :ok = HomeHandler.handle(session(%{is_buyer: true}), 999)
    end

    test "seller (has_store: true) → :ok" do
      assert :ok = HomeHandler.handle(session(%{has_store: true}), 999)
    end

    test "registered buyer default → :ok" do
      assert :ok = HomeHandler.handle(session(), 999)
    end
  end
end
