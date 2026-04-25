defmodule TrenurangCore.Gate.CheckerTest do
  use ExUnit.Case, async: true

  alias TrenurangCore.Gate.Checker

  @tag :unit

  defp guest, do: nil

  defp l1_session do
    %{is_registered: true, is_buyer: false, has_store: false, has_relation: false}
  end

  defp l2_session do
    %{is_registered: true, is_buyer: true, has_store: false, has_relation: false}
  end

  defp l3_session do
    %{is_registered: true, is_buyer: false, has_store: true, has_relation: false}
  end

  defp l4_session do
    %{is_registered: true, is_buyer: true, has_store: true, has_relation: true}
  end

  # L0 — siapapun boleh akses
  test "L0: /start tanpa session" do
    assert :ok = Checker.check("/start", guest())
  end

  test "L0: /market/browse tanpa session" do
    assert :ok = Checker.check("/market/browse", guest())
  end

  test "L0: /terms tanpa session" do
    assert :ok = Checker.check("/terms", guest())
  end

  # L1 — harus registered
  test "L1: /order/walkin dengan user registered" do
    assert :ok = Checker.check("/order/walkin", l1_session())
  end

  test "L1: /order/walkin tanpa registrasi" do
    assert {:error, :requires_register} = Checker.check("/order/walkin", guest())
  end

  test "L1: /profile/show user terdaftar" do
    assert :ok = Checker.check("/profile/show", l1_session())
  end

  test "L1: /store/new tidak butuh L3 — cukup L1" do
    assert :ok = Checker.check("/store/new", l1_session())
  end

  test "L1: /market/find user registered — tidak butuh is_buyer" do
    assert :ok = Checker.check("/market/find", l1_session())
  end

  test "L1: /market/find guest → requires_register" do
    assert {:error, :requires_register} = Checker.check("/market/find", guest())
  end

  test "L1: /market/find tidak butuh is_buyer — l2_session juga ok" do
    assert :ok = Checker.check("/market/find", l2_session())
  end

  # L2 — harus buyer
  test "L2: /cart tanpa pernah order" do
    assert {:error, :requires_buyer} = Checker.check("/cart", l1_session())
  end

  test "L2: /order/create buyer aktif" do
    assert :ok = Checker.check("/order/create", l2_session())
  end

  test "L2: /dispute/raise seller-only user tanpa order sebagai buyer" do
    assert {:error, :requires_buyer} = Checker.check("/dispute/raise", l3_session())
  end

  # L3 — harus seller
  test "L3: /store/orders/incoming seller" do
    assert :ok = Checker.check("/store/orders/incoming", l3_session())
  end

  test "L3: /chat/store user bukan seller" do
    assert {:error, :requires_seller} = Checker.check("/chat/store", l2_session())
  end

  # L4 — harus has_relation
  test "L4: /relation/new seller dengan relasi" do
    assert :ok = Checker.check("/relation/new", l4_session())
  end

  test "L4: /chat/b2b seller tanpa relasi" do
    assert {:error, :requires_relation} = Checker.check("/chat/b2b", l3_session())
  end

  test "L3: /store/walkin/record seller" do
    assert :ok = Checker.check("/store/walkin/record", l3_session())
  end

  test "L3: /store/walkin/record bukan seller → requires_seller" do
    assert {:error, :requires_seller} = Checker.check("/store/walkin/record", l2_session())
  end

  # Edge cases
  test "edge: route tidak dikenal" do
    assert {:error, :unknown_route} = Checker.check("/unknown/route", l4_session())
  end

  test "edge: session corrupt (missing key)" do
    corrupt = %{is_registered: true}
    assert {:error, :invalid_session} = Checker.check("/order/walkin", corrupt)
  end

  test "edge: L1 route dengan guest mengembalikan requires_register" do
    assert {:error, :requires_register} = Checker.check("/profile/show", guest())
  end

  test "edge: L4 route dengan L1 session mengembalikan requires_buyer atau requires_seller" do
    result = Checker.check("/relation/new", l1_session())
    assert result in [{:error, :requires_seller}, {:error, :requires_relation}]
  end
end
