defmodule AriaInteractivity.MixProject do
  use Mix.Project

  def project do
    [
      app: :aria_interactivity,
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

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {AriaInteractivity.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Umbrella app dependencies
      {:aria_gltf, in_umbrella: true},

      # External dependencies
      {:aria_hybrid_planner, git: "https://github.com/V-Sekai-fire/aria-hybrid-planner"}
    ]
  end
end
