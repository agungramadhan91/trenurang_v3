defmodule TrenurangAdapter.CommandRouterTest do
  use ExUnit.Case, async: true

  alias TrenurangAdapter.CommandRouter

  @session %{active_flow: nil, is_registered: true, is_buyer: true,
             has_store: true, has_relation: true, lang: :id}
  @chat_id 123

  test "dispatch start" do
    assert {:ok, :start} = CommandRouter.dispatch(@session, "start", @chat_id)
  end

  test "dispatch register" do
    assert {:ok, :register} = CommandRouter.dispatch(@session, "register", @chat_id)
  end

  test "dispatch home" do
    assert {:ok, :home} = CommandRouter.dispatch(@session, "home", @chat_id)
  end

  test "dispatch order/walkin" do
    assert {:ok, :walkin} = CommandRouter.dispatch(@session, "order/walkin", @chat_id)
  end

  test "dispatch order/list" do
    assert {:ok, :order_list} = CommandRouter.dispatch(@session, "order/list", @chat_id)
  end

  test "dispatch order/create" do
    assert {:ok, :order_create} = CommandRouter.dispatch(@session, "order/create", @chat_id)
  end

  test "dispatch order/confirm-price" do
    assert {:ok, :order_confirm_price} = CommandRouter.dispatch(@session, "order/confirm-price", @chat_id)
  end

  test "dispatch order/cancel" do
    assert {:ok, :order_cancel} = CommandRouter.dispatch(@session, "order/cancel", @chat_id)
  end

  test "dispatch store/walkin/generate" do
    assert {:ok, :store_walkin_generate} = CommandRouter.dispatch(@session, "store/walkin/generate", @chat_id)
  end

  test "dispatch store/walkin/record" do
    assert {:ok, :store_walkin_record} = CommandRouter.dispatch(@session, "store/walkin/record", @chat_id)
  end

  test "dispatch unknown command → {:unhandled, cmd}" do
    assert {:unhandled, "blah"} = CommandRouter.dispatch(@session, "blah", @chat_id)
  end
end
