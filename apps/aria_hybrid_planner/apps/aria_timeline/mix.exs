# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaTimeline.MixProject do
  use Mix.Project

  def project do
    [
      app: :aria_timeline,
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
      {:aria_state, in_umbrella: true},
      {:jason, "~> 1.4"},
      {:libgraph, "~> 0.16"},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:mox, "~> 1.0", only: :test},

      # STN solving functionality
      {:aria_minizinc_stn, in_umbrella: true}
    ]
  end

  defp package do
    [
      description: "Timeline management and temporal reasoning for AriaEngine",
      files: ~w(lib .formatter.exs mix.exs README* LICENSE*),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/your-org/aria_timeline"}
    ]
  end
end
