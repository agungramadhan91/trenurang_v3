defmodule TrenurangCore.Repo.Migrations.AlterStorePersonaAddPersonaFields do
  use Ecto.Migration

  def change do
    alter table(:store_persona) do
      add :supply_needs,    {:array, :map}, default: []
      add :capacity,        :map, default: %{}
      add :target_customer, :map, default: %{}
      add :expansion_needs, {:array, :map}, default: []
      add :prompted_fields, {:array, :string}, default: []
    end
  end
end
