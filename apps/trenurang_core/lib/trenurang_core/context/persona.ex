defmodule TrenurangCore.Context.Persona do
  @moduledoc """
  Context untuk persona management.

  Persona adalah data ekonomi user/toko yang memungkinkan matching engine bekerja aktif.
  Completeness score dihitung on-the-fly — tidak disimpan di DB.

  User persona: 4 field utama (roles, needs, skills, budget_range)
  Store persona: 4 field utama (supply_needs, capacity, target_customer, expansion_needs)

  Consent flag (user_persona.persona_consent) wajib true sebelum PersonaPromptWorker
  boleh mengirim pertanyaan. Jika false, tidak ada prompt persona.
  """

  alias TrenurangCore.Repo
  alias TrenurangCore.Schema.{UserPersona, StorePersona}

  # Field utama yang dihitung untuk completeness
  @user_persona_fields  [:roles, :needs, :skills, :budget_range]
  @store_persona_fields [:supply_needs, :capacity, :target_customer, :expansion_needs]

  # ---- Read ----

  @doc "Ambil user persona. Return nil jika belum ada."
  def get_user_persona(user_id), do: Repo.get_by(UserPersona, user_id: user_id)

  @doc "Ambil store persona. Return nil jika belum ada."
  def get_store_persona(store_id), do: Repo.get_by(StorePersona, store_id: store_id)

  # ---- Write ----

  @doc """
  Upsert user persona.
  Jika belum ada → insert. Jika sudah ada → merge attrs ke record existing.
  """
  def upsert_user_persona(user_id, attrs) do
    case get_user_persona(user_id) do
      nil ->
        %UserPersona{}
        |> UserPersona.changeset(Map.merge(attrs, %{user_id: user_id}))
        |> Repo.insert()

      existing ->
        existing
        |> UserPersona.changeset(attrs)
        |> Repo.update()
    end
  end

  @doc """
  Upsert store persona.
  Jika belum ada → insert. Jika sudah ada → merge attrs ke record existing.
  """
  def upsert_store_persona(store_id, attrs) do
    case get_store_persona(store_id) do
      nil ->
        %StorePersona{}
        |> StorePersona.changeset(Map.merge(attrs, %{store_id: store_id}))
        |> Repo.insert()

      existing ->
        existing
        |> StorePersona.changeset(attrs)
        |> Repo.update()
    end
  end

  # ---- Consent ----

  @doc """
  Set persona_consent untuk user.
  false = tidak ada prompt persona dari PersonaPromptWorker.
  """
  def set_consent(user_id, consent) when is_boolean(consent) do
    case get_user_persona(user_id) do
      nil ->
        # Buat record minimal dengan consent saja
        %UserPersona{}
        |> UserPersona.changeset(%{user_id: user_id, persona_consent: consent})
        |> Repo.insert()

      existing ->
        existing
        |> UserPersona.changeset(%{persona_consent: consent})
        |> Repo.update()
    end
  end

  # ---- Prompted fields ----

  @doc """
  Tambah field ke prompted_fields (tidak ditanya ulang oleh PersonaPromptWorker).
  Idempotent — tidak akan duplikat field yang sama.
  """
  def mark_user_prompted(user_id, field) when is_binary(field) do
    case get_user_persona(user_id) do
      nil -> {:error, :not_found}
      persona ->
        updated = persona.prompted_fields |> Enum.uniq() |> then(fn list ->
          if field in list, do: list, else: list ++ [field]
        end)
        persona
        |> UserPersona.changeset(%{prompted_fields: updated})
        |> Repo.update()
    end
  end

  @doc """
  Tambah field ke prompted_fields store persona.
  """
  def mark_store_prompted(store_id, field) when is_binary(field) do
    case get_store_persona(store_id) do
      nil -> {:error, :not_found}
      persona ->
        updated = persona.prompted_fields |> Enum.uniq() |> then(fn list ->
          if field in list, do: list, else: list ++ [field]
        end)
        persona
        |> StorePersona.changeset(%{prompted_fields: updated})
        |> Repo.update()
    end
  end

  # ---- Completeness ----

  @doc """
  Hitung completeness score user persona (0.0–1.0).
  Dihitung on-the-fly dari 4 field utama: roles, needs, skills, budget_range.
  """
  def user_completeness(%UserPersona{} = persona) do
    filled =
      @user_persona_fields
      |> Enum.count(fn field -> field_filled?(Map.get(persona, field)) end)

    filled / length(@user_persona_fields)
  end

  def user_completeness(nil), do: 0.0

  @doc """
  Hitung completeness score store persona (0.0–1.0).
  Dihitung on-the-fly dari 4 field utama: supply_needs, capacity, target_customer, expansion_needs.
  """
  def store_completeness(%StorePersona{} = persona) do
    filled =
      @store_persona_fields
      |> Enum.count(fn field -> field_filled?(Map.get(persona, field)) end)

    filled / length(@store_persona_fields)
  end

  def store_completeness(nil), do: 0.0

  # ---- Private ----

  defp field_filled?(nil),                          do: false
  defp field_filled?([]),                           do: false
  defp field_filled?(map) when map == %{},          do: false
  defp field_filled?(list) when is_list(list),      do: length(list) > 0
  defp field_filled?(map) when is_map(map),         do: map_size(map) > 0
  defp field_filled?(str) when is_binary(str),      do: String.trim(str) != ""
  defp field_filled?(_),                            do: true
end
