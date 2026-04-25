defmodule TrenurangAdapter.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      [{Finch, name: TrenurangAdapter.Finch}] ++ receiver_children()

    opts = [strategy: :one_for_one, name: TrenurangAdapter.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp receiver_children do
    if Application.get_env(:trenurang_adapter, :start_receiver, true) do
      [receiver_module()]
    else
      []
    end
  end

  defp receiver_module do
    case Application.get_env(:trenurang_adapter, :work_mode, :polling) do
      :webhook -> TrenurangAdapter.Telegram.WebhookReceiver
      _        -> TrenurangAdapter.Telegram.PollingReceiver
    end
  end
end
