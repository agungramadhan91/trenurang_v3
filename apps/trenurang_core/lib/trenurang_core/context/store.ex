defmodule TrenurangCore.Context.Store do
  @moduledoc """
  Context untuk manajemen toko: buat toko, kelola lokasi toko, dan kelola produk.
  """

  import Ecto.Query
  alias TrenurangCore.Repo
  alias TrenurangCore.Schema.{Store, StoreLocation, Product}

  # ---- Store ----

  @doc "Buat toko baru untuk owner_id."
  def create_store(owner_id, attrs) do
    %Store{}
    |> Store.changeset(Map.put(attrs, :owner_id, owner_id))
    |> Repo.insert()
    |> translate_unique_errors()
  end

  @doc "List semua toko milik user (aktif dan tidak aktif)."
  def list_stores_by_owner(owner_id) do
    from(s in Store, where: s.owner_id == ^owner_id, order_by: [asc: s.name])
    |> Repo.all()
  end

  @doc "Update data toko (name, type, status, dll)."
  def update_store(%Store{} = store, attrs) do
    store
    |> Store.changeset(attrs)
    |> Repo.update()
    |> translate_unique_errors()
  end

  @doc "Nonaktifkan toko (soft delete)."
  def deactivate_store(%Store{} = store) do
    store
    |> Store.changeset(%{status: "inactive"})
    |> Repo.update()
  end

  # ---- Store Location ----

  @doc "Tambah lokasi toko ke DB."
  def add_store_location(store_id, attrs) do
    %StoreLocation{}
    |> StoreLocation.changeset(Map.put(attrs, :store_id, store_id))
    |> Repo.insert()
  end

  @doc "List semua lokasi aktif milik toko."
  def list_store_locations(store_id) do
    from(l in StoreLocation,
      where: l.store_id == ^store_id and l.is_active == true,
      order_by: [asc: l.inserted_at]
    )
    |> Repo.all()
  end

  @doc "Nonaktifkan lokasi toko. Cek ownership via store_id."
  def deactivate_store_location(loc_id, store_id) do
    case Repo.get_by(StoreLocation, id: loc_id, store_id: store_id) do
      nil -> {:error, :not_found}
      loc -> loc |> StoreLocation.changeset(%{is_active: false}) |> Repo.update()
    end
  end

  # ---- Product ----

  @doc "Tambah produk baru ke toko."
  def add_product(store_id, attrs) do
    %Product{}
    |> Product.changeset(Map.put(attrs, :store_id, store_id))
    |> Repo.insert()
  end

  @doc """
  List semua produk milik toko — untuk seller (aktif + nonaktif).
  Gunakan Market.list_store_products/1 untuk buyer view (aktif saja).
  """
  def list_products(store_id) do
    from(p in Product,
      where: p.store_id == ^store_id,
      order_by: [asc: p.name]
    )
    |> Repo.all()
  end

  @doc "Update data produk."
  def update_product(%Product{} = product, attrs) do
    product
    |> Product.changeset(attrs)
    |> Repo.update()
  end

  @doc "Nonaktifkan produk (soft delete). Cek ownership via store_id."
  def deactivate_product(product_id, store_id) do
    case Repo.get_by(Product, id: product_id, store_id: store_id) do
      nil     -> {:error, :not_found}
      product -> product |> Product.changeset(%{status: "inactive"}) |> Repo.update()
    end
  end

  # ---- Private ----

  defp translate_unique_errors({:ok, _} = result), do: result

  defp translate_unique_errors({:error, changeset}) do
    if unique_error?(changeset, :storename),
      do: {:error, :storename_taken},
      else: {:error, changeset}
  end

  defp unique_error?(changeset, field) do
    Enum.any?(changeset.errors, fn
      {^field, {_, [constraint: :unique, constraint_name: _]}} -> true
      _                                                         -> false
    end)
  end
end
