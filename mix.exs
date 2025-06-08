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
      ]
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
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project
  defp aliases do
    [
      "test.all": ["test"],
      "test.watch": ["test.watch"],
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      format: ["format", "cmd --app aria_* mix format"],
      quality: ["format", "credo --strict", "dialyzer"]
    ]
  end
end