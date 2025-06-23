# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.Migrate.TimelineIntervalApi do
  @moduledoc """
  Migration tool with serial number: R25W007TINT

  Decode: mix migrate.decode_serial R25W007TINT

  Migrate deprecated AriaEngine.Timeline.Interval.new/3 calls to new_fixed_schedule/3.

  This task fixes the deprecation warning:
  "AriaEngine.Timeline.Interval.new/3 with DateTime structs is deprecated.
   Use new_fixed_schedule/3 with ISO 8601 strings instead."

  ## Usage

      mix migrate.timeline_interval_api                    # Full migration
      mix migrate.timeline_interval_api --dry-run         # Preview changes only
      mix migrate.timeline_interval_api --backup-dir=.bak # Custom backup location

  ## What it does

  Uses AST-based transformations to:
  - Replace `Interval.new(datetime1, datetime2)` with `Interval.new_fixed_schedule(iso1, iso2)`
  - Replace `Interval.new(datetime1, datetime2, opts)` with `Interval.new_fixed_schedule(iso1, iso2, opts)`
  - Wrap DateTime arguments with `DateTime.to_iso8601()` calls
  - Handle both fully-qualified and aliased module calls
  - Preserve code formatting and comments

  ## AST-based approach

  This migration uses AST transformations instead of regex patterns for:
  - Syntactic correctness
  - Proper handling of complex expressions
  - Context-aware transformations
  - Preservation of code structure
  """

  @serial_number "R25W007TINT"

  use Mix.Task

  require Logger

  alias Mix.Tasks.Migrate.Base
  alias Mix.Tasks.Migrate.AstTransformer

  @shortdoc "Migrate deprecated Interval.new/3 to new_fixed_schedule/3"

  def run(args) do
    {opts, _args, _invalid} = Base.parse_args(args)

    if opts[:help] do
      show_help()
    else
      dry_run = opts[:dry_run] || false
      backup_dir = opts[:backup_dir] || ".migration_backup"

      Base.log_migration_start("Timeline Interval API Migration", dry_run, backup_dir)

      migrate_timeline_interval_calls(dry_run, backup_dir)

      Base.log_migration_complete("Timeline Interval API Migration", dry_run, backup_dir)

      if not dry_run do
        Logger.info("")
        Logger.info("💡 Run 'mix test' to verify all tests pass")
        Logger.info("💡 The deprecation warnings should now be resolved")
      end
    end
  end

  defp show_help do
    IO.puts(@moduledoc)
  end

  defp migrate_timeline_interval_calls(dry_run, backup_dir) do
    Logger.info("Migrating Timeline.Interval.new calls to new_fixed_schedule...")

    files = Base.discover_elixir_files()
    |> Enum.filter(fn file ->
      content = File.read!(file)
      AstTransformer.needs_timeline_interval_transformation?(content) or
      needs_doctest_transformation?(content)
    end)

    if Enum.empty?(files) do
      Logger.info("📊 No files found with Timeline.Interval.new calls or doctests")
    else
      Logger.info("📊 Found #{length(files)} files with Timeline.Interval.new calls or doctests")

      transformation_fn = fn content ->
        # Use enhanced transformation that handles both code and doctests
        AstTransformer.transform_code_and_doctests(content, AstTransformer.timeline_interval_rules())
      end

      Base.process_files(files, transformation_fn, dry_run, backup_dir)
    end
  end

  defp needs_doctest_transformation?(content) do
    # Check for doctest patterns that use deprecated Timeline.Interval.new
    String.contains?(content, "iex>") and
    String.contains?(content, "Interval.new(") and
    String.contains?(content, "DateTime.from_naive!")
  end
end
