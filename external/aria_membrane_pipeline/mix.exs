# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaMembranePipeline.MixProject do
  use Mix.Project

  def project do
    [
      app: :aria_membrane_pipeline,
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
      {:aria_hybrid_planner, path: "../aria_hybrid_planner"},
      {:aria_minizinc_goal, path: "../aria_minizinc_goal"},

      # External dependencies
      {:jason, "~> 1.4"},
      {:telemetry, "~> 1.2"},
      {:porcelain, "~> 2.0"},

      # Membrane Framework dependencies
      {:membrane_core, "~> 1.0"},
      {:membrane_file_plugin, "~> 0.17.0"},
      {:membrane_hackney_plugin, "~> 0.11.0"}
    ]
  end
end
