defmodule AriaEngine.MixProject do
  use Mix.Project

  def project do
    [
      app: :aria_engine,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {AriaEngine.Application, []}
    ]
  end

  defp deps do
    [
      # Numerical computing for planning algorithms
      {:nx, "~> 0.6"},
      
      # Planning and decision-making libraries
      {:libgraph, "~> 0.16"},
      
      # Data persistence (dependency on aria_data)
      {:aria_data, in_umbrella: true},
      
      # Character AI integration
      {:aria_character_ai, in_umbrella: true},
      
      # JSON handling
      {:jason, "~> 1.4"},
      
      # Shared dependencies
      {:telemetry, "~> 1.2"}
    ]
  end
end