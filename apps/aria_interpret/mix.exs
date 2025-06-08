defmodule AriaInterpret.MixProject do
  use Mix.Project

  def project do
    [
      app: :aria_interpret,
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
      mod: {AriaInterpret.Application, []}
    ]
  end

  defp deps do
    [
      # AI and ML libraries
      {:nx, "~> 0.6"},
      {:ortex, "~> 0.1"},
      
      # Data persistence (dependency on aria_data)
      {:aria_data, in_umbrella: true},
      
      # Background job processing (dependency on aria_queue) 
      {:aria_queue, in_umbrella: true},
      
      # JSON handling
      {:jason, "~> 1.4"},
      
      # Shared dependencies
      {:telemetry, "~> 1.2"}
    ]
  end
end