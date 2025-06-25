# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaHybridPlanner.MixProject do
  use Mix.Project

  def project do
    [
      app: :aria_hybrid_planner,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      # Internal dependencies
      {:aria_engine_core, path: "../aria_engine_core"},
      {:aria_temporal_planner, path: "../aria_temporal_planner"},

      # External dependencies
      {:libgraph, "~> 0.16"},
      {:jason, "~> 1.4"},
      {:telemetry, "~> 1.0"},
      {:mox, "~> 1.0", only: :test}
    ]
  end
end
