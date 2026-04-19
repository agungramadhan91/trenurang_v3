defmodule TrenurangCore.Repo.Migrations.FixFkColumnNames do
  use Ecto.Migration

  def change do
    rename table(:disputes), :raised_by, to: :raised_by_id
    rename table(:store_order_payment), :send_to, to: :send_to_id
  end
end
