defmodule TrenurangCore.Context.Order do
  @moduledoc """
  Context untuk manajemen order: cart, B2C order, walk-in, dan generate kode order.
  """

  import Ecto.Query
  alias TrenurangCore.Repo
  alias TrenurangCore.Schema.{
    ProductCart, Product,
    StoreOrder, StoreOrderItem, StoreOrderPayment,
    StoreOrderCode, StoreReward, StoreTrustScore, Store
  }

  # Tier store → kapasitas kode harian
  @tier_capacity %{
    "belum_teruji"    => 50,
    "pemula_aktif"    => 75,
    "pedagang_tumbuh" => 100,
    "pedagang_andal"  => 150,
    "juragan"         => 250
  }
  @starter_boost_capacity 100
  @starter_boost_days     7
  @threshold_pct          0.50
  @code_chars             ~c"ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

  # ---- Cart ----

  @doc "Tambah produk ke keranjang. Jika sudah ada, qty diakumulasi."
  def add_to_cart(user_id, product_id, qty) do
    case Repo.get_by(ProductCart, user_id: user_id, product_id: product_id) do
      nil ->
        %ProductCart{}
        |> ProductCart.changeset(%{user_id: user_id, product_id: product_id, quantity: qty})
        |> Repo.insert()
      cart ->
        cart
        |> ProductCart.changeset(%{quantity: cart.quantity + qty})
        |> Repo.update()
    end
  end

  @doc "List isi keranjang user. Produk di-preload."
  def list_cart(user_id) do
    from(c in ProductCart,
      where: c.user_id == ^user_id,
      preload: [:product]
    )
    |> Repo.all()
  end

  @doc "Hapus semua item keranjang user."
  def clear_cart(user_id) do
    from(c in ProductCart, where: c.user_id == ^user_id)
    |> Repo.delete_all()
    :ok
  end

  # ---- B2C Order ----

  @doc """
  Buat order B2C. Atomik: order + items + payment dalam satu transaction.
  items: [%{product_id: id, qty: n, price: decimal}]
  payment_attrs: %{method: "cash"|"hutang"|"transfer"|"ewallet", ...}
  """
  def create_b2c_order(buyer_id, seller_id, items, payment_attrs)
      when is_list(items) and items != [] do
    Repo.transaction(fn ->
      order =
        %StoreOrder{}
        |> StoreOrder.changeset(%{type: "b2c", buyer_id: buyer_id, seller_id: seller_id})
        |> Repo.insert!()

      for %{product_id: pid, qty: qty, price: price} <- items do
        %StoreOrderItem{}
        |> StoreOrderItem.changeset(%{
          order_id:   order.id,
          product_id: pid,
          qty:        qty,
          price:      price
        })
        |> Repo.insert!()
      end

      payment_changeset =
        %StoreOrderPayment{}
        |> StoreOrderPayment.changeset(
          Map.merge(payment_attrs, %{order_id: order.id, send_to_id: seller_id})
        )

      case Repo.insert(payment_changeset) do
        {:ok, payment} -> {order, payment}
        {:error, cs}   -> Repo.rollback(cs)
      end
    end)
  end

  @doc "Get order by ID. Nil jika tidak ada."
  def get_order(id), do: Repo.get(StoreOrder, id)

  @doc "List order berdasarkan buyer, terbaru dulu."
  def list_orders_by_buyer(buyer_id) do
    from(o in StoreOrder,
      where: o.buyer_id == ^buyer_id,
      order_by: [desc: o.inserted_at]
    )
    |> Repo.all()
  end

  @doc "List order masuk berdasarkan seller, terbaru dulu."
  def list_orders_by_seller(seller_id) do
    from(o in StoreOrder,
      where: o.seller_id == ^seller_id,
      order_by: [desc: o.inserted_at]
    )
    |> Repo.all()
  end

  @doc "Cancel order. Hanya status pending yang bisa di-cancel."
  def cancel_order(order_id) do
    case Repo.get(StoreOrder, order_id) do
      nil ->
        {:error, :not_found}
      %StoreOrder{status: "pending"} = order ->
        order |> StoreOrder.changeset(%{status: "cancelled"}) |> Repo.update()
      _ ->
        {:error, :cannot_cancel}
    end
  end

  @doc "Update status order — dipakai internal (worker, handler)."
  def update_order_status(%StoreOrder{} = order, status) do
    order |> StoreOrder.changeset(%{status: status}) |> Repo.update()
  end

  # ---- Walk-in Code ----

  @doc """
  Lookup kode walk-in untuk toko. Return:
  - {:ok, order_code}             — valid, belum dipakai
  - {:error, :invalid_code}       — tidak ditemukan
  - {:error, :code_already_used}  — sudah dipakai
  - {:error, :code_expired}       — valid_date sudah lewat
  """
  def lookup_walkin_code(store_id, code) when is_binary(code) do
    today = Date.utc_today()

    case Repo.get_by(StoreOrderCode, store_id: store_id, code: String.upcase(code)) do
      nil ->
        {:error, :invalid_code}
      %StoreOrderCode{used_at: used_at} when not is_nil(used_at) ->
        {:error, :code_already_used}
      %StoreOrderCode{valid_date: valid_date} = record ->
        if Date.compare(valid_date, today) == :lt do
          {:error, :code_expired}
        else
          {:ok, record}
        end
    end
  end

  @doc "Tandai kode walk-in sebagai terpakai dan link ke order."
  def use_walkin_code(%StoreOrderCode{} = order_code, order_id) do
    order_code
    |> StoreOrderCode.changeset(%{
      used_at:  DateTime.utc_now() |> DateTime.truncate(:second),
      order_id: order_id
    })
    |> Repo.update()
  end

  # ---- Order Code Generation ----

  @doc """
  Generate batch kode order untuk toko.

  opts:
    - reward_id: integer | nil  — assign golden codes sesuai reward.total_codes

  Return:
  - {:ok, [map]}
  - {:error, :store_not_found}
  - {:error, :no_products}
  - {:error, :trust_score_not_found}
  - {:error, {:threshold_not_met, confirmed, total}}
  """
  def generate_order_codes(store_id, opts \\ []) do
    reward_id = Keyword.get(opts, :reward_id)
    today     = Date.utc_today()

    with {:ok, store}    <- fetch_store(store_id),
         {:ok, capacity} <- resolve_capacity(store, store_id, today),
         :ok             <- invalidate_old_codes(store_id, today),
         {:ok, codes}    <- insert_code_batch(store_id, capacity, today, reward_id) do
      {:ok, codes}
    end
  end

  # ---- Private: Generate ----

  defp fetch_store(store_id) do
    case Repo.get(Store, store_id) do
      nil   -> {:error, :store_not_found}
      store -> {:ok, store}
    end
  end

  defp resolve_capacity(store, store_id, today) do
    store_age_days = Date.diff(today, NaiveDateTime.to_date(store.inserted_at))
    within_window  = store_age_days <= @starter_boost_days
    boost_used     = already_boosted?(store_id)

    cond do
      within_window and not boost_used and has_active_products?(store_id) ->
        {:ok, @starter_boost_capacity}

      within_window and not boost_used ->
        {:error, :no_products}

      true ->
        with {:ok, tier} <- get_store_tier(store_id),
             :ok         <- check_threshold(store_id) do
          {:ok, Map.fetch!(@tier_capacity, tier)}
        end
    end
  end

  defp already_boosted?(store_id) do
    from(c in StoreOrderCode, where: c.store_id == ^store_id)
    |> Repo.exists?()
  end

  defp has_active_products?(store_id) do
    from(p in Product, where: p.store_id == ^store_id and p.status == "active")
    |> Repo.exists?()
  end

  defp get_store_tier(store_id) do
    case Repo.get_by(StoreTrustScore, store_id: store_id) do
      nil   -> {:error, :trust_score_not_found}
      score -> {:ok, score.tier}
    end
  end

  defp check_threshold(store_id) do
    latest_valid_date =
      from(c in StoreOrderCode,
        where: c.store_id == ^store_id,
        select: max(c.valid_date)
      )
      |> Repo.one()

    if is_nil(latest_valid_date) do
      :ok
    else
      total =
        from(c in StoreOrderCode,
          where: c.store_id == ^store_id and c.valid_date == ^latest_valid_date
        )
        |> Repo.aggregate(:count, :id)

      confirmed =
        from(c in StoreOrderCode,
          join: o in StoreOrder, on: c.order_id == o.id,
          where:
            c.store_id == ^store_id and
            c.valid_date == ^latest_valid_date and
            o.status == "confirmed"
        )
        |> Repo.aggregate(:count, :id)

      if total == 0 or confirmed * 1.0 / total >= @threshold_pct do
        :ok
      else
        {:error, {:threshold_not_met, confirmed, total}}
      end
    end
  end

  defp invalidate_old_codes(store_id, today) do
    yesterday = Date.add(today, -1)
    now       = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    from(c in StoreOrderCode,
      where: c.store_id == ^store_id and c.valid_date == ^today and is_nil(c.used_at)
    )
    |> Repo.update_all(set: [valid_date: yesterday, updated_at: now])

    :ok
  end

  defp insert_code_batch(store_id, capacity, today, reward_id) do
    codes  = generate_unique_codes(capacity)
    golden = if reward_id, do: pick_golden_indices(capacity, reward_id), else: MapSet.new()
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    entries =
      codes
      |> Enum.with_index()
      |> Enum.map(fn {code, idx} ->
        is_golden = MapSet.member?(golden, idx)
        %{
          store_id:    store_id,
          code:        code,
          valid_date:  today,
          is_golden:   is_golden,
          reward_id:   if(is_golden, do: reward_id, else: nil),
          inserted_at: now,
          updated_at:  now
        }
      end)

    {count, inserted} =
      Repo.insert_all(StoreOrderCode, entries,
        returning: [:id, :code, :valid_date, :is_golden, :reward_id, :store_id]
      )

    if count == capacity,
      do:   {:ok, inserted},
      else: {:error, :insert_failed}
  end

  defp generate_unique_codes(n) do
    Stream.repeatedly(&random_code/0)
    |> Stream.uniq()
    |> Enum.take(n)
  end

  defp random_code do
    1..6
    |> Enum.map(fn _ -> Enum.random(@code_chars) end)
    |> List.to_string()
  end

  defp pick_golden_indices(total, reward_id) do
    reward       = Repo.get!(StoreReward, reward_id)
    golden_count = min(reward.total_codes, total)

    0..(total - 1)
    |> Enum.to_list()
    |> Enum.take_random(golden_count)
    |> MapSet.new()
  end
end
