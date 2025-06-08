defmodule AriaData.MixProject do
  use Mix.Project

  def project do
    [
      app: :aria_data,
      version: "0.1.0", 
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps", 
      lockfile: "../../mix.lock",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {AriaData.Application, []}
    ]
  end

  defp deps do
    [
      # Database ORM with PostgreSQL adapter (CockroachDB compatible)
      {:ecto_sql, "~> 3.10"},
      {:postgrex, "~> 0.20.0"},
      
      # JSON handling
      {:jason, "~> 1.4"},
      
      # Shared dependencies
      {:telemetry, "~> 1.2"}
    ]
  end

  defp aliases do
    [
      setup: ["ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end