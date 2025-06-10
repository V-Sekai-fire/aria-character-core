# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

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
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {AriaStorage.Application, []}
    ]
  end

  defp deps do
    [
      # Content-addressed storage
      {:ex_aws, "~> 2.4"},
      {:ex_aws_s3, "~> 2.4"},
      {:hackney, "~> 1.18"},
      {:sweet_xml, "~> 0.7"},

      # File handling and compression
      {:ex_crypto, "~> 0.10"},
      {:ezstd, "~> 1.0"},  # zstd compression for desync compatibility

      # File upload and storage
      {:waffle, "~> 1.1"},
      {:waffle_ecto, "~> 0.0.11"},

      # Casync/desync format parsing
      {:nimble_parsec, "~> 1.4"},  # Parser combinator for casync formats

      # SFTP support
      {:sftp_ex, "~> 0.2"},

      # CDN integration
      {:finch, "~> 0.16"},

      # Data persistence (dependency on aria_data)
      {:aria_data, in_umbrella: true},

      # Background job processing (dependency on aria_queue)
      {:aria_queue, in_umbrella: true},

      # Security service integration
      {:aria_security, in_umbrella: true},

      # JSON handling
      {:jason, "~> 1.4"},

      # Shared dependencies
      {:telemetry, "~> 1.2"},

      # Test dependencies
      {:stream_data, "~> 0.5", only: :test},
      {:ex_unit_notifier, "~> 1.3", only: :test},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end
end
