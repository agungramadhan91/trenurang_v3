defmodule TrenurangAdapter.Handlers.RegisterHandler do
  @moduledoc """
  Handler untuk flow registrasi 5 langkah.

  Step 1 — Nama
  Step 2 — Username
  Step 3 — Email (opsional)
  Step 4 — Lokasi
  Step 5 — Konfirmasi + simpan ke DB
  """

  require Logger

  alias TrenurangAdapter.ResponseFormatter
  alias TrenurangAdapter.Telegram.Sender
  alias TrenurangCore.Locale
  alias TrenurangCore.Session.ETS, as: SessionETS
  alias TrenurangCore.Session.Hydrator
  alias TrenurangCore.Context.Accounts
  alias TrenurangCore.Location.Parser, as: LocationParser

  @reserved_names ~w(halo hai hello hi start help about admin trenurang test oke ok menu home)
  @username_regex ~r/^[a-z][a-z0-9_]{2,29}$/

  # ---- Entry dari CommandRouter (belum ada active_flow) ----

  def handle(session, chat_id) do
    lang = Map.get(session, :lang, :id)

    case session.active_flow do
      %{flow: :register} ->
        text = Locale.t(:register_interrupted, lang)
        buttons = [
          ResponseFormatter.row([
            {Locale.t(:register_btn_resume, lang), "register/resume"},
            {Locale.t(:register_btn_restart, lang), "register/restart"}
          ])
        ]
        Sender.send(ResponseFormatter.text_with_keyboard(chat_id, text, buttons))

      _ ->
        start_flow(session, chat_id, lang)
    end
  end

  # ---- Flow steps dari FlowDispatcher ----

  # Resume — kirim ulang prompt step saat ini
  def handle_step(session, %{flow: :register} = flow, "register/resume", chat_id) do
    send_current_step(session, flow, chat_id)
  end

  # Restart dari mana saja
  def handle_step(session, %{flow: :register}, "register/restart", chat_id) do
    lang = Map.get(session, :lang, :id)
    updated = %{session | active_flow: initial_flow()}
    SessionETS.put(session.user_id, updated)
    Sender.send(ResponseFormatter.text(chat_id, Locale.t(:register_start, lang)))
  end

  # Step 1 — Validasi nama
  def handle_step(session, %{flow: :register, step: 1} = flow, input, chat_id) do
    lang = Map.get(session, :lang, :id)
    name = input |> String.split() |> Enum.map_join(" ", &String.capitalize/1)

    case validate_name(name) do
      :ok ->
        new_flow = %{flow | step: 2, data: Map.put(flow.data, "name", name)}
        SessionETS.put(session.user_id, %{session | active_flow: new_flow})
        Sender.send(ResponseFormatter.text(chat_id, Locale.t(:register_step2_username, lang)))

      {:error, _} ->
        Sender.send(ResponseFormatter.text(chat_id, Locale.t(:register_step1_name_invalid, lang)))
    end
  end

  # Step 2 — Validasi username
  def handle_step(session, %{flow: :register, step: 2} = flow, input, chat_id) do
    lang = Map.get(session, :lang, :id)
    username = String.trim(input)

    cond do
      not valid_username?(username) ->
        Sender.send(ResponseFormatter.text(chat_id, Locale.t(:register_step2_username_invalid, lang)))

      Accounts.check_username_available(username) == :taken ->
        text = Locale.t(:register_step2_username_taken, lang, %{username: username})
        Sender.send(ResponseFormatter.text(chat_id, text))

      true ->
        new_flow = %{flow | step: 3, data: Map.put(flow.data, "username", username)}
        SessionETS.put(session.user_id, %{session | active_flow: new_flow})
        text = Locale.t(:register_step3_email, lang)
        buttons = [ResponseFormatter.row([{Locale.t(:register_btn_skip, lang), "register/skip_email"}])]
        Sender.send(ResponseFormatter.text_with_keyboard(chat_id, text, buttons))
    end
  end

  # Step 3 — Skip email
  def handle_step(session, %{flow: :register, step: 3} = flow, "register/skip_email", chat_id) do
    lang = Map.get(session, :lang, :id)
    new_flow = %{flow | step: 4, data: Map.put(flow.data, "email", nil)}
    SessionETS.put(session.user_id, %{session | active_flow: new_flow})
    Sender.send(ResponseFormatter.text(chat_id, Locale.t(:register_step4_location, lang)))
  end

  # Step 3 — Input email
  def handle_step(session, %{flow: :register, step: 3} = flow, input, chat_id) do
    lang = Map.get(session, :lang, :id)

    if valid_email?(input) do
      new_flow = %{flow | step: 4, data: Map.put(flow.data, "email", input)}
      SessionETS.put(session.user_id, %{session | active_flow: new_flow})
      Sender.send(ResponseFormatter.text(chat_id, Locale.t(:register_step4_location, lang)))
    else
      text = Locale.t(:register_step3_email_invalid, lang)
      buttons = [ResponseFormatter.row([{Locale.t(:register_btn_skip, lang), "register/skip_email"}])]
      Sender.send(ResponseFormatter.text_with_keyboard(chat_id, text, buttons))
    end
  end

  # Step 4 — Lokasi
  def handle_step(session, %{flow: :register, step: 4} = flow, input, chat_id) do
    lang = Map.get(session, :lang, :id)

    case LocationParser.parse(input) do
      {:ok, coords} ->
        label = build_location_label(input)
        loc = %{"lat" => coords.lat, "lng" => coords.lng, "label" => label}
        new_flow = %{flow | step: 5, data: Map.put(flow.data, "location", loc)}
        updated = %{session | active_flow: new_flow}
        SessionETS.put(session.user_id, updated)
        send_confirmation(updated, chat_id, lang)

      {:error, _} ->
        Sender.send(ResponseFormatter.text(chat_id, Locale.t(:register_step4_location_invalid, lang)))
    end
  end

  # Step 5 — Simpan ke DB
  def handle_step(session, %{flow: :register, step: 5} = flow, "register/save", chat_id) do
    lang = Map.get(session, :lang, :id)
    data = flow.data

    with {:ok, user} <-
           Accounts.register_user(%{
             name: data["name"],
             username: data["username"],
             email: data["email"],
             lang: to_string(lang)
           }),
         {:ok, _loc} <-
           Accounts.add_location(user.id, %{
             label: data["location"]["label"],
             coordinates: %Geo.Point{
               coordinates: {data["location"]["lng"], data["location"]["lat"]},
               srid: 4326
             },
             duration_type: "permanent",
             is_active: true
           }),
         {:ok, ci} <- Accounts.upsert_channel_identity("telegram", to_string(chat_id)),
         {:ok, _ci} <- Accounts.link_channel_identity(ci.id, user.id) do
      # Hapus guest session, hydrate session terdaftar
      SessionETS.delete(session.user_id)
      {:ok, new_session} = Hydrator.hydrate(user.id)

      Sender.send(
        ResponseFormatter.text(chat_id, Locale.t(:register_success, lang, %{name: data["name"]}))
      )

      TrenurangAdapter.Handlers.HomeHandler.handle(new_session, chat_id)
    else
      {:error, %Ecto.Changeset{} = cs} ->
        Logger.error("[RegisterHandler] Gagal simpan: #{inspect(cs.errors)}")
        Sender.send(ResponseFormatter.text(chat_id, Locale.t(:common_error, lang)))

      {:error, reason} ->
        Logger.error("[RegisterHandler] Error: #{inspect(reason)}")
        Sender.send(ResponseFormatter.text(chat_id, Locale.t(:common_error, lang)))
    end
  end

  # Fallback step tidak dikenal
  def handle_step(session, _flow, _input, chat_id) do
    lang = Map.get(session, :lang, :id)
    Sender.send(ResponseFormatter.text(chat_id, Locale.t(:common_error, lang)))
  end

  # ---- Private ----

  defp start_flow(session, chat_id, lang) do
    updated = %{session | active_flow: initial_flow()}
    SessionETS.put(session.user_id, updated)
    Sender.send(ResponseFormatter.text(chat_id, Locale.t(:register_start, lang)))
  end

  defp initial_flow do
    %{flow: :register, step: 1, data: %{"name" => nil, "username" => nil, "email" => nil, "location" => nil}}
  end

  defp send_current_step(session, flow, chat_id) do
    lang = Map.get(session, :lang, :id)

    case flow.step do
      1 -> Sender.send(ResponseFormatter.text(chat_id, Locale.t(:register_start, lang)))
      2 -> Sender.send(ResponseFormatter.text(chat_id, Locale.t(:register_step2_username, lang)))
      3 ->
        text = Locale.t(:register_step3_email, lang)
        buttons = [ResponseFormatter.row([{Locale.t(:register_btn_skip, lang), "register/skip_email"}])]
        Sender.send(ResponseFormatter.text_with_keyboard(chat_id, text, buttons))
      4 -> Sender.send(ResponseFormatter.text(chat_id, Locale.t(:register_step4_location, lang)))
      5 -> send_confirmation(session, chat_id, lang)
      _ -> Sender.send(ResponseFormatter.text(chat_id, Locale.t(:common_error, lang)))
    end
  end

  defp send_confirmation(session, chat_id, lang) do
    data = session.active_flow.data
    text = Locale.t(:register_step5_confirm, lang, %{
      name: data["name"],
      username: data["username"],
      email: data["email"] || "-",
      location: get_in(data, ["location", "label"]) || "-"
    })
    buttons = [
      ResponseFormatter.row([
        {Locale.t(:register_btn_save, lang), "register/save"},
        {Locale.t(:register_btn_restart, lang), "register/restart"}
      ])
    ]
    Sender.send(ResponseFormatter.text_with_keyboard(chat_id, text, buttons))
  end

  defp build_location_label(input) do
    cond do
      String.starts_with?(input, "http") -> "Dari Maps"
      String.match?(input, ~r/^-?\d+\.?\d*,-?\d+\.?\d*$/) -> "Koordinat GPS"
      true -> input |> String.split() |> Enum.map_join(" ", &String.capitalize/1)
    end
  end

  defp validate_name(name) do
    words = String.split(name)
    lower = String.downcase(name)

    cond do
      String.length(name) < 2 -> {:error, :too_short}
      String.length(name) > 30 -> {:error, :too_long}
      length(words) > 3 -> {:error, :too_many_words}
      lower in @reserved_names -> {:error, :reserved}
      String.match?(name, ~r/[@\/\.]/) -> {:error, :invalid_chars}
      not String.match?(name, ~r/[a-zA-ZÀ-ÿ]/u) -> {:error, :no_letters}
      true -> :ok
    end
  end

  defp valid_username?(u) do
    String.match?(u, @username_regex) and not String.contains?(u, "__")
  end

  defp valid_email?(email) do
    String.match?(email, ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/)
  end
end
