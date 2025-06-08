# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaDebugger.MixProject do
  use Mix.Project

  def project do
    [
      app: :aria_debugger,
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
      mod: {AriaDebugger.Application, []}
    ]
  end

  defp deps do
    [
      # Configuration management
      {:config_tuples, "~> 0.4"},
      
      # System inspection
      {:recon, "~> 2.5"},
      {:observer_cli, "~> 1.7"},
      
      # Character shaping for diagnostics
      {:aria_shape, in_umbrella: true},
      
      # Data persistence (dependency on aria_data)
      {:aria_data, in_umbrella: true},
      
      # Monitor service for system state
      {:aria_monitor, in_umbrella: true},
      
      # JSON handling
      {:jason, "~> 1.4"},
      
      # Shared dependencies
      {:telemetry, "~> 1.2"}
    ]
  end
end