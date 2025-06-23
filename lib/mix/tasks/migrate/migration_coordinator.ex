# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.Migrate.MigrationCoordinator do
  @moduledoc """
  Coordinates the migration process.

  Single responsibility: Orchestrate the overall migration flow by coordinating
  between rule registry, file processor, rule engine, and CLI interface.
  """

  alias Mix.Tasks.Migrate.{RuleRegistry, FileProcessor, RuleEngine, CliInterface}

  @doc """
  Execute migration with the given configuration.
  """
  def execute(config) do
    CliInterface.log_migration_start(config)

    # Discover files to process
    files = discover_files(config)

    if Enum.empty?(files) do
      CliInterface.log_no_files_found()
      :ok
    else
      # Determine which rules to apply
      rules = determine_rules(config, files)

      if Enum.empty?(rules) do
        CliInterface.log_no_applicable_rules()
        :ok
      else
        # Execute the migration
        results = process_files_with_rules(files, rules, config)

        # Report results
        CliInterface.log_migration_complete(results, config)

        :ok
      end
    end
  end

  # Private functions

  defp discover_files(config) do
    case config.files do
      [] ->
        # No specific files provided, discover all eligible files
        FileProcessor.discover_elixir_files()

      files ->
        # Use provided files, but expand directories
        Enum.flat_map(files, &expand_file_or_directory/1)
    end
    |> Enum.filter(&FileProcessor.should_process_file?/1)
  end

  defp expand_file_or_directory(path) do
    cond do
      File.regular?(path) ->
        [path]

      File.dir?(path) ->
        Path.wildcard(Path.join(path, "**/*.{ex,exs}"))

      true ->
        # Treat as a glob pattern
        Path.wildcard(path)
    end
  end

  defp determine_rules(config, files) do
    case config.rules do
      :all ->
        # Find all applicable rules by scanning file contents
        find_applicable_rules_for_files(files)

      rule_names when is_list(rule_names) ->
        # Use specified rules, resolved with dependencies
        RuleRegistry.resolve_dependencies(rule_names)
    end
  end

  defp find_applicable_rules_for_files(files) do
    # Sample a few files to determine applicable rules
    # For performance, we don't scan every file's content
    sample_files = Enum.take(files, 10)

    sample_files
    |> Enum.flat_map(fn file ->
      case File.read(file) do
        {:ok, content} -> RuleRegistry.get_applicable_rules(content)
        {:error, _} -> []
      end
    end)
    |> Enum.uniq_by(& &1.name)
    |> RuleRegistry.resolve_dependencies()
  end

  defp process_files_with_rules(files, rules, config) do
    # Create backup directory if not in dry-run mode
    unless config.dry_run do
      FileProcessor.create_backup_dir(config.backup_dir)
    end

    # Process each file
    results =
      Enum.map(files, fn file ->
        process_single_file(file, rules, config)
      end)

    # Aggregate results
    %{
      total_files: length(files),
      changed_files: count_results(results, :changed),
      unchanged_files: count_results(results, :unchanged),
      skipped_files: count_results(results, :skipped),
      error_files: count_results(results, :error),
      results: results
    }
  end

  defp process_single_file(file, rules, config) do
    case File.read(file) do
      {:ok, content} ->
        # Determine which rules apply to this file
        applicable_rules = Enum.filter(rules, &(&1.detection_fn.(content)))

        if Enum.empty?(applicable_rules) do
          CliInterface.log_file_skipped(file, config)
          {:skipped, file}
        else
          # Apply transformations
          case apply_rules_to_content(content, applicable_rules) do
            {:changed, new_content} ->
              if config.dry_run do
                CliInterface.log_file_would_change(file, config)
                {:would_change, file}
              else
                # Backup and write the file
                FileProcessor.backup_file(file, config.backup_dir)
                File.write!(file, new_content)
                CliInterface.log_file_changed(file, config)
                {:changed, file}
              end

            :unchanged ->
              CliInterface.log_file_unchanged(file, config)
              {:unchanged, file}

            {:error, reason} ->
              CliInterface.log_file_error(file, reason, config)
              {:error, file, reason}
          end
        end

      {:error, reason} ->
        CliInterface.log_file_error(file, reason, config)
        {:error, file, reason}
    end
  end

  defp apply_rules_to_content(content, rules) do
    # Extract transformation functions from rules
    transformation_rules =
      Enum.flat_map(rules, fn rule ->
        rule.transformation_fn.()
      end)

    # Apply all transformations using the rule engine
    RuleEngine.transform_code(content, transformation_rules)
  end

  defp count_results(results, type) do
    Enum.count(results, fn
      {^type, _} -> true
      {^type, _, _} -> true
      _ -> false
    end)
  end
end
