defmodule AriaBacktrackingTest.MixProject do
  use Mix.Project

  def project do
    [
      app: :aria_backtracking_test,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.14",
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
      {:aria_state, in_umbrella: true},
      {:aria_core, in_umbrella: true},
      {:aria_engine_core, in_umbrella: true},
      {:aria_hybrid_planner, in_umbrella: true}
    ]
  end
end
