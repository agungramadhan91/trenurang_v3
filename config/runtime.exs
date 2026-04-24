import Config

if config_env() == :prod do
  config :trenurang_core, TrenurangCore.Repo,
    url: System.fetch_env!("DATABASE_URL"),
    pool_size: String.to_integer(System.get_env("POOL_SIZE", "10")),
    ssl: true,
    ssl_opts: [verify: :verify_none]

  config :trenurang_adapter,
    telegram_bot_token: System.fetch_env!("TELEGRAM_BOT_TOKEN")

  config :trenurang_intelligence,
    groq_api_key: System.fetch_env!("GROQ_API_KEY")

  config :telegex, token: System.fetch_env!("TELEGRAM_BOT_TOKEN")
end
