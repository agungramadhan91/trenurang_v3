defmodule TrenurangAdapter.SessionHydrator do
  @moduledoc """
  Wrapper adapter untuk TrenurangCore.Session.Hydrator.

  Menerima user_id integer, return session map dari ETS/DB.
  Jika user belum registered (ghost), return {:error, :not_found}.
  """

  alias TrenurangCore.Session.Hydrator

  @spec hydrate(integer()) :: {:ok, map()} | {:error, :not_found}
  def hydrate(user_id) when is_integer(user_id) do
    Hydrator.hydrate(user_id)
  end
end
