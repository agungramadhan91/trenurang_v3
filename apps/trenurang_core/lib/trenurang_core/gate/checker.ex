defmodule TrenurangCore.Gate.Checker do
  @moduledoc """
  Gate checker L0–L4.

  Level:
    L0 — Siapapun (guest ok)
    L1 — Harus registered (name + username di DB)
    L2 — Harus pernah jadi buyer
    L3 — Harus punya toko (seller)
    L4 — Harus punya relasi B2B aktif

  Returns:
    :ok | {:error, :requires_register | :requires_buyer | :requires_seller | :requires_relation | :unknown_route | :invalid_session}
  """

  # L0 — routes yang bisa diakses siapapun termasuk guest
  @l0_routes [
    "/start",
    "/about",
    "/help",
    "/terms",
    "/settings",
    "/market/browse",
    "/register",           # tambah
    "/register/confirm"    # tambah
  ]

  # L2 — routes yang butuh is_buyer
  @l2_routes [
    "/market/find",
    "/cart",
    "/order/create",
    "/order/confirm",
    "/order/cancel",
    "/dispute/raise",
    "/dispute/show",
    "/chat/b2c"
  ]

  # L3 — routes yang butuh has_store
  @l3_routes [
    "/store/show",
    "/store/edit",
    "/store/products",
    "/store/orders/incoming",
    "/store/walkin/generate",
    "/chat/store",
    "/chat/seller"
  ]

  # L4 — routes yang butuh has_relation
  @l4_routes [
    "/relation/new",
    "/relation/show",
    "/relation/list",
    "/chat/b2b"
  ]

  @spec check(String.t(), map() | nil) ::
          :ok
          | {:error,
             :requires_register
             | :requires_buyer
             | :requires_seller
             | :requires_relation
             | :unknown_route
             | :invalid_session}

  def check(route, session) do
    cond do
      l0?(route) -> :ok
      known_route?(route) -> check_session(route, session)
      true -> {:error, :unknown_route}
    end
  end

  # --- Private ---

  defp l0?(route), do: route in @l0_routes

  defp known_route?(route) do
    route in @l0_routes or
      route in @l2_routes or
      route in @l3_routes or
      route in @l4_routes or
      l1_route?(route)
  end

  # L1 = semua route yang dikenal tapi bukan L0/L2/L3/L4
  # termasuk /order/walkin, /profile/show, /store/new, dll
  defp l1_route?(route) do
    route in [
      "/order/walkin",
      "/profile/show",
      "/profile/edit",
      "/store/new",
      "/settings/lang",
      "/home"
    ]
  end

  defp check_session(_route, nil), do: {:error, :requires_register}

  defp check_session(_route, session) when not is_map(session),
    do: {:error, :invalid_session}

  defp check_session(route, session) do
    case session do
      %{is_registered: _, is_buyer: _, has_store: _, has_relation: _} ->
        do_check(route, session)

      _ ->
        {:error, :invalid_session}
    end
  end

  defp do_check(route, session) do
    cond do
      route in @l4_routes -> check_l4(session)
      route in @l3_routes -> check_l3(session)
      route in @l2_routes -> check_l2(session)
      true -> check_l1(session)
    end
  end

  defp check_l1(%{is_registered: true}), do: :ok
  defp check_l1(_), do: {:error, :requires_register}

  defp check_l2(%{is_registered: true, is_buyer: true}), do: :ok
  defp check_l2(%{is_registered: false}), do: {:error, :requires_register}
  defp check_l2(_), do: {:error, :requires_buyer}

  defp check_l3(%{is_registered: true, has_store: true}), do: :ok
  defp check_l3(%{is_registered: false}), do: {:error, :requires_register}
  defp check_l3(_), do: {:error, :requires_seller}

  defp check_l4(%{is_registered: true, has_store: true, has_relation: true}), do: :ok
  defp check_l4(%{is_registered: false}), do: {:error, :requires_register}
  defp check_l4(%{has_store: false}), do: {:error, :requires_seller}
  defp check_l4(_), do: {:error, :requires_relation}
end
