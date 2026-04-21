defmodule TrenurangCore.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      TrenurangCore.Repo,
      TrenurangCore.Session.ETSServer
    ]

    opts = [strategy: :one_for_one, name: TrenurangCore.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
