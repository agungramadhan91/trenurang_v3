defmodule TrenurangCore.Session.Hydrator do
  @moduledoc """
  Load session dari DB ke ETS saat user pertama kali kirim pesan.

  Flow:
    1. Cek ETS — ada? return langsung (tidak hit DB)
    2. Tidak ada? Query DB
    3. Tidak ada di DB? {:error, :not_found}
    4. Ada di DB? Populate ETS, return session
  """

  import Ecto.Query

  alias TrenurangCore.Repo
  alias TrenurangCore.Session.ETS, as: SessionETS
  alias TrenurangCore.Schema.User
  alias TrenurangCore.Schema.UserLocation
  alias TrenurangCore.Schema.UserSessionState
  alias TrenurangCore.Schema.Store
  alias TrenurangCore.Schema.StoreOrder
  alias TrenurangCore.Schema.StoreRelation

  @spec hydrate(integer()) :: {:ok, map()} | {:error, :not_found}
  def hydrate(user_id) when is_integer(user_id) do
    prefixed = "u##{user_id}"

    case SessionETS.get(prefixed) do
      nil -> load_from_db(user_id, prefixed)
      session -> {:ok, session}
    end
  end

  # --- Private ---

  defp load_from_db(user_id, prefixed) do
    case Repo.get(User, user_id) do
      nil ->
        {:error, :not_found}

      user ->
        session = build_session(user, prefixed)
        SessionETS.put(prefixed, session)
        {:ok, session}
    end
  end

  defp build_session(user, prefixed) do
    locations = load_locations(user.id)
    active_flow = load_active_flow(user.id)
    route = load_route(user.id)

    %{
      user_id:         prefixed,
      username:        "@#{user.username}",
      lang:            String.to_existing_atom(user.lang),
      locations:       locations,
      active_location: 0,
      route:           route,
      active_flow:     active_flow,
      is_registered:   true,
      is_buyer:        buyer?(user.id),
      has_store:       has_store?(user.id),
      has_relation:    has_relation?(user.id)
    }
  end

  defp load_locations(user_id) do
    UserLocation
    |> where([l], l.user_id == ^user_id and l.is_active == true)
    |> Repo.all()
    |> Enum.map(fn loc ->
      %{
        label:    loc.label,
        lat:      loc.coordinates && loc.coordinates.coordinates |> elem(1),
        lng:      loc.coordinates && loc.coordinates.coordinates |> elem(0),
        days:     loc.days,
        hours:    {loc.hours_start, loc.hours_end},
        duration: parse_duration(loc.duration_type, loc.duration_value)
      }
    end)
  end

  defp load_active_flow(user_id) do
    case Repo.get_by(UserSessionState, user_id: user_id) do
      nil -> nil
      %{active_flow: nil} -> nil
      %{active_flow: flow} -> atomize_flow(flow)
    end
  end

  defp load_route(user_id) do
    case Repo.get_by(UserSessionState, user_id: user_id) do
      nil -> %{current: "/start", previous: nil}
      state -> %{current: state.route_current, previous: state.route_previous}
    end
  end

  defp buyer?(user_id) do
    Repo.exists?(
      from o in StoreOrder,
        where: o.buyer_id == ^user_id and o.status == "completed"
    )
  end

  defp has_store?(user_id) do
    Repo.exists?(
      from s in Store,
        where: s.owner_id == ^user_id and s.status == "active"
    )
  end

  defp has_relation?(user_id) do
    Repo.exists?(
      from r in StoreRelation,
        join: s in Store,
          on: s.id == r.supplier_id or s.id == r.receiver_id,
        where: s.owner_id == ^user_id
    )
  end

  defp parse_duration("permanent", _), do: :permanent
  defp parse_duration("weeks", value), do: {:weeks, value}
  defp parse_duration(_, _), do: :permanent

  defp atomize_flow(%{"flow" => flow, "step" => step, "data" => data}) do
    %{
      flow: String.to_existing_atom(flow),
      step: step,
      data: data
    }
  end

  defp atomize_flow(_), do: nil
end
