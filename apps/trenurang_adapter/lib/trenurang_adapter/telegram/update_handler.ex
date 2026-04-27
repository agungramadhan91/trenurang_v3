defmodule TrenurangAdapter.Telegram.UpdateHandler do
  @moduledoc """
  Orchestrator pipeline untuk setiap Telegram update.

  Urutan:
    1. Extract chat_id + text/lokasi dari update
    2. ChannelIdentityRecorder — upsert, ambil channel_identity
    3. Normalizer — normalize input
    4. SessionHydrator — load session (guest jika belum registered)
    5. GateChecker — cek prerequisite gate
    6. FlowRouter — routing berdasarkan active_flow
    7. CommandRouter / FlowDispatcher — eksekusi
    8. Sender — kirim response

  Guest session di-store di ETS dengan key "c{chat_id}" agar
  multi-step flow (register) bisa persist antar pesan.
  """

  require Logger

  alias TrenurangAdapter.{
    ChannelIdentityRecorder,
    Normalizer,
    SessionHydrator,
    GateChecker,
    FlowRouter,
    FlowDispatcher,
    CommandRouter,
    ResponseFormatter
  }
  alias TrenurangAdapter.Telegram.Sender
  alias TrenurangCore.Locale
  alias TrenurangCore.Session.ETS, as: SessionETS

  @doc "Entry point untuk setiap Telegram update."
  @spec handle(%Telegex.Type.Update{}) :: :ok
  def handle(%Telegex.Type.Update{} = update) do
    with {:ok, chat_id, raw_text} <- extract(update) do
      Logger.info("[IN] chat_id=#{chat_id} text=#{inspect(raw_text)}")
      case ChannelIdentityRecorder.record_and_get(to_string(chat_id)) do
        {:ok, ci} ->
          continue_pipeline(ci, raw_text, chat_id)

        {:error, _} ->
          Logger.warning("[UpdateHandler] Gagal record channel_id=#{chat_id}")
          :ok
      end
    else
      {:error, :unsupported_update} ->
        Logger.info("[UpdateHandler] extract gagal — update diabaikan")
        :ok
    end
  end

  # ---- Private ----

  defp continue_pipeline(ci, raw_text, chat_id) do
    normalized = Normalizer.normalize(raw_text)
    Logger.debug("[PIPELINE] normalized=#{inspect(normalized)} user_id=#{inspect(ci.user_id)}")

    session =
      case ci.user_id do
        nil ->
          # Guest — cek ETS dulu (bisa ada active_flow dari register)
          guest_key = "c#{chat_id}"

          case SessionETS.get(guest_key) do
            nil ->
              %{
                user_id: guest_key,
                username: nil,
                lang: :id,
                locations: [],
                active_location: 0,
                route: %{current: "/start", previous: nil},
                active_flow: nil,
                is_registered: false,
                is_buyer: false,
                has_store: false,
                has_relation: false
              }

            existing ->
              existing
          end

        user_id ->
          case SessionHydrator.hydrate(user_id) do
            {:ok, s} ->
              s

            {:error, :not_found} ->
              guest_key = "c#{chat_id}"
              %{
                user_id: guest_key,
                username: nil,
                lang: :id,
                locations: [],
                active_location: 0,
                route: %{current: "/start", previous: nil},
                active_flow: nil,
                is_registered: false,
                is_buyer: false,
                has_store: false,
                has_relation: false
              }
          end
      end

    lang = Map.get(session, :lang, :id)
    route = normalized_to_route(normalized)

    case GateChecker.check(session, route) do
      :ok ->
        execute(session, normalized, chat_id)

      {:error, :requires_register} ->
        Sender.send(ResponseFormatter.text(chat_id, Locale.t(:error_gate_l1, lang)))

      {:error, :requires_buyer} ->
        Sender.send(ResponseFormatter.text(chat_id, Locale.t(:error_gate_l2, lang)))

      {:error, :requires_seller} ->
        Sender.send(ResponseFormatter.text(chat_id, Locale.t(:error_gate_l3, lang)))

      {:error, :requires_relation} ->
        Sender.send(ResponseFormatter.text(chat_id, Locale.t(:error_gate_l4, lang)))

      {:error, :unknown_route} ->
        execute(session, normalized, chat_id)

      {:error, _} ->
        execute(session, normalized, chat_id)
    end
  end

  defp execute(session, normalized, chat_id) do
    lang = Map.get(session, :lang, :id)

    case FlowRouter.route(session, normalized) do
      {:command, cmd} ->
        Logger.info("[DISPATCH] cmd=#{inspect(cmd)} registered=#{session.is_registered}")
        case CommandRouter.dispatch(session, cmd, chat_id) do
          {:unhandled, _input} ->
            Sender.send(ResponseFormatter.text(chat_id, Locale.t(:error_unknown_command, lang)))

          _ ->
            :ok
        end

      {:flow_step, flow, input} ->
        Logger.info("[FLOW] flow=#{inspect(flow.flow)} step=#{flow.step} input=#{inspect(input)}")
        FlowDispatcher.dispatch(session, flow, input, chat_id)

      {:flow_free_text, flow, text} ->
        Logger.info("[FLOW_TEXT] flow=#{inspect(flow.flow)} step=#{flow.step} text=#{inspect(text)}")
        FlowDispatcher.dispatch(session, flow, text, chat_id)
    end
  end

  defp normalized_to_route("market/find" <> _),          do: "/market/find"
  defp normalized_to_route("cart" <> _),                  do: "/cart"
  defp normalized_to_route("order/walkin"),               do: "/order/walkin"
  defp normalized_to_route("order" <> _),                 do: "/order/create"
  defp normalized_to_route("store/walkin/generate"),      do: "/store/walkin/generate"
  defp normalized_to_route("store/walkin/record"),        do: "/store/walkin/record"
  defp normalized_to_route("store/new"),                  do: "/store/new"
  defp normalized_to_route("store" <> _),                 do: "/store/show"
  defp normalized_to_route("relation" <> _),              do: "/relation/list"
  defp normalized_to_route("chat/b2c" <> _),              do: "/chat/b2c"
  defp normalized_to_route("chat/b2b" <> _),              do: "/chat/b2b"
  defp normalized_to_route("chat/store" <> _),            do: "/chat/store"
  defp normalized_to_route("chat/seller" <> _),           do: "/chat/seller"
  defp normalized_to_route("dispute" <> _),               do: "/dispute/raise"
  defp normalized_to_route("profile" <> _),               do: "/profile/show"
  defp normalized_to_route("settings" <> _),              do: "/settings"
  defp normalized_to_route("start"),                      do: "/start"
  defp normalized_to_route("register" <> _),              do: "/register"
  defp normalized_to_route("home"),                       do: "/home"
  defp normalized_to_route("terms"),                      do: "/terms"
  defp normalized_to_route("help"),                       do: "/help"
  defp normalized_to_route("about"),                      do: "/about"
  defp normalized_to_route(_),                            do: "/unknown"

  # Extract: pesan teks biasa
  defp extract(%Telegex.Type.Update{message: %{chat: %{id: chat_id}, text: text}})
       when not is_nil(text) do
    {:ok, chat_id, text}
  end

  # Extract: callback button (inline keyboard)
  defp extract(%Telegex.Type.Update{
         callback_query: %{message: %{chat: %{id: chat_id}}, data: data}
       })
       when not is_nil(data) do
    {:ok, chat_id, data}
  end

  # Extract: lokasi GPS dari Telegram location button
  defp extract(%Telegex.Type.Update{
         message: %{chat: %{id: chat_id}, location: %{latitude: lat, longitude: lng}}
       })
       when not is_nil(lat) do
    {:ok, chat_id, "#{lat},#{lng}"}
  end

  defp extract(_), do: {:error, :unsupported_update}
end
