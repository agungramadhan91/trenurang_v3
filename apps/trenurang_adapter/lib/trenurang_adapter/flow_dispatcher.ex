defmodule TrenurangAdapter.FlowDispatcher do
  @moduledoc """
  Route active_flow step ke handler yang tepat.

  Dipanggil dari update_handler saat session punya active_flow aktif.
  Setiap flow name di-dispatch ke handler yang bertanggung jawab.
  """

  alias TrenurangAdapter.Handlers

  @spec dispatch(map(), map(), String.t(), integer()) :: :ok
  def dispatch(session, %{flow: :register} = flow, input, chat_id) do
    Handlers.RegisterHandler.handle_step(session, flow, input, chat_id)
  end

  def dispatch(_session, _flow, _input, _chat_id), do: :ok
end
