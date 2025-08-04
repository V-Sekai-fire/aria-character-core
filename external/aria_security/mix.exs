# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaSecurity.MixProject do
  use Mix.Project

  def project do
    [
      app: :aria_security,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {AriaSecurity.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:vaultex, "~> 1.0"},
      {:httpoison, "~> 1.0"},
      {:jason, "~> 1.4"}
    ]
  end
end
