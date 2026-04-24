defmodule TrenurangCore.Context.Chat do
  @moduledoc """
  Context untuk chat relay dan privacy control.

  B2C: buyer memakai alias per order, identitas asli tersembunyi.
  B2B: identitas asli, terbuka sepenuhnya (L4).
  Seller hanya bisa mulai chat ke buyer yang punya completed transaction.
  """

  import Ecto.Query
  alias TrenurangCore.Repo
  alias TrenurangCore.Schema.{StoreChat, ChatBlock, StoreOrder}

  # ---- Send Message ----

  @doc """
  Seller kirim pesan ke buyer (B2C).
  Validasi: harus ada completed transaction antara seller dan buyer.
  Validasi: buyer tidak boleh punya block aktif ke seller ini.
  """
  def send_b2c_message(seller_user_id, buyer_user_id, store_id, message) do
    with :ok <- check_completed_transaction(seller_user_id, buyer_user_id),
         :ok <- check_not_blocked(buyer_user_id, store_id) do
      %StoreChat{}
      |> StoreChat.changeset(%{
        sender_id:   seller_user_id,
        receiver_id: buyer_user_id,
        message:     message
      })
      |> Repo.insert()
    end
  end

  @doc """
  Kirim pesan B2B (dalam konteks store_relation).
  Tidak ada cek blokir — B2B adalah relasi yang disepakati kedua pihak.
  """
  def send_b2b_message(sender_user_id, receiver_user_id, relation_id, message) do
    %StoreChat{}
    |> StoreChat.changeset(%{
      sender_id:   sender_user_id,
      receiver_id: receiver_user_id,
      relation_id: relation_id,
      message:     message
    })
    |> Repo.insert()
  end

  @doc "List riwayat chat dalam satu order (B2C)."
  def list_order_chat(order_id) do
    from(c in StoreChat,
      where: c.order_id == ^order_id,
      order_by: [asc: c.inserted_at]
    )
    |> Repo.all()
  end

  @doc "List riwayat chat dalam satu relasi B2B."
  def list_relation_chat(relation_id) do
    from(c in StoreChat,
      where: c.relation_id == ^relation_id,
      order_by: [asc: c.inserted_at]
    )
    |> Repo.all()
  end

  # ---- Privacy / Block ----

  @doc """
  Buyer blokir toko spesifik.
  Idempotent: tidak error jika sudah diblokir sebelumnya.
  """
  def block_store(buyer_user_id, store_id) do
    case Repo.get_by(ChatBlock, user_id: buyer_user_id, blocked_store_id: store_id) do
      nil ->
        %ChatBlock{}
        |> ChatBlock.changeset(%{user_id: buyer_user_id, blocked_store_id: store_id})
        |> Repo.insert()
      existing ->
        {:ok, existing}
    end
  end

  @doc """
  Buyer aktifkan global block: blokir semua seller.
  blocked_store_id = nil → blokir global.
  Idempotent.
  """
  def block_all_sellers(buyer_user_id) do
    case Repo.one(from b in ChatBlock,
      where: b.user_id == ^buyer_user_id and is_nil(b.blocked_store_id)
    ) do
      nil ->
        %ChatBlock{}
        |> ChatBlock.changeset(%{user_id: buyer_user_id})
        |> Repo.insert()
      existing ->
        {:ok, existing}
    end
  end

  @doc "Hapus blokir toko spesifik (buyer buka blokir)."
  def unblock_store(buyer_user_id, store_id) do
    case Repo.get_by(ChatBlock, user_id: buyer_user_id, blocked_store_id: store_id) do
      nil    -> {:error, :not_found}
      block  -> Repo.delete(block)
    end
  end

  @doc "Hapus global block."
  def unblock_all_sellers(buyer_user_id) do
    case Repo.one(from b in ChatBlock,
      where: b.user_id == ^buyer_user_id and is_nil(b.blocked_store_id)
    ) do
      nil   -> {:error, :not_found}
      block -> Repo.delete(block)
    end
  end

  @doc "Cek apakah buyer memblokir toko tertentu (atau global block aktif)."
  def blocked?(buyer_user_id, store_id) do
    from(b in ChatBlock,
      where:
        b.user_id == ^buyer_user_id and
        (is_nil(b.blocked_store_id) or b.blocked_store_id == ^store_id)
    )
    |> Repo.exists?()
  end

  # ---- Private ----

  defp check_completed_transaction(seller_user_id, buyer_user_id) do
    has_completed =
      from(o in StoreOrder,
        where:
          o.seller_id == ^seller_user_id and
          o.buyer_id == ^buyer_user_id and
          o.status == "completed"
      )
      |> Repo.exists?()

    if has_completed, do: :ok, else: {:error, :no_completed_transaction}
  end

  defp check_not_blocked(buyer_user_id, store_id) do
    if blocked?(buyer_user_id, store_id),
      do: {:error, :blocked},
      else: :ok
  end
end
