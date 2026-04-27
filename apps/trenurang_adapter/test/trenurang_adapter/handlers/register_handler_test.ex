defmodule TrenurangAdapter.Handlers.RegisterHandlerTest do
  use ExUnit.Case, async: false

  alias TrenurangAdapter.Handlers.RegisterHandler
  alias TrenurangCore.Session.ETS, as: SessionETS
  alias TrenurangCore.Context.Accounts
  alias TrenurangCore.Repo

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    :ets.delete_all_objects(:trenurang_sessions)
    :ok
  end

  defp guest(chat_id, overrides \\ %{}) do
    Map.merge(
      %{
        user_id: "c#{chat_id}",
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
      },
      overrides
    )
  end

  defp flow(step, data \\ %{}) do
    %{
      flow: :register,
      step: step,
      data:
        Map.merge(
          %{"name" => nil, "username" => nil, "email" => nil, "location" => nil},
          data
        )
    }
  end

  # ---- handle/2 ----

  describe "handle/2" do
    test "mulai flow baru — set step 1 di ETS" do
      session = guest(1)
      RegisterHandler.handle(session, 1)

      updated = SessionETS.get("c1")
      assert updated.active_flow.flow == :register
      assert updated.active_flow.step == 1
    end

    test "sudah mid-register — tidak reset ETS" do
      session = guest(2, %{active_flow: flow(3, %{"name" => "Ahmad"})})
      SessionETS.put("c2", session)

      RegisterHandler.handle(session, 2)

      assert SessionETS.get("c2").active_flow.step == 3
    end
  end

  # ---- Step 1 — Nama ----

  describe "step 1 — nama" do
    setup do
      session = guest(10, %{active_flow: flow(1)})
      SessionETS.put("c10", session)
      %{session: session, flow: flow(1)}
    end

    test "nama 1 kata → step 2, nama di-title-case", %{session: s, flow: f} do
      RegisterHandler.handle_step(s, f, "ahmad", 10)
      updated = SessionETS.get("c10")
      assert updated.active_flow.step == 2
      assert updated.active_flow.data["name"] == "Ahmad"
    end

    test "nama 2 kata → step 2", %{session: s, flow: f} do
      RegisterHandler.handle_step(s, f, "ahmad ramadhan", 10)
      assert SessionETS.get("c10").active_flow.step == 2
    end

    test "nama 3 kata → step 2", %{session: s, flow: f} do
      RegisterHandler.handle_step(s, f, "ahmad bin ramadhan", 10)
      assert SessionETS.get("c10").active_flow.step == 2
    end

    test "nama 1 karakter → tetap step 1", %{session: s, flow: f} do
      RegisterHandler.handle_step(s, f, "a", 10)
      assert SessionETS.get("c10").active_flow.step == 1
    end

    test "nama > 3 kata → tetap step 1", %{session: s, flow: f} do
      RegisterHandler.handle_step(s, f, "ahmad bin hasan muda", 10)
      assert SessionETS.get("c10").active_flow.step == 1
    end

    test "nama reserved (halo) → tetap step 1", %{session: s, flow: f} do
      RegisterHandler.handle_step(s, f, "halo", 10)
      assert SessionETS.get("c10").active_flow.step == 1
    end

    test "nama dengan @ → tetap step 1", %{session: s, flow: f} do
      RegisterHandler.handle_step(s, f, "@seseorang", 10)
      assert SessionETS.get("c10").active_flow.step == 1
    end

    test "nama angka saja → tetap step 1", %{session: s, flow: f} do
      RegisterHandler.handle_step(s, f, "12345", 10)
      assert SessionETS.get("c10").active_flow.step == 1
    end
  end

  # ---- Step 2 — Username ----

  describe "step 2 — username" do
    setup do
      f = flow(2, %{"name" => "Ahmad"})
      session = guest(20, %{active_flow: f})
      SessionETS.put("c20", session)
      %{session: session, flow: f}
    end

    test "username valid → step 3", %{session: s, flow: f} do
      n = System.unique_integer([:positive])
      RegisterHandler.handle_step(s, f, "budi#{n}", 20)
      assert SessionETS.get("c20").active_flow.step == 3
    end

    test "username 2 karakter → tetap step 2", %{session: s, flow: f} do
      RegisterHandler.handle_step(s, f, "ab", 20)
      assert SessionETS.get("c20").active_flow.step == 2
    end

    test "username diawali angka → tetap step 2", %{session: s, flow: f} do
      RegisterHandler.handle_step(s, f, "1budi", 20)
      assert SessionETS.get("c20").active_flow.step == 2
    end

    test "username double underscore → tetap step 2", %{session: s, flow: f} do
      RegisterHandler.handle_step(s, f, "budi__jkt", 20)
      assert SessionETS.get("c20").active_flow.step == 2
    end

    test "username huruf besar → tetap step 2 (normalizer sudah lowercase)", %{session: s, flow: f} do
      # Normalizer lowercase dulu, tapi test ini simulasi input uppercase langsung
      RegisterHandler.handle_step(s, f, "BUDI", 20)
      assert SessionETS.get("c20").active_flow.step == 2
    end

    test "username sudah dipakai → tetap step 2", %{session: s, flow: f} do
      n = System.unique_integer([:positive])
      username = "taken#{n}"
      {:ok, _} = Accounts.register_user(%{name: "Other", username: username, lang: "id"})

      RegisterHandler.handle_step(s, f, username, 20)
      assert SessionETS.get("c20").active_flow.step == 2
    end
  end

  # ---- Step 3 — Email ----

  describe "step 3 — email" do
    setup do
      f = flow(3, %{"name" => "Ahmad", "username" => "ahmad_test"})
      session = guest(30, %{active_flow: f})
      SessionETS.put("c30", session)
      %{session: session, flow: f}
    end

    test "email valid → step 4, email tersimpan", %{session: s, flow: f} do
      RegisterHandler.handle_step(s, f, "ahmad@example.com", 30)
      updated = SessionETS.get("c30")
      assert updated.active_flow.step == 4
      assert updated.active_flow.data["email"] == "ahmad@example.com"
    end

    test "skip email → step 4, email nil", %{session: s, flow: f} do
      RegisterHandler.handle_step(s, f, "register/skip_email", 30)
      updated = SessionETS.get("c30")
      assert updated.active_flow.step == 4
      assert is_nil(updated.active_flow.data["email"])
    end

    test "email invalid → tetap step 3", %{session: s, flow: f} do
      RegisterHandler.handle_step(s, f, "bukan_email", 30)
      assert SessionETS.get("c30").active_flow.step == 3
    end

    test "email tanpa domain → tetap step 3", %{session: s, flow: f} do
      RegisterHandler.handle_step(s, f, "ahmad@", 30)
      assert SessionETS.get("c30").active_flow.step == 3
    end
  end

  # ---- Step 4 — Lokasi ----

  describe "step 4 — lokasi" do
    setup do
      f = flow(4, %{"name" => "Ahmad", "username" => "ahmad_lok", "email" => nil})
      session = guest(40, %{active_flow: f})
      SessionETS.put("c40", session)
      %{session: session, flow: f}
    end

    test "nama kota valid (jakarta) → step 5", %{session: s, flow: f} do
      RegisterHandler.handle_step(s, f, "jakarta", 40)
      updated = SessionETS.get("c40")
      assert updated.active_flow.step == 5
      assert updated.active_flow.data["location"]["lat"] != nil
    end

    test "koordinat valid → step 5", %{session: s, flow: f} do
      RegisterHandler.handle_step(s, f, "-6.175,106.827", 40)
      assert SessionETS.get("c40").active_flow.step == 5
    end

    test "lokasi tidak dikenal → tetap step 4", %{session: s, flow: f} do
      RegisterHandler.handle_step(s, f, "xyzxyzxyz tidak ada", 40)
      assert SessionETS.get("c40").active_flow.step == 4
    end
  end

  # ---- Step 5 — Simpan ----

  describe "step 5 — simpan" do
    setup do
      n = System.unique_integer([:positive])
      loc = %{"lat" => -6.2088, "lng" => 106.8456, "label" => "Jakarta"}

      f =
        flow(5, %{
          "name" => "Ahmad Test",
          "username" => "ahmad_#{n}",
          "email" => nil,
          "location" => loc
        })

      chat_id = 50_000 + n
      session = guest(chat_id, %{active_flow: f})
      SessionETS.put("c#{chat_id}", session)
      %{session: session, flow: f, chat_id: chat_id}
    end

    test "register/save → user tersimpan di DB", %{session: s, flow: f, chat_id: id} do
      RegisterHandler.handle_step(s, f, "register/save", id)
      assert Accounts.get_user_by_username(f.data["username"]) != nil
    end

    test "register/save → guest ETS key dihapus", %{session: s, flow: f, chat_id: id} do
      RegisterHandler.handle_step(s, f, "register/save", id)
      assert is_nil(SessionETS.get("c#{id}"))
    end

    test "register/save → user ETS key dibuat (hydrated)", %{session: s, flow: f, chat_id: id} do
      RegisterHandler.handle_step(s, f, "register/save", id)
      user = Accounts.get_user_by_username(f.data["username"])
      assert SessionETS.get("u##{user.id}") != nil
    end

    test "register/save → channel_identity terhubung ke user", %{session: s, flow: f, chat_id: id} do
      RegisterHandler.handle_step(s, f, "register/save", id)
      user = Accounts.get_user_by_username(f.data["username"])
      {:ok, ci} = Accounts.upsert_channel_identity("telegram", to_string(id))
      assert ci.user_id == user.id
    end

    test "register/restart dari step 5 → kembali ke step 1", %{session: s, flow: f, chat_id: id} do
      RegisterHandler.handle_step(s, f, "register/restart", id)
      assert SessionETS.get("c#{id}").active_flow.step == 1
    end
  end

  # ---- Resume & Restart ----

  describe "resume dan restart" do
    test "register/resume → tidak ubah step di ETS" do
      f = flow(3, %{"name" => "Ahmad", "username" => "ahmad_r"})
      session = guest(60, %{active_flow: f})
      SessionETS.put("c60", session)

      RegisterHandler.handle_step(session, f, "register/resume", 60)
      assert SessionETS.get("c60").active_flow.step == 3
    end

    test "register/restart dari tengah flow → reset ke step 1" do
      f = flow(4, %{"name" => "Ahmad", "username" => "ahmad_r", "email" => nil})
      session = guest(61, %{active_flow: f})
      SessionETS.put("c61", session)

      RegisterHandler.handle_step(session, f, "register/restart", 61)
      assert SessionETS.get("c61").active_flow.step == 1
    end
  end
end
