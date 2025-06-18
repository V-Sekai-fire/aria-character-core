# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaTown.MixProject do
  use Mix.Project

  def project do
    [
      app: :aria_town,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {AriaTown.Application, []}
    ]
  end

  defp deps do
    [
      # RDF Knowledge Base
      {:rdf, "~> 1.1"},
      {:sparql, "~> 0.3"},
      
      # Phoenix LiveView for Real-time UI
      {:phoenix, "~> 1.7.14"},
      {:phoenix_live_view, "~> 0.20.2"},
      {:phoenix_html, "~> 4.0"},
      {:jason, "~> 1.4"},
      {:plug_cowboy, "~> 2.5"},
      
      # AriaEngine Integration
      {:aria_engine, in_umbrella: true},
      
      # Utilities
      {:uuid, "~> 1.1"},
      
      # Utilities
      {:elixir_uuid, "~> 1.2"},
      
      # Development and Testing
      {:phoenix_live_reload, "~> 1.2", only: :dev}
    ]
  end
end
