# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaMonitor.MixProject do
  use Mix.Project

  def project do
    [
      app: :aria_monitor,
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
      mod: {AriaMonitor.Application, []}
    ]
  end

  defp deps do
    [
      # Monitoring and metrics
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      
      # Prometheus integration
      {:telemetry_metrics_prometheus, "~> 1.1"},
      {:prometheus_ex, "~> 3.0"},
      
      # System monitoring
      {:recon, "~> 2.5"},
      
      # Phoenix Live Dashboard for UI
      {:phoenix_live_dashboard, "~> 0.8"},
      {:phoenix, "~> 1.7"},
      {:phoenix_live_view, "~> 0.20"},
      
      # Data persistence (dependency on aria_data)
      {:aria_data, in_umbrella: true},
      
      # JSON handling
      {:jason, "~> 1.4"},
      
      # Shared dependencies
      {:telemetry, "~> 1.2"}
    ]
  end
end