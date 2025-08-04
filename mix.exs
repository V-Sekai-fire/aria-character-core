# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCharacterCore.MixProject do
  use Mix.Project

  def project do
    [
      app: :aria_character_core,
      version: "0.2.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      elixirc_options: [],
      deps: deps(),
      aliases: aliases(),
      preferred_cli_env: [
        "test.all": :test,
        "test.watch": :test
      ],
      dialyzer: [
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
        ignore_warnings: ".dialyzer_ignore.exs"
      ]
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
      # Development and testing tools
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},

      # Core dependencies
      {:jason, "~> 1.4"},
      {:telemetry, "~> 1.2"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:tzdata, "~> 1.1"},

      # Planning and AI/ML
      {:libgraph, "~> 0.16"},

      # Numerical computing with GPU acceleration
      {:nx, "~> 0.10"},
      {:torchx, "~> 0.10"},

      # Phoenix web framework
      {:phoenix, "~> 1.7"},
      {:phoenix_html, "~> 4.0"},
      {:phoenix_live_reload, "~> 1.4", only: :dev},
      {:phoenix_live_view, "~> 1.0"},
      {:phoenix_live_dashboard, "~> 0.8"},
      {:bandit, "~> 1.0"},
      {:plug_cowboy, "~> 2.6"},
      {:cors_plug, "~> 3.0"},

      # Database
      {:ecto_sql, "~> 3.10"},
      {:ecto_sqlite3, "~> 0.12"},

      # RDF Knowledge Base
      {:rdf, "~> 2.1"},
      {:rdf_xml, "~> 1.2"},
      {:json_ld, "~> 1.0"},

      # Authentication and Security
      {:macfly, "~> 0.2.20"},
      {:bcrypt_elixir, "~> 3.0"},
      {:vaultex, "~> 1.0"},
      {:httpoison, "~> 1.8"},
      {:poison, "~> 4.0"},

      # Storage and File Management
      {:ex_aws, "~> 2.4"},
      {:ex_aws_s3, "~> 2.4"},
      {:hackney, "~> 1.18"},
      {:sweet_xml, "~> 0.7"},
      {:waffle, "~> 1.1"},
      {:waffle_ecto, "~> 0.0.11"},
      {:sftp_ex, "~> 0.2"},
      {:finch, "~> 0.16"},

      # Workflow and State Management
      {:gen_state_machine, "~> 3.0"},
      {:flow, "~> 1.2"},

      # Membrane Framework for Pipeline Processing
      {:membrane_core, "~> 1.0"},
      {:membrane_file_plugin, "~> 0.17.0"},

      # Monitoring and Metrics
      {:telemetry_metrics_prometheus, "~> 1.1"},
      {:prometheus_ex, "~> 3.0"},
      {:recon, "~> 2.5"},
      {:hammer, "~> 6.1"},

      # External Communication
      {:ex_webrtc, "~> 0.3"},
      {:req, "~> 0.4"},

      # Cryptography and Compression
      {:ex_crypto, "~> 0.10"},
      {:ezstd, "~> 1.0"},
      {:rustler, "~> 0.36", optional: true},

      # External Process Execution
      {:porcelain, "~> 2.0"},

      # Git operations
      {:egit, "~> 0.1.9"},

      # AST parsing and manipulation
      {:sourceror, "~> 1.0"},

      # UUID Generation
      {:elixir_uuid, "~> 1.2"},
      {:uuid, "~> 1.1", app: false},
      {:iso8601, "~> 1.3"},
      {:timex, "~> 3.7"},

      # Test dependencies
      {:mox, "~> 1.0", only: :test},
      {:stream_data, "~> 1.2", only: :test},
      {:ex_unit_notifier, "~> 1.3", only: :test},

      # Internal applications
      {:aria_blocks_world, path: "apps/aria_blocks_world"},
      {:aria_core, path: "apps/aria_core"},
      {:aria_town, path: "apps/aria_town"},
      {:aria_hybrid_planner, git: "https://github.com/V-Sekai-fire/aria_hybrid_planner.git"},
      {:aria_membrane_pipeline, path: "apps/aria_membrane_pipeline"},
      {:aria_math, path: "apps/aria_math"},
      {:aria_joint, path: "apps/aria_joint"},
      {:aria_gltf, path: "apps/aria_gltf"},
      {:aria_qcp, path: "apps/aria_qcp"},
      {:ast_migrate, path: "apps/ast_migrate"},
      {:aria_serial, path: "apps/aria_serial"},
      {:aria_simple_travel, path: "apps/aria_simple_travel"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project
  defp aliases do
    [
      "test.all": ["test"],
      "test.setup": ["test"],
      # Exclude type_check_strict tests by default
      test: ["test --exclude type_check_strict"],
      "test.watch": ["test.watch"],
      setup: ["deps.get"],
      format: ["format"],
      quality: ["credo --strict", "dialyzer"],
      "cycle.analyze": ["run scripts/analyze_commit_cycles.exs"],
      "cycle.format": [
        "cmd",
        "sh",
        "-c",
        "elixir scripts/analyze_commit_cycles.exs --format-commit"
      ]
    ]
  end
end
