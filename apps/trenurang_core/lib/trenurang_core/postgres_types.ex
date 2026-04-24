Postgrex.Types.define(
  TrenurangCore.PostgresTypes,
  [Geo.PostGIS.Extension] ++ Ecto.Adapters.Postgres.extensions(),
  []
)
