defmodule TrenurangAdapter.FlowRouterTest do
  use ExUnit.Case, async: true

  alias TrenurangAdapter.FlowRouter

  @flow %{flow: :register, step: 2, data: %{name: "Ahmad"}}

  describe "route/2 — tanpa active_flow" do
    test "session nil active_flow → {:command, input}" do
      session = %{active_flow: nil}
      assert {:command, "start"} = FlowRouter.route(session, "start")
    end

    test "session tanpa key active_flow → {:command, input}" do
      assert {:command, "market/browse"} = FlowRouter.route(%{}, "market/browse")
    end
  end

  describe "route/2 — dengan active_flow, input step/button" do
    test "satu kata pendek dianggap step" do
      session = %{active_flow: @flow}
      assert {:flow_step, @flow, "ya"} = FlowRouter.route(session, "ya")
    end

    test "input command pendek dianggap step" do
      session = %{active_flow: @flow}
      assert {:flow_step, @flow, "confirm"} = FlowRouter.route(session, "confirm")
    end
  end

  describe "route/2 — dengan active_flow, input free text" do
    test "kalimat lebih dari satu kata → {:flow_free_text, flow, text}" do
      session = %{active_flow: @flow}
      result = FlowRouter.route(session, "mau beli baju murah")
      assert {:flow_free_text, @flow, "mau beli baju murah"} = result
    end

    test "input panjang (>20 karakter) → free text" do
      session = %{active_flow: @flow}
      input = "pertanyaanyangsangatpanjang"
      assert {:flow_free_text, @flow, ^input} = FlowRouter.route(session, input)
    end
  end
end
