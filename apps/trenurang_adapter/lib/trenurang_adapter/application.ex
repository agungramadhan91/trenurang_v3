defmodule TrenurangAdapter.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Finch, name: TrenurangAdapter.Finch}
    ]

    opts = [strategy: :one_for_one, name: TrenurangAdapter.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
