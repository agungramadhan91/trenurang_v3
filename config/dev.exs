import Config

config :trenurang_core, TrenurangCore.Repo,
  username: System.get_env("DB_USERNAME", "postgres"),
  password: System.get_env("DB_PASSWORD", ""),
  hostname: System.get_env("DB_HOST", "localhost"),
  database: System.get_env("DB_NAME", "trenurang_dev"),
  types: TrenurangCore.PostgresTypes,
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

config :trenurang_adapter,
  telegram_bot_token: System.get_env("TELEGRAM_BOT_TOKEN", "")

config :telegex, token: System.get_env("TELEGRAM_BOT_TOKEN", "")

config :trenurang_intelligence,
  groq_api_key: System.get_env("GROQ_API_KEY", "")

config :trenurang_adapter, work_mode: :polling
