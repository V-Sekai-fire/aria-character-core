# Copy  def project do
    [
      app: :aria_security,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.15", 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaSecurity.MixProject do
  use Mix.Project

  def project do
    [
      app: :aria_security,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs", 
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {AriaSecurity.Application, []}
    ]
  end

  defp deps do
    [
      # OpenBao/Vault client (compatible with OpenBao)
      {:vaultex, "~> 1.0"},
      
      # HTTP client (used by vaultex)
      {:httpoison, "~> 1.8"},
      
      # JSON handling (used by vaultex)
      {:poison, "~> 4.0"},

      # For managing external OS processes (like OpenBao server)
      {:porcelain, "~> 2.0"},
      
      # Shared dependencies
      {:telemetry, "~> 1.2"}
    ]
  end
end