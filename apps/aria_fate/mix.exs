# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaFate.MixProject do
  use Mix.Project

  def project do
    [
      app: :aria_fate,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {AriaFate.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:aria_hybrid_planner, git: "https://github.com/V-Sekai-fire/aria-hybrid-planner.git"},
    ]
  end
end
