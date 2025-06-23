# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.Migrate do
  @moduledoc """
  Unified migration system for code transformations.

  This task provides a single entry point for all code migrations using AST-based
  transformations. It replaces individual migration tasks with a unified, extensible
  system that follows single responsibility principles.

  ## Usage

      mix migrate [options] [files...]

  ## Options

      --rules=rule1,rule2,rule3    Apply specific transformation rules
      --list-rules                 List all available transformation rules
      --dry-run                    Preview changes without modifying files
      --backup-dir=DIR             Custom backup directory (default: .migration_backup)
      --verbose                    Show detailed progress information
      --help                       Show this help message

  ## Examples

      mix migrate --list-rules                           # Show available rules
      mix migrate --rules=domain_from_module,logger      # Apply specific rules
      mix migrate --dry-run                              # Preview all applicable changes
      mix migrate --rules=goal_tuples test/              # Apply goal tuple fixes to test files

  ## Rule Categories

  - **deprecation**: Fix deprecated API usage
  - **refactoring**: Code structure improvements
  - **api_migration**: API signature changes
  - **format_migration**: Data format changes
  """

  use Mix.Task
  alias AriaEngine.Membrane.Migration.{Pipeline, Registry}

  @shortdoc "Unified migration system for code transformations"

  @switches [
    rules: :string,
    list_rules: :boolean,
    dry_run: :boolean,
    backup_dir: :string,
    verbose: :boolean,
    help: :boolean
  ]

  @aliases [
    r: :rules,
    l: :list_rules,
    d: :dry_run,
    b: :backup_dir,
    v: :verbose,
    h: :help
  ]

  @impl Mix.Task
  def run(args) do
    {opts, files, _invalid} = OptionParser.parse(args, switches: @switches, aliases: @aliases)

    cond do
      opts[:help] ->
        show_help()

      opts[:list_rules] ->
        list_available_rules()

      true ->
        execute_migration(opts, files)
    end
  end

  defp show_help do
    Mix.shell().info(@moduledoc)
  end

  defp list_available_rules do
    Mix.shell().info("Available Migration Rules:")
    Mix.shell().info("=" <> String.duplicate("=", 25))

    Registry.list_rules()
    |> Enum.group_by(& &1.category)
    |> Enum.each(fn {category, rules} ->
      Mix.shell().info("\n#{String.upcase(to_string(category))}:")

      Enum.each(rules, fn rule ->
        Mix.shell().info("  #{rule.name} - #{rule.description}")
      end)
    end)
  end

  defp execute_migration(opts, files) do
    config = %{
      rules: parse_rules(opts[:rules]),
      dry_run: opts[:dry_run] || false,
      backup_dir: opts[:backup_dir] || ".migration_backup",
      verbose: opts[:verbose] || false,
      files: if(Enum.empty?(files), do: ["."], else: files)
    }

    # Start the Membrane pipeline
    {:ok, _supervisor_pid, pipeline_pid} = Membrane.Pipeline.start_link(Pipeline, config)

    # Wait for pipeline completion
    ref = Process.monitor(pipeline_pid)

    receive do
      {:DOWN, ^ref, :process, ^pipeline_pid, reason} ->
        case reason do
          :normal -> :ok
          :shutdown -> :ok
          {:shutdown, _} -> :ok
          other ->
            Mix.shell().error("Pipeline failed: #{inspect(other)}")
            System.halt(1)
        end
    end
  end

  defp parse_rules(nil), do: :all
  defp parse_rules(rules_string) do
    rules_string
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.map(&String.to_atom/1)
  end
end
