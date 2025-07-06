# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

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
  alias AstMigrate

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

    rules = AstMigrate.list_rules()

    if Enum.empty?(rules) do
      Mix.shell().info("  No rules currently implemented.")
      Mix.shell().info("  This is a clean foundation ready for future transformation rules.")
    else
      Enum.each(rules, fn rule_name ->
        case AstMigrate.rule_info(rule_name) do
          {:ok, _module} ->
            Mix.shell().info("  #{rule_name} - Available transformation rule")
          {:error, _} ->
            Mix.shell().info("  #{rule_name} - No description available")
        end
      end)
    end
  end

  defp execute_migration(opts, args) do
    {rules, files} = parse_rules_and_files(opts[:rules], args)
    dry_run = opts[:dry_run] || false
    verbose = opts[:verbose] || false

    target_files = if Enum.empty?(files), do: ["lib/**/*.ex", "test/**/*.exs"], else: files

    migration_opts = [
      dry_run: dry_run,
      files: target_files
    ]

    case rules do
      :all ->
        # Apply all available rules
        AstMigrate.list_rules()
        |> Enum.each(fn rule ->
          apply_single_rule(rule, migration_opts, verbose)
        end)

      rule_list when is_list(rule_list) ->
        # Apply specific rules
        Enum.each(rule_list, fn rule ->
          apply_single_rule(rule, migration_opts, verbose)
        end)
    end
  end

  defp apply_single_rule(rule, opts, verbose) do
    if verbose do
      Mix.shell().info("Applying rule: #{rule}")
    end

    case AstMigrate.apply_rule(rule, opts) do
      {:ok, result} ->
        if verbose do
          Mix.shell().info("✓ #{rule}: #{result.files_changed} files changed")
        end

      {:error, reason} ->
        Mix.shell().error("✗ #{rule}: #{reason}")
    end
  end

  defp parse_rules_and_files(rules_option, args) do
    available_rules = AstMigrate.list_rules()

    cond do
      # If --rules option is provided, use it and treat args as files
      rules_option != nil ->
        rules = parse_rules(rules_option)
        {rules, args}

      # If first arg is a known rule name, treat it as rule and rest as files
      length(args) > 0 and String.to_atom(hd(args)) in available_rules ->
        rule_name = String.to_atom(hd(args))
        files = tl(args)
        {[rule_name], files}

      # Otherwise, apply all rules to the provided files
      true ->
        {:all, args}
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
