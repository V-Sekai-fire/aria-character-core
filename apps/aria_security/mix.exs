defmodule AriaSecurity.MixProject do
  use Mix.Project

  def project do
    [
      app: :aria_security,
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
      mod: {AriaSecurity.Application, []}
    ]
  end

  defp deps do
    [
      # HTTP client for OpenBao API
      {:req, "~> 0.4"},
      
      # JSON handling
      {:jason, "~> 1.4"},
      
      # Configuration and secrets management  
      {:vault, "~> 0.2"},
      
      # Shared dependencies
      {:telemetry, "~> 1.2"}
    ]
  end
end