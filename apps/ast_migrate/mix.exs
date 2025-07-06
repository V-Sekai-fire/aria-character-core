# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AstMigrate.MixProject do
  use Mix.Project

  def project do
    [
      app: :ast_migrate,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      aliases: aliases(),
      preferred_cli_env: [
        "test.all": :test,
        "test.watch": :test
      ],
      description: "AST-based code migration tool for Elixir projects",
      package: package()
    ]
  end

  # Specifies which paths to compile per environment
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      # Core dependencies for AST manipulation
      {:sourceror, "~> 1.0"},
      {:jason, "~> 1.4"},

      # Development and testing tools
      {:egit, "~> 0.1.9"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},

      # Test dependencies
      {:stream_data, "~> 1.2", only: :test},
      {:ex_unit_notifier, "~> 1.3", only: :test}
    ]
  end

  defp aliases do
    [
      "test.all": ["test"],
      "test.setup": ["test"],
      test: ["test"],
      "test.watch": ["test.watch"],
      setup: ["deps.get"],
      format: ["format"],
      quality: ["credo --strict", "dialyzer"]
    ]
  end

  defp package do
    [
      name: "ast_migrate",
      files: ~w(lib mix.exs README.md LICENSE.md),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/your-org/ast_migrate"}
    ]
  end
end
