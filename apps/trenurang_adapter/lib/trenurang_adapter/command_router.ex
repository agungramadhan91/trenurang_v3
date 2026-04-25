defmodule TrenurangAdapter.CommandRouter do
  @moduledoc """
  Dispatch normalized command ke handler yang tepat.

  Input: normalized string dari Normalizer (sudah lowercase, sudah resolve alias).
  Output: dipanggil handler yang sesuai, return response tuple untuk Sender.

  Handlers belum diimplementasi (Fase 6) — sementara return {:unhandled, input}
  agar pipeline tidak crash dan bisa ditest end-to-end.
  """

  alias TrenurangAdapter.Handlers

  @spec dispatch(map(), String.t(), integer()) ::
          {:ok, term()} | {:unhandled, String.t()}
  def dispatch(session, command, chat_id) do
    case command do
      "start"          -> Handlers.StartHandler.handle(session, chat_id)
      "register"       -> Handlers.RegisterHandler.handle(session, chat_id)
      "home"           -> Handlers.HomeHandler.handle(session, chat_id)
      "profile/show"   -> Handlers.ProfileHandler.handle(session, chat_id)
      "market/browse"  -> Handlers.MarketHandler.handle(:browse, session, chat_id)
      "market/find/store"   -> Handlers.MarketHandler.handle(:find_store, session, chat_id)
      "market/find/product" -> Handlers.MarketHandler.handle(:find_product, session, chat_id)
      "store/list"     -> Handlers.StoreHandler.handle(:list, session, chat_id)
      "store/new"      -> Handlers.StoreHandler.handle(:new, session, chat_id)
      "order/walkin"   -> Handlers.WalkinHandler.handle(session, chat_id)
      "order/list"           -> Handlers.OrderHandler.handle(:list, session, chat_id)
      "order/create"         -> Handlers.OrderHandler.handle(:create, session, chat_id)
      "order/confirm-price"  -> Handlers.OrderHandler.handle(:confirm_price, session, chat_id)
      "order/cancel"         -> Handlers.OrderHandler.handle(:cancel, session, chat_id)
      "store/walkin/generate" -> Handlers.StoreHandler.handle(:walkin_generate, session, chat_id)
      "store/walkin/record"   -> Handlers.StoreHandler.handle(:walkin_record, session, chat_id)
      "cart/show"      -> Handlers.CartHandler.handle(:show, session, chat_id)
      "relation/list"  -> Handlers.RelationHandler.handle(:list, session, chat_id)
      "chat/b2c"       -> Handlers.ChatHandler.handle(:b2c, session, chat_id)
      "dispute/raise"  -> Handlers.DisputeHandler.handle(:raise, session, chat_id)
      "terms"          -> Handlers.TermsHandler.handle(session, chat_id)
      "settings"       -> Handlers.SettingsHandler.handle(:show, session, chat_id)
      "help"           -> Handlers.StartHandler.handle_help(session, chat_id)
      "about"          -> Handlers.StartHandler.handle_about(session, chat_id)
      _other           -> {:unhandled, command}
    end
  end
end
