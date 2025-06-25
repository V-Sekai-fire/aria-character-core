# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaScheduler.MixProject do
  use Mix.Project

  def project do
    [
      app: :aria_scheduler,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.18",
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
      {:aria_hybrid_planner, path: "../aria_hybrid_planner"},
      {:aria_temporal_planner, path: "../aria_temporal_planner"},

      # External dependencies
      {:jason, "~> 1.4"},
      {:libgraph, "~> 0.16"},
      {:telemetry, "~> 1.2"},
      {:timex, "~> 3.7"},
      {:mox, "~> 1.0", only: :test}
    ]
  end
end
