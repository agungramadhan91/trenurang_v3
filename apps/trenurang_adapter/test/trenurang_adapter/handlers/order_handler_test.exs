defmodule TrenurangAdapter.Handlers.OrderHandlerTest do
  use ExUnit.Case, async: true

  alias TrenurangAdapter.Handlers.OrderHandler

  @session %{active_flow: nil, is_registered: true, is_buyer: true,
             has_store: false, has_relation: false, lang: :id}
  @chat_id 123

  test "handle :list mengembalikan {:ok, :order_list}" do
    assert {:ok, :order_list} = OrderHandler.handle(:list, @session, @chat_id)
  end

  test "handle :create mengembalikan {:ok, :order_create}" do
    assert {:ok, :order_create} = OrderHandler.handle(:create, @session, @chat_id)
  end

  test "handle :status mengembalikan {:ok, :order_status}" do
    assert {:ok, :order_status} = OrderHandler.handle(:status, @session, @chat_id)
  end

  test "handle :confirm_price mengembalikan {:ok, :order_confirm_price}" do
    assert {:ok, :order_confirm_price} = OrderHandler.handle(:confirm_price, @session, @chat_id)
  end

  test "handle :cancel mengembalikan {:ok, :order_cancel}" do
    assert {:ok, :order_cancel} = OrderHandler.handle(:cancel, @session, @chat_id)
  end
end
