# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaWorkflow.MixProject do
  use Mix.Project

  def project do
    [
      app: :aria_workflow,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      elixirc_options: [warnings_as_errors: true],
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {AriaWorkflow.Application, []}
    ]
  end

  defp deps do
    [
      # SOP execution planning
      {:libgraph, "~> 0.16"},

      # State machines and workflow management
      {:gen_state_machine, "~> 3.0"},

      # Data persistence (dependency on aria_data)
      {:aria_data, in_umbrella: true},

      # Planning engine for workflow execution
      {:aria_engine, in_umbrella: true},

      # Domain apps
      {:aria_file_management, in_umbrella: true},
      {:aria_workflow_system, in_umbrella: true},
      {:aria_timestrike, in_umbrella: true},

      # Character shaping for SOP assistance
      {:aria_shape, in_umbrella: true},

      # Interpret service for analysis
      {:aria_interpret, in_umbrella: true},

      # External process execution
      {:porcelain, "~> 2.0"},

      # JSON handling
      {:jason, "~> 1.4"},

      # Shared dependencies
      {:telemetry, "~> 1.2"}
    ]
  end
end
