defmodule TrenurangCore.Context.PersonaTest do
  use ExUnit.Case, async: false

  alias TrenurangCore.Repo
  alias TrenurangCore.Context.Persona
  alias TrenurangCore.Schema.{User, Store, UserPersona}

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  end

  # ---- Helpers ----

  defp insert_user do
    n = System.unique_integer([:positive])
    {:ok, u} =
      %User{}
      |> User.changeset(%{name: "User", username: "user#{n}", lang: "id"})
      |> Repo.insert()
    u
  end

  defp insert_store(owner_id) do
    n = System.unique_integer([:positive])
    {:ok, s} =
      %Store{}
      |> Store.changeset(%{
        owner_id:  owner_id,
        type:      "good",
        name:      "Toko #{n}",
        storename: "toko#{n}_store",
        status:    "active"
      })
      |> Repo.insert()
    s
  end

  # ---- get_user_persona/1 ----

  @tag :db
  test "get_user_persona/1 — return nil jika belum ada" do
    user = insert_user()
    assert nil == Persona.get_user_persona(user.id)
  end

  @tag :db
  test "get_user_persona/1 — return persona jika ada" do
    user = insert_user()
    {:ok, _} = Persona.upsert_user_persona(user.id, %{})
    assert %UserPersona{} = Persona.get_user_persona(user.id)
  end

  # ---- upsert_user_persona/2 ----

  @tag :db
  test "upsert_user_persona/2 — insert jika belum ada" do
    user = insert_user()
    attrs = %{roles: [%{"type" => "pencari_kerja"}], skills: ["menjahit"]}

    assert {:ok, persona} = Persona.upsert_user_persona(user.id, attrs)
    assert persona.user_id == user.id
    assert persona.roles == [%{"type" => "pencari_kerja"}]
    assert persona.skills == ["menjahit"]
  end

  @tag :db
  test "upsert_user_persona/2 — update jika sudah ada" do
    user = insert_user()
    {:ok, _} = Persona.upsert_user_persona(user.id, %{skills: ["menjahit"]})
    {:ok, updated} = Persona.upsert_user_persona(user.id, %{skills: ["menjahit", "akuntansi"]})

    assert length(updated.skills) == 2
    # Hanya satu record
    count = Repo.aggregate(UserPersona, :count, :id)
    assert count == 1
  end

  @tag :db
  test "upsert_user_persona/2 — update tidak hapus field lain" do
    user = insert_user()
    {:ok, _} = Persona.upsert_user_persona(user.id, %{
      roles:  [%{"type" => "reseller"}],
      skills: ["akuntansi"]
    })

    {:ok, updated} = Persona.upsert_user_persona(user.id, %{
      needs: [%{"category" => "bahan_baku", "description" => "tepung"}]
    })

    assert updated.roles  == [%{"type" => "reseller"}]
    assert updated.skills == ["akuntansi"]
    assert length(updated.needs) == 1
  end

  # ---- upsert_store_persona/2 ----

  @tag :db
  test "upsert_store_persona/2 — insert jika belum ada" do
    owner = insert_user()
    store = insert_store(owner.id)
    attrs = %{
      capacity: %{"current" => "100 pcs/hari", "target" => "200 pcs/hari"}
    }

    assert {:ok, persona} = Persona.upsert_store_persona(store.id, attrs)
    assert persona.store_id == store.id
    assert persona.capacity["current"] == "100 pcs/hari"
  end

  @tag :db
  test "upsert_store_persona/2 — update jika sudah ada" do
    owner = insert_user()
    store = insert_store(owner.id)
    {:ok, _} = Persona.upsert_store_persona(store.id, %{unique_partners: 2})
    {:ok, updated} = Persona.upsert_store_persona(store.id, %{
      supply_needs: [%{"type" => "bahan_baku"}]
    })
    assert length(updated.supply_needs) == 1
  end

  # ---- set_consent/2 ----

  @tag :db
  test "set_consent/2 — buat record baru jika belum ada, consent true" do
    user = insert_user()
    assert {:ok, persona} = Persona.set_consent(user.id, true)
    assert persona.persona_consent == true
  end

  @tag :db
  test "set_consent/2 — update consent jika record sudah ada" do
    user = insert_user()
    {:ok, _} = Persona.upsert_user_persona(user.id, %{persona_consent: true})
    {:ok, updated} = Persona.set_consent(user.id, false)
    assert updated.persona_consent == false
  end

  # ---- mark_user_prompted/2 ----

  @tag :db
  test "mark_user_prompted/2 — tambah field ke prompted_fields" do
    user = insert_user()
    {:ok, _} = Persona.upsert_user_persona(user.id, %{})

    assert {:ok, updated} = Persona.mark_user_prompted(user.id, "roles")
    assert "roles" in updated.prompted_fields
  end

  @tag :db
  test "mark_user_prompted/2 — idempotent, tidak duplikat field" do
    user = insert_user()
    {:ok, _} = Persona.upsert_user_persona(user.id, %{})

    {:ok, _} = Persona.mark_user_prompted(user.id, "roles")
    {:ok, updated} = Persona.mark_user_prompted(user.id, "roles")
    assert Enum.count(updated.prompted_fields, &(&1 == "roles")) == 1
  end

  @tag :db
  test "mark_user_prompted/2 — return :not_found jika persona belum ada" do
    user = insert_user()
    assert {:error, :not_found} = Persona.mark_user_prompted(user.id, "roles")
  end

  # ---- mark_store_prompted/2 ----

  @tag :db
  test "mark_store_prompted/2 — tambah field ke prompted_fields store" do
    owner = insert_user()
    store = insert_store(owner.id)
    {:ok, _} = Persona.upsert_store_persona(store.id, %{})

    assert {:ok, updated} = Persona.mark_store_prompted(store.id, "supply_needs")
    assert "supply_needs" in updated.prompted_fields
  end

  # ---- user_completeness/1 ----

  test "user_completeness/1 — 0.0 jika persona nil" do
    assert Persona.user_completeness(nil) == 0.0
  end

  @tag :db
  test "user_completeness/1 — 0.0 jika semua field kosong" do
    user = insert_user()
    {:ok, persona} = Persona.upsert_user_persona(user.id, %{})
    assert Persona.user_completeness(persona) == 0.0
  end

  @tag :db
  test "user_completeness/1 — 0.5 jika 2 dari 4 field terisi" do
    user = insert_user()
    {:ok, persona} = Persona.upsert_user_persona(user.id, %{
      roles:  [%{"type" => "reseller"}],
      skills: ["menjahit"]
    })
    assert Persona.user_completeness(persona) == 0.5
  end

  @tag :db
  test "user_completeness/1 — 1.0 jika semua 4 field terisi" do
    user = insert_user()
    {:ok, persona} = Persona.upsert_user_persona(user.id, %{
      roles:       [%{"type" => "reseller"}],
      needs:       [%{"category" => "bahan_baku", "description" => "tepung"}],
      skills:      ["menjahit"],
      budget_range: %{"min" => 500_000, "max" => 2_000_000}
    })
    assert Persona.user_completeness(persona) == 1.0
  end

  # ---- store_completeness/1 ----

  test "store_completeness/1 — 0.0 jika persona nil" do
    assert Persona.store_completeness(nil) == 0.0
  end

  @tag :db
  test "store_completeness/1 — 0.25 jika 1 dari 4 field terisi" do
    owner = insert_user()
    store = insert_store(owner.id)
    {:ok, persona} = Persona.upsert_store_persona(store.id, %{
      capacity: %{"current" => "100 pcs/hari"}
    })
    assert Persona.store_completeness(persona) == 0.25
  end

  @tag :db
  test "store_completeness/1 — 1.0 jika semua 4 field terisi" do
    owner = insert_user()
    store = insert_store(owner.id)
    {:ok, persona} = Persona.upsert_store_persona(store.id, %{
      supply_needs:    [%{"type" => "bahan_baku", "description" => "tepung"}],
      capacity:        %{"current" => "100 pcs/hari", "target" => "200 pcs/hari"},
      target_customer: %{"segment" => "ibu rumah tangga", "area" => "jakarta selatan"},
      expansion_needs: [%{"type" => "reseller", "description" => "butuh 5 reseller"}]
    })
    assert Persona.store_completeness(persona) == 1.0
  end
end
