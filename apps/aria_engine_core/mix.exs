# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngineCore.MixProject do
  use Mix.Project

  def project do
    [
      app: :aria_engine_core,
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
      {:aria_state, path: "../aria_state"},
      {:aria_hybrid_planner, path: "../aria_hybrid_planner"},
      {:aria_timeline, path: "../aria_timeline"},
      {:aria_minizinc_stn, path: "../aria_minizinc_stn"},
      {:aria_minizinc_goal, in_umbrella: true},
      # External dependencies
      {:jason, "~> 1.4"},
      {:libgraph, "~> 0.16"},
      {:porcelain, "~> 2.0"},
      {:timex, "~> 3.7"},
      {:telemetry, "~> 1.0"},
      {:mox, "~> 1.0", only: :test},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false}
    ]
  end
end
