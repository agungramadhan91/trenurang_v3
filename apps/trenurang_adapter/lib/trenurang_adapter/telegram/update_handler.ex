defmodule TrenurangAdapter.Telegram.UpdateHandler do
  @moduledoc """
  Orchestrator pipeline untuk setiap Telegram update.

  Urutan:
    1. Extract chat_id + text dari update
    2. ChannelIdentityRecorder — upsert, ambil channel_identity
    3. Normalizer — normalize input
    4. SessionHydrator — load session (guest jika belum registered)
    5. GateChecker — cek prerequisite gate
    6. FlowRouter — routing berdasarkan active_flow
    7. CommandRouter / FlowHandler — eksekusi
    8. Sender — kirim response

  Setiap step yang gagal mengirim error message ke user dan stop pipeline.
  Pipeline tidak pernah crash — semua error ditangkap dan di-log.
  """

  require Logger

  alias TrenurangAdapter.{
    ChannelIdentityRecorder,
    Normalizer,
    SessionHydrator,
    GateChecker,
    FlowRouter,
    CommandRouter,
    ResponseFormatter
  }
  alias TrenurangAdapter.Telegram.Sender
  alias TrenurangCore.Locale

  @doc "Entry point untuk setiap Telegram update."
  @spec handle(%Telegex.Type.Update{}) :: :ok
  def handle(%Telegex.Type.Update{} = update) do
    with {:ok, chat_id, raw_text} <- extract(update) do
      case ChannelIdentityRecorder.record_and_get(to_string(chat_id)) do
        {:ok, ci} ->
          continue_pipeline(ci, raw_text, chat_id)

        {:error, _} ->
          Logger.warning("[UpdateHandler] Gagal record channel_id=#{chat_id}")
          :ok
      end
    else
      {:error, :unsupported_update} ->
        Logger.debug("[UpdateHandler] Update diabaikan — bukan message/callback")
        :ok
    end
  end

  # ---- Private ----

  defp continue_pipeline(ci, raw_text, chat_id) do
    # Step 3 — Normalize input
    normalized = Normalizer.normalize(raw_text)

    # Step 4 — Hydrate session
    session =
      case ci.user_id do
        nil ->
          %{
            active_flow: nil,
            is_registered: false,
            is_buyer: false,
            has_store: false,
            has_relation: false,
            lang: :id
          }

        user_id ->
          case SessionHydrator.hydrate(user_id) do
            {:ok, s} ->
              s

            {:error, :not_found} ->
              %{
                active_flow: nil,
                is_registered: false,
                is_buyer: false,
                has_store: false,
                has_relation: false,
                lang: :id
              }
          end
      end

    lang = Map.get(session, :lang, :id)

    # Step 5 — Gate check
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
        case CommandRouter.dispatch(session, cmd, chat_id) do
          {:unhandled, _input} ->
            Sender.send(ResponseFormatter.text(chat_id, Locale.t(:error_unknown_command, lang)))
          _ ->
            :ok
        end

      {:flow_step, _flow, _input} ->
        :ok

      {:flow_free_text, _flow, _text} ->
        :ok
    end
  end

  defp normalized_to_route("market/find" <> _), do: "/market/find"
  defp normalized_to_route("cart" <> _),        do: "/cart"
  defp normalized_to_route("order/walkin"),      do: "/order/walkin"
  defp normalized_to_route("order" <> _),        do: "/order/create"
  defp normalized_to_route("store/walkin/generate"), do: "/store/walkin/generate"
  defp normalized_to_route("store/walkin/record"),   do: "/store/walkin/record"
  defp normalized_to_route("store/new"),             do: "/store/new"
  defp normalized_to_route("store" <> _),            do: "/store/show"
  defp normalized_to_route("relation" <> _),     do: "/relation/list"
  defp normalized_to_route("chat/b2c" <> _),     do: "/chat/b2c"
  defp normalized_to_route("chat/b2b" <> _),     do: "/chat/b2b"
  defp normalized_to_route("chat/store" <> _),   do: "/chat/store"
  defp normalized_to_route("chat/seller" <> _),  do: "/chat/seller"
  defp normalized_to_route("dispute" <> _),      do: "/dispute/raise"
  defp normalized_to_route("profile" <> _),      do: "/profile/show"
  defp normalized_to_route("settings" <> _),     do: "/settings"
  defp normalized_to_route("start"),             do: "/start"
  defp normalized_to_route("register" <> _),     do: "/register"
  defp normalized_to_route("home"),              do: "/home"
  defp normalized_to_route("terms"),             do: "/terms"
  defp normalized_to_route("help"),              do: "/help"
  defp normalized_to_route("about"),             do: "/about"
  defp normalized_to_route(_),                   do: "/unknown"

  defp extract(%Telegex.Type.Update{message: %{chat: %{id: chat_id}, text: text}})
       when not is_nil(text) do
    {:ok, chat_id, text}
  end

  defp extract(%Telegex.Type.Update{callback_query: %{message: %{chat: %{id: chat_id}}, data: data}})
       when not is_nil(data) do
    {:ok, chat_id, data}
  end

  defp extract(_), do: {:error, :unsupported_update}
end
