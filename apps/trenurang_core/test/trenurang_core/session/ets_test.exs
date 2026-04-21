defmodule TrenurangCore.Session.ETSTest do
  use ExUnit.Case, async: false

  alias TrenurangCore.Session.ETS, as: SessionETS

  @tag :unit
  setup do
    # Bersihkan table sebelum setiap test
    :ets.delete_all_objects(:trenurang_sessions)
    :ok
  end

  defp build_session(user_id) do
    %{
      user_id:         user_id,
      username:        "@test",
      lang:            :id,
      locations:       [],
      active_location: 0,
      route:           %{current: "/start", previous: nil},
      active_flow:     nil,
      is_registered:   true,
      is_buyer:        false,
      has_store:       false,
      has_relation:    false
    }
  end

  test "insert session baru dan get kembali" do
    session = build_session("u#1")
    SessionETS.put("u#1", session)
    assert SessionETS.get("u#1") == session
  end

  test "get session yang tidak ada mengembalikan nil" do
    assert SessionETS.get("u#999") == nil
  end

  test "update active_flow" do
    SessionETS.put("u#1", build_session("u#1"))
    flow = %{flow: :register, step: 2, data: %{name: "Ahmad"}}
    assert :ok = SessionETS.update("u#1", :active_flow, flow)
    assert SessionETS.get("u#1").active_flow == flow
  end

  test "clear active_flow dengan set nil" do
    session = build_session("u#1") |> Map.put(:active_flow, %{flow: :register, step: 1, data: %{}})
    SessionETS.put("u#1", session)
    assert :ok = SessionETS.update("u#1", :active_flow, nil)
    assert SessionETS.get("u#1").active_flow == nil
    assert SessionETS.get("u#1").route != nil
  end

  test "update active_location" do
    SessionETS.put("u#1", build_session("u#1"))
    assert :ok = SessionETS.update("u#1", :active_location, 1)
    assert SessionETS.get("u#1").active_location == 1
  end

  test "delete session" do
    SessionETS.put("u#1", build_session("u#1"))
    SessionETS.delete("u#1")
    assert SessionETS.get("u#1") == nil
  end

  test "update session yang tidak ada mengembalikan error" do
    assert {:error, :not_found} = SessionETS.update("u#999", :lang, :en)
  end

  test "multi-location tersimpan" do
    locations = [
      %{label: "Rumah", lat: -6.2, lng: 106.8},
      %{label: "Pasar", lat: -6.3, lng: 106.9}
    ]
    session = build_session("u#1") |> Map.put(:locations, locations)
    SessionETS.put("u#1", session)
    assert length(SessionETS.get("u#1").locations) == 2
  end

  test "count mengembalikan jumlah session" do
    :ets.delete_all_objects(:trenurang_sessions)
    SessionETS.put("u#1", build_session("u#1"))
    SessionETS.put("u#2", build_session("u#2"))
    assert SessionETS.count() == 2
  end

  @tag :slow
  test "concurrent write 100 proses tidak ada race condition" do
    tasks =
      for i <- 1..100 do
        Task.async(fn -> SessionETS.put("u##{i}", build_session("u##{i}")) end)
      end

    Task.await_many(tasks, 5_000)
    assert SessionETS.count() == 100
  end
end
