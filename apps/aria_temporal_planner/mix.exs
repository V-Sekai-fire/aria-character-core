# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaTemporalPlanner.MixProject do
  use Mix.Project

  def project do
    [
      app: :aria_temporal_planner,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.4"},
      {:libgraph, "~> 0.16"},
      {:porcelain, "~> 2.0"},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},

      # Core engine dependency for AriaEngine.State and AriaEngine.MiniZinc.Executor
      {:aria_engine_core, path: "../aria_engine_core"}
    ]
  end

  defp package do
    [
      description: "Temporal planning and STN solving for AriaEngine",
      files: ~w(lib .formatter.exs mix.exs README* LICENSE*),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/your-org/aria_temporal_planner"}
    ]
  end
end
