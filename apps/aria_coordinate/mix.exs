# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaCoordinate.MixProject do
  use Mix.Project

  def project do
    [
      app: :aria_coordinate,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {AriaCoordinate.Application, []}
    ]
  end

  defp deps do
    [
      # Phoenix web framework
      {:phoenix, "~> 1.7"},
      {:phoenix_html, "~> 4.0.0"},
      {:phoenix_live_reload, "~> 1.4", only: :dev},
      {:phoenix_live_view, "~> 1.0.0"},
      {:phoenix_live_dashboard, "~> 0.8"},

      # HTTP server
      {:bandit, "~> 1.0"},

      # Plugs for request handling
      {:plug_cowboy, "~> 2.6"},

      # CORS handling
      {:cors_plug, "~> 3.0"},

      # Rate limiting
      {:hammer, "~> 6.1"},

      # Security and authentication (dependencies on other services)
      {:aria_security, in_umbrella: true},
      {:aria_auth, in_umbrella: true},

      # JSON handling
      {:jason, "~> 1.4"},

      # Shared dependencies
      {:telemetry, "~> 1.2"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"}
    ]
  end
end
