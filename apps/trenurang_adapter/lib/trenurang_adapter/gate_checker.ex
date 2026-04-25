defmodule TrenurangAdapter.GateChecker do
  @moduledoc """
  Wrapper adapter untuk TrenurangCore.Gate.Checker.

  Menerima session map dan route string, return :ok atau {:error, reason}.
  """

  alias TrenurangCore.Gate.Checker

  @spec check(map(), String.t()) ::
          :ok
          | {:error,
             :requires_register
             | :requires_buyer
             | :requires_seller
             | :requires_relation
             | :unknown_route
             | :invalid_session}

  def check(session, route) when is_map(session) and is_binary(route) do
    Checker.check(route, session)   # core: route dulu, session kedua
  end
end
