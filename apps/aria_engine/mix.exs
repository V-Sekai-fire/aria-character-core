# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.MixProject do
  use Mix.Project

  def project do
    [
      app: :aria_engine,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      elixirc_options: [warnings_as_errors: false],
      deps: deps()
    ]
  end

  # Specifies which paths to compile per environment
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [
      extra_applications: [:logger],
      mod: {AriaEngine.Application, []}
    ]
  end

  defp deps do
    [
      # Numerical computing for planning algorithms
      {:nx, "~> 0.6"},

      # Planning and decision-making libraries
      {:libgraph, "~> 0.16"},

      # Real-time multimedia processing framework
      {:membrane_core, "~> 1.0"},

      # Data persistence (dependency on aria_data)
      {:aria_data, in_umbrella: true},

      # Character shaping integration
      {:aria_shape, in_umbrella: true},

      # JSON handling
      {:jason, "~> 1.4"},

      # External process execution for actions
      {:porcelain, "~> 2.0"},

      # UUID generation for character IDs
      {:elixir_uuid, "~> 1.2"},

      # Shared dependencies
      {:telemetry, "~> 1.2"}
    ]
  end
end
