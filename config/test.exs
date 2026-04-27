import Config

config :trenurang_core, TrenurangCore.Repo,
  username: "postgres",
  password: System.get_env("DB_PASSWORD", ""),
  hostname: "localhost",
  database: "trenurang_test",
  types: TrenurangCore.PostgresTypes,
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10,
  log: false

config :trenurang_adapter,
  telegram_bot_token: "test_token"

config :trenurang_adapter, work_mode: :polling

config :trenurang_adapter, start_receiver: false

config :trenurang_intelligence,
  groq_api_key: "test_key"

config :trenurang_core, Oban, testing: :inline

config :telegex, token: "test_token_placeholder"

config :trenurang_adapter, :test_mode, true
