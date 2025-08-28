defmodule AriaFate.MixProject do
  use Mix.Project

  def project do
    [
      app: :aria_fate,
      version: "0.2.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.17",
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
      {:jason, "~> 1.4"},
      {:floki, "~> 0.36"},
      {:aria_core, git: "https://github.com/V-Sekai-fire/aria-hybrid-planner.git", sparse: "apps/aria_core"}
    ]
  end
end
