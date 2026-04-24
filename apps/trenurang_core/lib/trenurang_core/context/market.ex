defmodule TrenurangCore.Context.Market do
  @moduledoc """
  Context untuk discovery dan browse: cari toko dan produk.
  """

  import Ecto.Query
  alias TrenurangCore.Repo
  alias TrenurangCore.Schema.{Store, StoreLocation, Product}

  @default_radius_m 5_000  # 5 km

  @doc """
  Browse toko aktif dalam radius dari koordinat user.
  coords: %Geo.Point{} — radius_m: integer (default 5000m)
  Return: [Store] diurutkan dari terdekat.
  """
  def browse_stores(%Geo.Point{} = coords, radius_m \\ @default_radius_m) do
    from(sl in StoreLocation,
      join: s in assoc(sl, :store),
      where: s.status == "active" and sl.is_active == true,
      where: fragment(
        "ST_DWithin(?::geography, ?::geography, ?)",
        sl.coordinates, ^coords, ^radius_m
      ),
      order_by: fragment(
        "ST_Distance(?::geography, ?::geography)",
        sl.coordinates, ^coords
      ),
      distinct: s.id,
      select: s
    )
    |> Repo.all()
  end

  @doc """
  Cari toko berdasarkan nama atau storename (case-insensitive).
  Return: [Store]
  """
  def find_stores(query) when is_binary(query) do
    pattern = "%#{String.downcase(query)}%"

    from(s in Store,
      where: s.status == "active",
      where:
        fragment("lower(?) LIKE ?", s.name, ^pattern) or
        fragment("lower(?) LIKE ?", s.storename, ^pattern),
      order_by: [asc: s.name]
    )
    |> Repo.all()
  end

  @doc """
  Cari produk berdasarkan nama (case-insensitive).
  Return: [Product] dengan store ter-preload.
  """
  def find_products(query) when is_binary(query) do
    pattern = "%#{String.downcase(query)}%"

    from(p in Product,
      join: s in assoc(p, :store),
      where: p.status == "active" and s.status == "active",
      where: fragment("lower(?) LIKE ?", p.name, ^pattern),
      order_by: [asc: p.name],
      preload: [:store]
    )
    |> Repo.all()
  end

  @doc "Get toko by ID. Nil jika tidak ada."
  def get_store(id), do: Repo.get(Store, id)

  @doc "Get toko by storename. Nil jika tidak ada."
  def get_store_by_storename(storename), do: Repo.get_by(Store, storename: storename)

  @doc "List semua produk aktif milik toko."
  def list_store_products(store_id) do
    from(p in Product,
      where: p.store_id == ^store_id and p.status == "active",
      order_by: [asc: p.name]
    )
    |> Repo.all()
  end
end
