defmodule AriaInterface.MixProject do
  use Mix.Project

  def project do
    [
      app: :aria_interface,
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
      mod: {AriaInterface.Application, []}
    ]
  end

  defp deps do
    [
      # Phoenix for web interface
      {:phoenix, "~> 1.7"},
      {:phoenix_live_view, "~> 0.20"},
      
      # HTTP server
      {:bandit, "~> 1.0"},
      
      # File handling and uploads
      {:upload, "~> 0.3"},
      {:mime, "~> 2.0"},
      
      # WebSocket and real-time communication
      {:phoenix_pubsub, "~> 2.1"},
      
      # gRPC support
      {:grpc, "~> 0.7"},
      {:protobuf, "~> 0.12"},
      
      # Character AI for data characterization
      {:aria_character_ai, in_umbrella: true},
      
      # Interpret service for analysis
      {:aria_interpret, in_umbrella: true},
      
      # Engine service for processing
      {:aria_engine, in_umbrella: true},
      
      # Storage for large assets
      {:aria_storage, in_umbrella: true},
      
      # JSON handling
      {:jason, "~> 1.4"},
      
      # Shared dependencies
      {:telemetry, "~> 1.2"}
    ]
  end
end