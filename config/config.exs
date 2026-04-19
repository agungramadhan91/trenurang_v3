import Config

config :trenurang_core, ecto_repos: [TrenurangCore.Repo]

config :trenurang_core, Oban,
  repo: TrenurangCore.Repo,
  queues: [default: 10, mailers: 5, billing: 3]

import_config "#{config_env()}.exs"
