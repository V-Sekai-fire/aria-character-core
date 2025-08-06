# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaTemporalBlocks.MixProject do
  use Mix.Project

  def project do
    [
      app: :aria_temporal_blocks,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps()
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [
      extra_applications: [:logger],
    ]
  end

  defp deps do
    [
      # Internal dependencies
      {:aria_core, in_umbrella: true},
      {:aria_hybrid_planner, in_umbrella: true},
      {:aria_state, in_umbrella: true},
      {:aria_timeline, in_umbrella: true},
      # External dependencies
      {:jason, "~> 1.4"},
      {:mox, "~> 1.0", only: :test},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false}
    ]
  end
end
