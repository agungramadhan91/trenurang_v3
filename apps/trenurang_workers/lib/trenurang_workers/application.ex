defmodule TrenurangWorkers.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Oban, Application.fetch_env!(:trenurang_core, Oban)}
    ]

    opts = [strategy: :one_for_one, name: TrenurangWorkers.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
