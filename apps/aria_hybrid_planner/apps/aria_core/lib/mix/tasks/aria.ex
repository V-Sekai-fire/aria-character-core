# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule Mix.Tasks.Aria do
  @moduledoc """
  AriaEngine command-line interface.

  ## Available Commands

    * `mix aria.validate` - Validate scheduling solutions by comparing solvers
    * `mix aria.pipeline` - Manage AriaEngine processing pipelines

  ## Quick Examples

      # Validate scheduling with generated problem
      mix aria.validate --problem "test_scaling" --activities 3 --compare

      # Start a processing pipeline
      mix aria.pipeline start --topology echo_pipeline

      # List active pipelines
      mix aria.pipeline list

  ## Getting Help

  Use `--help` with any command for detailed usage information:

      mix aria.validate --help
      mix aria.pipeline --help

  ## About AriaEngine

  AriaEngine is a temporal planning and scheduling system that provides:

  - Activity scheduling with resource management
  - Multi-solver validation and comparison
  - Pipeline-based processing architecture
  - Train scheduling optimization
  - Constraint satisfaction solving

  For more information, see the project documentation.
  """

  use Mix.Task

  @shortdoc "AriaEngine command-line interface"

  def run(args) do
    case args do
      ["--help"] ->
        Mix.shell().info(@moduledoc)

      ["help"] ->
        Mix.shell().info(@moduledoc)

      [] ->
        Mix.shell().info(@moduledoc)

      [command | _] ->
        Mix.shell().error("Unknown command: #{command}")
        Mix.shell().info("Use 'mix aria --help' for available commands")
        System.halt(1)
    end
  end
end
