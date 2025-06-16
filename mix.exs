# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaCharacterCore.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: "0.1.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      preferred_cli_env: [
        "test.all": :test,
        "test.watch": :test
      ],
      elixirc_options: [warnings_as_errors: true],
    ]
  end

  # Dependencies listed here are available to all child apps
  defp deps do
    [
      # Development and testing tools
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},

      # Shared utilities that all apps might need
      {:jason, "~> 1.4"},
      {:telemetry, "~> 1.2"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:tzdata, "~> 1.1"},

      # JSON-LD and RDF support for temporal planner
      {:json_ld, "~> 1.0"},
      {:rdf, "~> 2.1"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project
  defp aliases do
    [
      "test.all": ["test"],
      "test.watch": ["test.watch"],
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": [
        "ecto.create -r AriaData.Repo",
        "ecto.migrate -r AriaData.Repo",
        "ecto.create -r AriaData.AuthRepo",
        "ecto.migrate -r AriaData.AuthRepo",
        "ecto.create -r AriaData.StorageRepo",
        "ecto.migrate -r AriaData.StorageRepo",
        "ecto.create -r AriaData.MonitorRepo",
        "ecto.migrate -r AriaData.MonitorRepo",
        "ecto.create -r AriaData.EngineRepo",
        "ecto.migrate -r AriaData.EngineRepo",
        "run priv/repo/seeds.exs"
      ],
      "ecto.reset": [
        "ecto.drop -r AriaData.Repo",
        "ecto.drop -r AriaData.AuthRepo",
        "ecto.drop -r AriaData.StorageRepo",
        "ecto.drop -r AriaData.MonitorRepo",
        "ecto.drop -r AriaData.EngineRepo",
        "ecto.setup"
      ],
      format: ["format", "cmd --app aria_* mix format"],
      quality: ["format", "credo --strict", "dialyzer"],
      app: ["app"],
      "cycle.analyze": ["run scripts/analyze_commit_cycles.exs"],
      "cycle.format": ["cmd", "sh", "-c", "elixir scripts/analyze_commit_cycles.exs --format-commit"]
    ]
  end
end
