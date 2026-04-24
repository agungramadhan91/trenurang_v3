defmodule TrenurangCore.Context.Relation do
  @moduledoc """
  Context untuk manajemen relasi B2B antar toko.
  Relasi bersifat permanen — tidak ada status field.
  """

  import Ecto.Query
  alias TrenurangCore.Repo
  alias TrenurangCore.Schema.{StoreRelation, StoreRelationSettlement}

  @code_chars ~c"ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
  @code_length 6

  @doc """
  Buat relasi B2B baru antara dua toko.
  Cek duplikat: satu pasang toko hanya boleh punya satu relasi per type.
  """
  def create_relation(supplier_id, receiver_id, type) do
    if relation_exists?(supplier_id, receiver_id, type) do
      {:error, :already_exists}
    else
      code = generate_unique_code()

      %StoreRelation{}
      |> StoreRelation.changeset(%{
        supplier_id: supplier_id,
        receiver_id: receiver_id,
        type:        type,
        code:        code
      })
      |> Repo.insert()
    end
  end

  @doc "Get relasi by ID. Nil jika tidak ada."
  def get_relation(id), do: Repo.get(StoreRelation, id)

  @doc "Get relasi by kode partner. Nil jika tidak ada."
  def get_relation_by_code(code) when is_binary(code) do
    Repo.get_by(StoreRelation, code: String.upcase(code))
  end

  @doc "List semua relasi di mana toko berperan sebagai supplier atau receiver."
  def list_relations_by_store(store_id) do
    from(r in StoreRelation,
      where: r.supplier_id == ^store_id or r.receiver_id == ^store_id,
      order_by: [desc: r.inserted_at]
    )
    |> Repo.all()
  end

  @doc "Update teks agreement relasi (setelah kedua pihak konfirmasi chat)."
  def update_agreement(%StoreRelation{} = relation, agreement) when is_binary(agreement) do
    relation
    |> StoreRelation.changeset(%{agreement: agreement})
    |> Repo.update()
  end

  @doc "Tambah settlement ke relasi."
  def add_settlement(relation_id, attrs) do
    %StoreRelationSettlement{}
    |> StoreRelationSettlement.changeset(Map.put(attrs, :relation_id, relation_id))
    |> Repo.insert()
  end

  @doc "List semua settlement milik relasi."
  def list_settlements(relation_id) do
    from(s in StoreRelationSettlement,
      where: s.relation_id == ^relation_id,
      order_by: [desc: s.inserted_at]
    )
    |> Repo.all()
  end

  # ---- Private ----

  defp relation_exists?(supplier_id, receiver_id, type) do
    from(r in StoreRelation,
      where:
        r.type == ^type and
        ((r.supplier_id == ^supplier_id and r.receiver_id == ^receiver_id) or
         (r.supplier_id == ^receiver_id and r.receiver_id == ^supplier_id))
    )
    |> Repo.exists?()
  end

  defp generate_unique_code do
    Stream.repeatedly(&random_code/0)
    |> Stream.reject(&code_taken?/1)
    |> Enum.take(1)
    |> hd()
  end

  defp random_code do
    1..@code_length
    |> Enum.map(fn _ -> Enum.random(@code_chars) end)
    |> List.to_string()
  end

  defp code_taken?(code) do
    Repo.exists?(from r in StoreRelation, where: r.code == ^code)
  end
end
