defmodule TrenurangCore.Context.Dispute do
  @moduledoc """
  Context untuk dispute management.

  Dispute dibuka oleh buyer atau seller terhadap lawan transaksi.
  Satu order hanya boleh punya satu dispute aktif (open/under_review).
  Saat dispute dibuka, status order berubah menjadi "disputed" secara atomik.
  Resolution dispute memicu TrustScoreWorker (di-trigger dari luar context ini).
  """

  import Ecto.Query
  alias TrenurangCore.Repo
  alias TrenurangCore.Schema.{Dispute, StoreOrder}

  # ---- Open ----

  @doc """
  Buka dispute untuk sebuah order.
  - Order harus ada dan dimiliki salah satu pihak (buyer/seller)
  - Tidak boleh ada dispute aktif (open/under_review) untuk order yang sama
  - Order berubah status ke "disputed" secara atomik dalam satu transaksi
  """
  def open_dispute(order_id, raised_by_id, against_id, reason, evidence \\ []) do
    Repo.transaction(fn ->
      order = Repo.get!(StoreOrder, order_id)

      if order.status in ["cancelled", "disputed"] do
        Repo.rollback({:invalid_order_status, order.status})
      end

      existing =
        from(d in Dispute,
          where: d.order_id == ^order_id and d.status in ["open", "under_review"]
        )
        |> Repo.one()

      if existing do
        Repo.rollback(:dispute_already_exists)
      end

      # Update order ke "disputed"
      case Repo.update(StoreOrder.changeset(order, %{status: "disputed"})) do
        {:ok, _updated_order} ->
          %Dispute{}
          |> Dispute.changeset(%{
            order_id:    order_id,
            raised_by_id: raised_by_id,
            against_id:  against_id,
            reason:      reason,
            evidence:    evidence
          })
          |> Repo.insert!()

        {:error, cs} ->
          Repo.rollback(cs)
      end
    end)
  end

  # ---- Read ----

  @doc "Ambil dispute by ID."
  def get_dispute(id), do: Repo.get(Dispute, id)

  @doc "Ambil dispute aktif untuk sebuah order (nil jika tidak ada)."
  def get_dispute_by_order(order_id) do
    from(d in Dispute,
      where: d.order_id == ^order_id,
      order_by: [desc: d.inserted_at],
      limit: 1
    )
    |> Repo.one()
  end

  @doc "List semua dispute yang diajukan oleh user."
  def list_disputes_raised_by(user_id) do
    from(d in Dispute,
      where: d.raised_by_id == ^user_id,
      order_by: [desc: d.inserted_at]
    )
    |> Repo.all()
  end

  @doc "List semua dispute yang ditujukan ke user."
  def list_disputes_against(user_id) do
    from(d in Dispute,
      where: d.against_id == ^user_id,
      order_by: [desc: d.inserted_at]
    )
    |> Repo.all()
  end

  # ---- Update ----

  @doc """
  Update status dispute ke under_review atau dismissed.
  Untuk resolve (dengan resolution text), pakai resolve_dispute/3.
  """
  def update_status(dispute_id, new_status) when new_status in ["under_review", "dismissed"] do
    case Repo.get(Dispute, dispute_id) do
      nil -> {:error, :not_found}
      dispute ->
        dispute
        |> Dispute.changeset(%{status: new_status})
        |> Repo.update()
    end
  end

  @doc """
  Resolve dispute — isi resolution text dan resolved_at.
  Status order dikembalikan ke "completed" secara atomik.
  """
  def resolve_dispute(dispute_id, resolution) do
    Repo.transaction(fn ->
      dispute = Repo.get!(Dispute, dispute_id)

      if dispute.status == "resolved" do
        Repo.rollback(:already_resolved)
      end

      {:ok, resolved} =
        dispute
        |> Dispute.changeset(%{
          status:      "resolved",
          resolution:  resolution,
          resolved_at: DateTime.utc_now() |> DateTime.truncate(:second)
        })
        |> Repo.update()

      # Kembalikan order ke completed
      order = Repo.get!(StoreOrder, dispute.order_id)
      Repo.update!(StoreOrder.changeset(order, %{status: "completed"}))

      resolved
    end)
  end

  @doc "Tambah evidence ke dispute (append, tidak replace)."
  def add_evidence(dispute_id, new_evidence) when is_list(new_evidence) do
    case Repo.get(Dispute, dispute_id) do
      nil -> {:error, :not_found}
      dispute ->
        updated_evidence = dispute.evidence ++ new_evidence
        dispute
        |> Dispute.changeset(%{evidence: updated_evidence})
        |> Repo.update()
    end
  end
end
