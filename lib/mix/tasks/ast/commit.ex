# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.Ast.Commit do
  @moduledoc """
  Phase 1 AST migration tool with advanced parallel processing and Git integration.

  This task provides the enhanced Phase 1 functionality with:
  - Sourceror-based AST parsing for robust transformations
  - Task.async_stream for parallel file processing
  - Advanced rule composition and dependency management
  - Comprehensive Git integration with automatic commits
  - Enhanced error handling and recovery

  ## Usage

      # Apply transformation with automatic Git commit
      mix ast.commit --rule state_v2_to_state --message "Convert StateV2 to State"

      # Process specific files with parallel execution
      mix ast.commit --rule state_v2_to_state --files "lib/engine.ex,lib/state.ex" --concurrency 4

      # Apply multiple rules in sequence
      mix ast.commit --rules "state_v2_to_state,update_typespecs" --message "Comprehensive state migration"

      # Dry run with parallel processing preview
      mix ast.commit --rule state_v2_to_state --dry-run --concurrency 8

  ## Options

  - `--rule` - Single transformation rule to apply
  - `--rules` - Comma-separated list of rules to apply in sequence
  - `--message` - Git commit message (required unless --dry-run)
  - `--files` - Comma-separated list of specific files to transform
  - `--pattern` - File pattern to match (default: lib/**/*.ex,test/**/*.exs)
  - `--concurrency` - Maximum concurrent transformations (default: system cores)
  - `--timeout` - Timeout per file in milliseconds (default: 30000)
  - `--dry-run` - Preview transformations without applying changes
  - `--ordered` - Maintain file order in processing (slower but deterministic)
  - `--verbose` - Enable detailed logging output

  ## Examples

      # Basic usage with Git commit
      mix ast.commit --rule state_v2_to_state --message "Convert StateV2 to State in engine modules"

      # High-performance parallel processing
      mix ast.commit --rule state_v2_to_state --message "Parallel StateV2 conversion" --concurrency 16

      # Multiple rules with dependency handling
      mix ast.commit --rules "state_v2_to_state,update_typespecs,fix_imports" --message "Complete state migration"

      # Targeted file transformation
      mix ast.commit --rule state_v2_to_state --files "lib/aria_engine.ex" --message "Convert engine state"

      # Preview mode for safety
      mix ast.commit --rule state_v2_to_state --dry-run --verbose
  """

  use Mix.Task

  require Logger

  alias AstMigrate.RuleSystem
  alias AstMigrate.Git

  @shortdoc "Apply AST transformations with parallel processing and Git commit"

  @switches [
    rule: :string,
    rules: :string,
    message: :string,
    files: :string,
    pattern: :string,
    concurrency: :integer,
    timeout: :integer,
    dry_run: :boolean,
    ordered: :boolean,
    verbose: :boolean,
    help: :boolean
  ]

  @aliases [
    r: :rule,
    m: :message,
    f: :files,
    p: :pattern,
    c: :concurrency,
    t: :timeout,
    d: :dry_run,
    o: :ordered,
    v: :verbose,
    h: :help
  ]

  @impl Mix.Task
  def run(args) do
    {opts, _remaining_args, _invalid} = OptionParser.parse(args, switches: @switches, aliases: @aliases)

    if opts[:help] do
      print_help()
      :ok
    else

    # Configure logging level
    if opts[:verbose] do
      Logger.configure(level: :debug)
    end

    Logger.info("🔧 AST Migration Tool - Phase 1 (Advanced)")

    try do
      with {:ok, config} <- parse_configuration(opts),
           {:ok, rule_modules} <- load_rule_modules(config.rules),
           {:ok, target_files} <- discover_target_files(config),
           :ok <- validate_git_requirements(config),
           {:ok, successful_files, failed_files} <- apply_transformations(target_files, rule_modules, config) do

        print_results(successful_files, failed_files, config)

        if length(failed_files) > 0 do
          System.halt(1)
        end
      else
        {:error, reason} ->
          Mix.shell().error("❌ Transformation failed: #{reason}")
          System.halt(1)
      end
    rescue
      exception ->
        Mix.shell().error("❌ Unexpected error: #{inspect(exception)}")
        Logger.error("Exception in ast.commit task", exception: inspect(exception), stacktrace: Exception.format_stacktrace(__STACKTRACE__))
        System.halt(1)
    end
    end
  end

  # Configuration parsing and validation

  defp parse_configuration(opts) do
    config = %{
      rules: parse_rules(opts),
      message: opts[:message],
      files: parse_files(opts[:files]),
      pattern: opts[:pattern] || "lib/**/*.ex,test/**/*.exs",
      concurrency: opts[:concurrency] || System.schedulers_online(),
      timeout: opts[:timeout] || 30_000,
      dry_run: opts[:dry_run] || false,
      ordered: opts[:ordered] || false,
      verbose: opts[:verbose] || false
    }

    Logger.debug("Configuration parsed", config: config)

    case validate_configuration(config) do
      :ok -> {:ok, config}
      {:error, reason} -> {:error, reason}
    end
  end

  defp parse_rules(opts) do
    cond do
      opts[:rules] -> String.split(opts[:rules], ",") |> Enum.map(&String.trim/1)
      opts[:rule] -> [opts[:rule]]
      true -> []
    end
  end

  defp parse_files(nil), do: nil
  defp parse_files(files_string) do
    files_string
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.filter(&(&1 != ""))
  end

  defp validate_configuration(config) do
    cond do
      Enum.empty?(config.rules) ->
        {:error, "No transformation rules specified. Use --rule or --rules option."}

      not config.dry_run and is_nil(config.message) ->
        {:error, "Git commit message required unless using --dry-run. Use --message option."}

      config.concurrency < 1 ->
        {:error, "Concurrency must be at least 1"}

      config.timeout < 1000 ->
        {:error, "Timeout must be at least 1000ms"}

      true ->
        :ok
    end
  end

  # Rule module loading and validation

  defp load_rule_modules(rule_names) do
    Logger.debug("Loading rule modules", rules: rule_names)

    rule_modules = Enum.map(rule_names, &rule_name_to_module/1)

    case RuleSystem.validate_rules(rule_modules) do
      :ok ->
        Logger.debug("All rule modules loaded successfully", modules: rule_modules)
        {:ok, rule_modules}
      {:error, reason} ->
        {:error, "Failed to load rules: #{reason}"}
    end
  end

  defp rule_name_to_module(rule_name) do
    module_name = rule_name
    |> Macro.camelize()
    |> String.replace_suffix("", "")

    Module.concat([AstMigrate, Rules, module_name])
  end

  # File discovery and validation

  defp discover_target_files(config) do
    files = if config.files do
      config.files
    else
      discover_files_by_pattern(config.pattern)
    end

    Logger.info("Target files discovered",
      count: length(files),
      pattern: config.pattern,
      explicit_files: not is_nil(config.files)
    )

    case RuleSystem.validate_files(files) do
      :ok -> {:ok, files}
      {:error, reason} -> {:error, "File validation failed: #{reason}"}
    end
  end

  defp discover_files_by_pattern(pattern) do
    patterns = String.split(pattern, ",") |> Enum.map(&String.trim/1)

    patterns
    |> Enum.flat_map(&Path.wildcard/1)
    |> Enum.uniq()
    |> Enum.filter(&File.regular?/1)
  end

  # Git validation

  defp validate_git_requirements(config) do
    if config.dry_run do
      :ok
    else
      case Git.ensure_clean_working_tree(".") do
        :ok -> :ok
        {:error, reason} -> {:error, "Git validation failed: #{reason}"}
      end
    end
  end

  # Transformation execution

  defp apply_transformations(target_files, rule_modules, config) do
    Logger.info("Starting transformations",
      file_count: length(target_files),
      rule_count: length(rule_modules),
      concurrency: config.concurrency,
      dry_run: config.dry_run
    )

    start_time = System.monotonic_time(:millisecond)

    transform_options = [
      max_concurrency: config.concurrency,
      timeout: config.timeout,
      ordered: config.ordered,
      git_commit: not config.dry_run,
      commit_message: config.message,
      dry_run: config.dry_run
    ]

    result = RuleSystem.transform_files(target_files, rule_modules, transform_options)

    end_time = System.monotonic_time(:millisecond)
    duration = end_time - start_time

    Logger.info("Transformations completed",
      duration_ms: duration,
      files_per_second: length(target_files) / (duration / 1000)
    )

    result
  end

  # Results reporting

  defp print_results(successful_files, failed_files, config) do
    total_files = length(successful_files) + length(failed_files)
    success_rate = if total_files > 0, do: length(successful_files) / total_files * 100, else: 0

    Mix.shell().info("")
    Mix.shell().info("✅ Transformation completed successfully!")
    Mix.shell().info("Files processed: #{total_files}")
    Mix.shell().info("Files changed: #{length(successful_files)}")
    Mix.shell().info("Files failed: #{length(failed_files)}")
    Mix.shell().info("Success rate: #{Float.round(success_rate, 1)}%")

    if config.dry_run do
      Mix.shell().info("(Dry run - no files were actually modified)")
    else
      Mix.shell().info("Git commit created with message: \"#{config.message}\"")
    end

    if length(failed_files) > 0 do
      Mix.shell().info("")
      Mix.shell().info("❌ Failed files:")
      Enum.each(failed_files, fn file ->
        Mix.shell().info("  - #{file}")
      end)
    end

    if config.verbose and length(successful_files) > 0 do
      Mix.shell().info("")
      Mix.shell().info("✅ Successful files:")
      Enum.each(successful_files, fn file ->
        Mix.shell().info("  - #{file}")
      end)
    end
  end

  # Help documentation

  defp print_help do
    Mix.shell().info("""
    mix ast.commit - Phase 1 AST Migration Tool

    Apply AST transformations with parallel processing and Git integration.

    USAGE:
        mix ast.commit [OPTIONS]

    REQUIRED OPTIONS:
        --rule RULE                 Single transformation rule to apply
        --rules RULE1,RULE2,...     Multiple rules to apply in sequence
        --message MESSAGE           Git commit message (required unless --dry-run)

    OPTIONAL OPTIONS:
        --files FILE1,FILE2,...     Specific files to transform
        --pattern PATTERN           File pattern (default: lib/**/*.ex,test/**/*.exs)
        --concurrency N             Max concurrent transformations (default: #{System.schedulers_online()})
        --timeout MS                Timeout per file in milliseconds (default: 30000)
        --dry-run                   Preview without applying changes
        --ordered                   Maintain file order (slower but deterministic)
        --verbose                   Enable detailed logging
        --help                      Show this help

    EXAMPLES:
        # Basic transformation with Git commit
        mix ast.commit --rule state_v2_to_state --message "Convert StateV2 to State"

        # High-performance parallel processing
        mix ast.commit --rule state_v2_to_state --concurrency 16 --message "Parallel conversion"

        # Multiple rules in sequence
        mix ast.commit --rules "state_v2_to_state,update_typespecs" --message "Complete migration"

        # Targeted file transformation
        mix ast.commit --rule state_v2_to_state --files "lib/engine.ex" --message "Convert engine"

        # Safe preview mode
        mix ast.commit --rule state_v2_to_state --dry-run --verbose

    AVAILABLE RULES:
        state_v2_to_state          Convert StateV2 usage to State
        (Additional rules can be added to lib/ast_migrate/rules/)

    For more information, see: decisions/149-git-style-ast-migration-tool.md
    """)
  end
end
