defmodule TrenurangAdapter.Telegram.Receiver do
  @moduledoc """
  Telegex handler — polling mode untuk dev, webhook mode untuk prod.

  Dipilih via config :trenurang_adapter, work_mode: :polling | :webhook
  di application.ex supervision tree.
  """
end

defmodule TrenurangAdapter.Telegram.PollingReceiver do
  @moduledoc "Telegex polling handler — dev only."
  use Telegex.Polling.GenHandler

  @impl true
  def on_boot do
    {:ok, true} = Telegex.delete_webhook()
    %Telegex.Polling.Config{}
  end

  @impl true
  def on_update(update) do
    TrenurangAdapter.Telegram.UpdateHandler.handle(update)
    :ok
  end
end

defmodule TrenurangAdapter.Telegram.WebhookReceiver do
  @moduledoc "Telegex webhook handler — production."
  use Telegex.Hook.GenHandler

  @impl true
  def on_boot do
    token = Application.get_env(:trenurang_adapter, :telegram_bot_token, "")
    webhook_url = Application.get_env(:trenurang_adapter, :webhook_url, "")

    {:ok, true} = Telegex.delete_webhook()
    {:ok, true} = Telegex.set_webhook(webhook_url, secret_token: token)

    %Telegex.Hook.Config{server_port: 4000}
  end

  @impl true
  def on_update(update) do
    TrenurangAdapter.Telegram.UpdateHandler.handle(update)
    :ok
  end
end
