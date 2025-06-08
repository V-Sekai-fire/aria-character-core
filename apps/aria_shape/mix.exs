# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaShape.MixProject do
  use Mix.Project

  def project do
    [
      app: :aria_shape,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {AriaShape.Application, []}
    ]
  end

  defp deps do
    [
      # ONNX model execution
      {:ortex, "~> 0.1"},
      {:nx, "~> 0.6"},
      
      # Machine learning for GRPO training
      {:scholar, "~> 0.2"},
      
      # Data persistence (dependency on aria_data)
      {:aria_data, in_umbrella: true},
      
      # Storage for models and assets
      {:aria_storage, in_umbrella: true},
      
      # Background processing
      {:aria_queue, in_umbrella: true},
      
      # JSON handling
      {:jason, "~> 1.4"},
      
      # Shared dependencies
      {:telemetry, "~> 1.2"}
    ]
  end
end