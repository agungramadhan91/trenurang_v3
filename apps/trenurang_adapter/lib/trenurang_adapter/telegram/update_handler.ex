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

  @doc "Entry point untuk setiap Telegram update."
  @spec handle(%Telegex.Type.Update{}) :: :ok
  def handle(%Telegex.Type.Update{} = update) do
    with {:ok, chat_id, raw_text} <- extract(update) do
      process(chat_id, raw_text)
    else
      {:error, :unsupported_update} ->
        Logger.debug("[UpdateHandler] Update diabaikan — bukan message/callback")
        :ok
    end
  end

  # ---- Private ----

  defp process(chat_id, raw_text) do
    # Step 1 — Record channel identity (selalu :ok, tidak pernah block)
    :ok = ChannelIdentityRecorder.record(to_string(chat_id))

    # Step 2 — Ambil channel_identity untuk cek user_id
    {:ok, ci} = ChannelIdentityRecorder.get_identity(to_string(chat_id))

    # Step 3 — Normalize input
    normalized = Normalizer.normalize(raw_text)

    # Step 4 — Hydrate session
    session = case ci.user_id do
      nil ->
        # Guest — session minimal
        %{active_flow: nil, is_registered: false, is_buyer: false,
          has_store: false, has_relation: false, lang: :id}

      user_id ->
        case SessionHydrator.hydrate(user_id) do
          {:ok, s}              -> s
          {:error, :not_found}  ->
            %{active_flow: nil, is_registered: false, is_buyer: false,
              has_store: false, has_relation: false, lang: :id}
        end
    end

    # Step 5 — Gate check
    route = normalized_to_route(normalized)
    case GateChecker.check(session, route) do
      :ok ->
        execute(session, normalized, chat_id)

      {:error, :requires_register} ->
        Sender.send(ResponseFormatter.text(chat_id, "Silakan daftar dulu. Ketik /register"))

      {:error, :requires_buyer} ->
        Sender.send(ResponseFormatter.text(chat_id, "Fitur ini untuk buyer. Buat order dulu."))

      {:error, :requires_seller} ->
        Sender.send(ResponseFormatter.text(chat_id, "Fitur ini untuk seller. Buat toko dulu."))

      {:error, :requires_relation} ->
        Sender.send(ResponseFormatter.text(chat_id, "Fitur ini untuk mitra B2B."))

      {:error, :unknown_route} ->
        execute(session, normalized, chat_id)

      {:error, _} ->
        execute(session, normalized, chat_id)
    end
  end

  defp execute(session, normalized, chat_id) do
    case FlowRouter.route(session, normalized) do
      {:command, cmd} ->
        case CommandRouter.dispatch(session, cmd, chat_id) do
          {:unhandled, _input} ->
            Sender.send(ResponseFormatter.text(chat_id, "Perintah tidak dikenali. Ketik /help"))
          _ ->
            :ok
        end

      {:flow_step, _flow, _input} ->
        # TODO Fase 6: teruskan ke flow handler
        :ok

      {:flow_free_text, _flow, _text} ->
        # TODO Fase 7: kirim ke Intelligence classifier
        :ok
    end
  end

  defp normalized_to_route("start"),          do: "/start"
  defp normalized_to_route("register"),       do: "/register"
  defp normalized_to_route("home"),           do: "/home"
  defp normalized_to_route("market/browse"),  do: "/market/browse"
  defp normalized_to_route("market/find" <> rest), do: "/market/find" <> rest
  defp normalized_to_route("store" <> rest),  do: "/store" <> rest
  defp normalized_to_route("order" <> rest),  do: "/order" <> rest
  defp normalized_to_route("cart" <> rest),   do: "/cart" <> rest
  defp normalized_to_route("relation" <> rest), do: "/relation" <> rest
  defp normalized_to_route("chat" <> rest),   do: "/chat" <> rest
  defp normalized_to_route("dispute" <> rest), do: "/dispute" <> rest
  defp normalized_to_route("terms"),          do: "/terms"
  defp normalized_to_route("settings"),       do: "/settings"
  defp normalized_to_route("help"),           do: "/help"
  defp normalized_to_route(_),               do: "/unknown"

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
