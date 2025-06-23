# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.Migrate.CliInterface do
  @moduledoc """
  Handles CLI interaction and logging for migrations.

  Single responsibility: Manage user interface, progress reporting, and
  logging without any migration logic.
  """

  require Logger

  @doc """
  Log the start of a migration process.
  """
  def log_migration_start(config) do
    Logger.info("🔧 Unified Migration System")
    Logger.info("===========================")

    if config.dry_run do
      Logger.info("🔍 DRY RUN MODE - No files will be modified")
    else
      Logger.info("📁 Backup directory: #{config.backup_dir}")
    end

    if config.verbose do
      Logger.info("📋 Verbose mode enabled")
    end

    case config.rules do
      :all ->
        Logger.info("🎯 Applying all applicable rules")

      rules when is_list(rules) ->
        rule_names = Enum.join(rules, ", ")
        Logger.info("🎯 Applying specific rules: #{rule_names}")
    end

    Logger.info("")
  end

  @doc """
  Log when no files are found for processing.
  """
  def log_no_files_found do
    Logger.info("📄 No eligible files found for migration")
  end

  @doc """
  Log when no applicable rules are found.
  """
  def log_no_applicable_rules do
    Logger.info("📋 No applicable transformation rules found")
  end

  @doc """
  Log when a file is skipped.
  """
  def log_file_skipped(file, config) do
    if config.verbose do
      Logger.debug("   ⏭️  Skipped: #{file}")
    end
  end

  @doc """
  Log when a file would be changed (dry-run mode).
  """
  def log_file_would_change(file, config) do
    if config.verbose do
      Logger.info("   📄 Would modify: #{file}")
    end
  end

  @doc """
  Log when a file is successfully changed.
  """
  def log_file_changed(file, config) do
    if config.verbose do
      Logger.info("   ✅ Modified: #{file}")
    end
  end

  @doc """
  Log when a file is unchanged.
  """
  def log_file_unchanged(file, config) do
    if config.verbose do
      Logger.debug("   ✅ No changes needed: #{file}")
    end
  end

  @doc """
  Log when there's an error processing a file.
  """
  def log_file_error(file, reason, config) do
    Logger.warning("   ⚠️  Error processing #{file}: #{reason}")

    if config.verbose do
      Logger.debug("   Full error details: #{inspect(reason)}")
    end
  end

  @doc """
  Log the completion of a migration process.
  """
  def log_migration_complete(results, config) do
    Logger.info("")
    Logger.info("📊 Migration Summary:")
    Logger.info("  Total files: #{results.total_files}")
    Logger.info("  Changed: #{results.changed_files}")
    Logger.info("  Unchanged: #{results.unchanged_files}")
    Logger.info("  Skipped: #{results.skipped_files}")

    if results.error_files > 0 do
      Logger.info("  Errors: #{results.error_files}")
    end

    Logger.info("")

    cond do
      config.dry_run and results.changed_files > 0 ->
        Logger.info("🔍 Run without --dry-run to apply changes")

      results.changed_files > 0 and not config.dry_run ->
        Logger.info("✅ Migration completed successfully!")
        Logger.info("💡 Backup files are in: #{config.backup_dir}")
        Logger.info("💡 Run tests to verify the changes work correctly")

      results.changed_files == 0 ->
        Logger.info("✅ No changes were needed - all files are up to date")

      true ->
        Logger.info("✅ Migration process completed")
    end
  end

  @doc """
  Log detailed rule information.
  """
  def log_rule_details(rule, config) do
    if config.verbose do
      Logger.info("🔧 Applying rule: #{rule.name}")
      Logger.info("   Description: #{rule.description}")
      Logger.info("   Category: #{rule.category}")

      unless Enum.empty?(rule.dependencies) do
        deps = Enum.join(rule.dependencies, ", ")
        Logger.info("   Dependencies: #{deps}")
      end
    end
  end

  @doc """
  Log progress for large file sets.
  """
  def log_progress(current, total, config) do
    if config.verbose and rem(current, 10) == 0 do
      percentage = round(current / total * 100)
      Logger.info("📈 Progress: #{current}/#{total} files (#{percentage}%)")
    end
  end

  @doc """
  Display help information for specific rules.
  """
  def display_rule_help(rule) do
    Mix.shell().info("Rule: #{rule.name}")
    Mix.shell().info("Description: #{rule.description}")
    Mix.shell().info("Category: #{rule.category}")

    unless Enum.empty?(rule.dependencies) do
      deps = Enum.join(rule.dependencies, ", ")
      Mix.shell().info("Dependencies: #{deps}")
    end

    Mix.shell().info("")
  end

  @doc """
  Display a preview of changes that would be made.
  """
  def display_change_preview(file, original_content, new_content, config) do
    if config.verbose do
      Logger.info("📍 Preview changes for #{file}:")

      original_lines = String.split(original_content, "\n")
      new_lines = String.split(new_content, "\n")

      # Simple diff display - show lines that changed
      original_lines
      |> Enum.with_index(1)
      |> Enum.each(fn {original_line, line_num} ->
        new_line = Enum.at(new_lines, line_num - 1, "")

        if original_line != new_line do
          Logger.info("   Line #{line_num}:")
          Logger.info("   - #{String.trim(original_line)}")
          Logger.info("   + #{String.trim(new_line)}")
        end
      end)

      Logger.info("")
    end
  end

  @doc """
  Display statistics about the migration run.
  """
  def display_statistics(results, config) do
    if config.verbose do
      Logger.info("📈 Detailed Statistics:")

      # Group results by outcome
      outcomes = Enum.group_by(results.results, &elem(&1, 0))

      Enum.each(outcomes, fn {outcome, files} ->
        count = length(files)
        percentage = round(count / results.total_files * 100)
        Logger.info("  #{format_outcome(outcome)}: #{count} files (#{percentage}%)")
      end)

      Logger.info("")
    end
  end

  # Private functions

  defp format_outcome(:changed), do: "✅ Changed"
  defp format_outcome(:unchanged), do: "⏭️  Unchanged"
  defp format_outcome(:skipped), do: "⏭️  Skipped"
  defp format_outcome(:would_change), do: "📄 Would change"
  defp format_outcome(:error), do: "⚠️  Error"
  defp format_outcome(other), do: "❓ #{other}"
end
