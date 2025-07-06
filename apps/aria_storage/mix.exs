# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaStorage.MixProject do
  use Mix.Project

  def project do
    [
      app: :aria_storage,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :crypto]
    ]
  end

  defp deps do
    [
      # Storage and File Management
      {:waffle, "~> 1.1"},
      {:waffle_ecto, "~> 0.0.11"},
      {:ex_aws, "~> 2.4"},
      {:ex_aws_s3, "~> 2.4"},
      {:hackney, "~> 1.18"},
      {:sweet_xml, "~> 0.7"},
      {:sftp_ex, "~> 0.2"},
      {:finch, "~> 0.16"},
      {:httpoison, "~> 1.8"},

      # Compression
      {:ezstd, "~> 1.0"},

      # JSON handling
      {:jason, "~> 1.4"},

      # Database (for chunk metadata)
      {:ecto_sql, "~> 3.10"},
      {:ecto_sqlite3, "~> 0.12"},

      # UUID Generation
      {:elixir_uuid, "~> 1.2"},

      # Development and testing tools
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:stream_data, "~> 1.2", only: :test}
    ]
  end
end
