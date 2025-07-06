# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

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
      # RDF support for semantic web compatibility
      {:rdf, "~> 2.0"},

      # JSON handling
      {:jason, "~> 1.4"},

      # Development and testing
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end
end
