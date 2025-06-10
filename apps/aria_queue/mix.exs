# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaQueue.MixProject do
  use Mix.Project

  def project do
    [
      app: :aria_queue,
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
      mod: {AriaQueue.Application, []}
    ]
  end

  defp deps do
    [
      # Background job processing
      {:oban, "~> 2.19.4"},

      # Data persistence (dependency on aria_data)
      {:aria_data, in_umbrella: true},

      # JSON handling
      {:jason, "~> 1.4"},

      # Shared dependencies
      {:telemetry, "~> 1.2"}
    ]
  end
end
