# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaTimelineIntervals.MixProject do
  use Mix.Project

  def project do
    [
      app: :aria_timeline_intervals,
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
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:mox, "~> 1.0", only: :test}
    ]
  end

  defp package do
    [
      description: "Interval operations, Allen relations, and timeline functionality for AriaEngine",
      files: ~w(lib .formatter.exs mix.exs README* LICENSE*),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/your-org/aria_timeline_intervals"}
    ]
  end
end
