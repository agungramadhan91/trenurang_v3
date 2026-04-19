import Config

config :trenurang_core, TrenurangCore.Repo,
  username: "postgres",
  password: "",
  hostname: "localhost",
  database: "trenurang_test",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

config :trenurang_adapter,
  telegram_bot_token: "test_token"

config :trenurang_intelligence,
  groq_api_key: "test_key"

config :trenurang_core, Oban, testing: :inline
