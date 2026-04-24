defmodule TrenurangCore.Locale do
  @moduledoc """
  Locale module — translate key dengan lang + params interpolation.

  Usage:
    Locale.t(:start_welcome_new, :id)
    Locale.t(:start_welcome_back, :en, %{name: "Budi"})

  Fallback chain:
    - Lang tidak dikenal → :en
    - Key tidak ada di lang → :id
    - Key tidak ada di :id → key sebagai string (failsafe)
  """

  @supported_langs [:id, :en, :zh, :de, :ar, :ru]

  @langs (for lang <- @supported_langs, into: %{} do
    path = Path.join([__DIR__, "languages", "#{lang}.exs"])
    @external_resource path
    {lang, path |> Code.eval_file() |> elem(0)}
  end)

  @doc """
  Translate key ke bahasa yang diminta.
  params adalah map untuk interpolasi, contoh: %{name: "Budi"}
  """
  @spec t(atom(), atom(), map()) :: String.t()
  def t(key, lang, params \\ %{}) do
    lang = normalize_lang(lang)
    raw = lookup(key, lang)
    interpolate(raw, params)
  end

  # --- Private ---

  defp normalize_lang(lang) when lang in @supported_langs, do: lang
  defp normalize_lang(_), do: :en

  defp lookup(key, lang) do
    translations = Map.get(@langs, lang, %{})

    case Map.get(translations, key) do
      nil -> fallback(key, lang)
      val -> val
    end
  end

  defp fallback(key, :id) do
    # Key tidak ada di :id — kembalikan key sebagai string
    key |> Atom.to_string() |> String.replace("_", " ")
  end

  defp fallback(key, lang) when lang in [:zh, :de, :ar, :ru] do
    # Stub lang → fallback ke :en dulu, lalu :id
    lookup(key, :en)
  end

  defp fallback(key, :en) do
    # Key tidak ada di :en → fallback ke :id
    lookup(key, :id)
  end

  defp interpolate(text, params) when map_size(params) == 0, do: text

  defp interpolate(text, params) do
    Enum.reduce(params, text, fn {k, v}, acc ->
      String.replace(acc, "%{#{k}}", to_string(v))
    end)
  end
end
