# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.Migrate.DatetimeDeprecation do
  @serial_number "R25W004DTDP"
  @doc "Returns the module's serial number for tracking and identification."
  @spec serial_number() :: String.t()
  def serial_number() do
    @serial_number
  end

  @moduledoc """
  Fix DateTime deprecation warnings in timeline interval function calls.

  This task fixes deprecation warnings from AriaEngine.Timeline.Interval.new_fixed_schedule/3
  calls that use DateTime structs instead of ISO 8601 strings.

  ## Usage

      mix migrate.datetime_deprecation                    # Full migration
      mix migrate.datetime_deprecation --dry-run         # Preview changes only
      mix migrate.datetime_deprecation --backup-dir=.bak # Custom backup location

  ## What it does

  - Finds calls to DateTime.from_naive!(~N[...], "Etc/UTC")
  - Converts them to ISO 8601 string literals
  - Handles both regular code and test files
  - Uses AST parsing for accurate transformations

  ## Example transformation

  Before:
  ```elixir
  AriaEngine.Timeline.Interval.new_fixed_schedule(
    DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC"),
    DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC"),
    label: "Test"
  )
  ```

  After:
  ```elixir
  AriaEngine.Timeline.Interval.new_fixed_schedule(
    "2025-01-01T10:00:00Z",
    "2025-01-01T12:00:00Z",
    label: "Test"
  )
  ```
  """

  use Mix.Task
  require Logger
  alias Mix.Tasks.Migrate.AstTransformer

  @shortdoc "Fix DateTime deprecation warnings in timeline interval calls"
  @switches dry_run: :boolean, backup_dir: :string
  @aliases d: :dry_run, b: :backup_dir

  def run(args) do
    {opts, _args, _invalid} = OptionParser.parse(args, switches: @switches, aliases: @aliases)
    dry_run = opts[:dry_run] || false
    backup_dir = opts[:backup_dir] || ".migration_backup"

    Logger.info("🔧 DateTime Deprecation Migration")
    Logger.info("=================================")

    if dry_run do
      Logger.info("🔍 DRY RUN MODE - No files will be modified")
    else
      Logger.info("📁 Backup directory: #{backup_dir}")
      create_backup_dir(backup_dir)
    end

    migrate_datetime_calls(dry_run, backup_dir)
    Logger.info("✅ DateTime deprecation migration completed!")
  end

  defp should_skip_file?(file) do
    String.contains?(file, "migrate") or String.contains?(file, "migration") or
      String.contains?(file, ".migration_backup") or String.contains?(file, "_fixer") or
      String.ends_with?(file, "_fixer.exs") or String.ends_with?(file, "_migration.exs")
  end

  defp create_backup_dir(backup_dir) do
    if not File.exists?(backup_dir) do
      File.mkdir_p!(backup_dir)
      Logger.info("📁 Created backup directory: #{backup_dir}")
    end
  end

  defp migrate_datetime_calls(dry_run, backup_dir) do
    Logger.info("Migrating DateTime.from_naive! calls...")
    files_to_check = Path.wildcard("**/*.{ex,exs}", match_dot: true)

    transformation_rules = AstTransformer.timeline_interval_rules()

    Enum.each(files_to_check, fn file ->
      if File.exists?(file) and not should_skip_file?(file) do
        content = File.read!(file)

        if needs_migration?(content) do
          if dry_run do
            Logger.debug("   📄 Would migrate: #{file}")
            preview_changes(content, file, transformation_rules)
          else
            backup_file(file, backup_dir)

            case AstTransformer.transform_code(content, transformation_rules) do
              {:changed, updated_content} ->
                File.write!(file, updated_content)
                Logger.debug("   ✅ Migrated: #{file}")

              :unchanged ->
                Logger.debug("   ⏭️  No changes needed: #{file}")

              {:error, reason} ->
                Logger.warning("   ⚠️  Error transforming #{file}: #{reason}")
            end
          end
        end
      end
    end)
  end

  defp needs_migration?(content) do
    AstTransformer.needs_timeline_interval_transformation?(content)
  end

  defp preview_changes(content, file, transformation_rules) do
    case AstTransformer.transform_code(content, transformation_rules) do
      {:changed, new_content} ->
        Logger.info("   📍 Changes for #{file}:")
        show_diff_preview(content, new_content)

      :unchanged ->
        Logger.info("   ⏭️  No changes needed for #{file}")

      {:error, reason} ->
        Logger.warning("   ⚠️  Error analyzing #{file}: #{reason}")
    end
  end

  defp show_diff_preview(original, transformed) do
    original_lines = String.split(original, "\n")
    transformed_lines = String.split(transformed, "\n")

    # Find lines that changed
    original_lines
    |> Enum.with_index(1)
    |> Enum.each(fn {original_line, line_num} ->
      transformed_line = Enum.at(transformed_lines, line_num - 1, "")

      if original_line != transformed_line and
         (String.contains?(original_line, "DateTime.from_naive!") or
          String.contains?(original_line, "new_fixed_schedule")) do
        Logger.info("      Line #{line_num}:")
        Logger.info("      - #{String.trim(original_line)}")
        Logger.info("      + #{String.trim(transformed_line)}")
      end
    end)
  end

  defp backup_file(file, backup_dir) do
    backup_path = Path.join(backup_dir, file)
    backup_dir_path = Path.dirname(backup_path)
    File.mkdir_p!(backup_dir_path)
    File.cp!(file, backup_path)
  end
end
