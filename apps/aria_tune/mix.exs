defmodule AriaTune.MixProject do
  use Mix.Project

  def project do
    [
      app: :aria_tune,
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
      mod: {AriaTune.Application, []}
    ]
  end

  defp deps do
    [
      # Performance analysis and optimization
      {:benchee, "~> 1.1"},
      {:telemetry_metrics, "~> 0.6"},
      
      # Machine learning for optimization
      {:nx, "~> 0.6"},
      {:scholar, "~> 0.2"},
      
      # Character shaping for optimization suggestions
      {:aria_shape, in_umbrella: true},
      
      # Monitor service for performance data
      {:aria_monitor, in_umbrella: true},
      
      # Data persistence (dependency on aria_data)
      {:aria_data, in_umbrella: true},
      
      # JSON handling
      {:jason, "~> 1.4"},
      
      # Shared dependencies
      {:telemetry, "~> 1.2"}
    ]
  end
end