defmodule TrenurangAdapter.MixProject do
  use Mix.Project

  def project do
    [
      app: :trenurang_adapter,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {TrenurangAdapter.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:telegex, "~> 1.0"},
      {:finch, "~> 0.19"},
      {:trenurang_core, in_umbrella: true},
      {:trenurang_intelligence, in_umbrella: true}
    ]
  end
end
