defmodule TrenurangCore.Repo do
  use Ecto.Repo,
    otp_app: :trenurang_core,
    adapter: Ecto.Adapters.Postgres
end
