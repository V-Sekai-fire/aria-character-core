# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.Migrate.TimelineIntervalApi do
  @compile {:no_warn_unused, [:serial_number]}
  @moduledoc "Migration tool with serial number: R25W007TINT\n\nDecode: mix migrate.decode_serial R25W007TINT\n\nMigrate deprecated AriaEngine.Timeline.Interval.new/3 calls to new_fixed_schedule/3.\n\nThis task fixes the deprecation warning:\n\"AriaEngine.Timeline.Interval.new/3 with DateTime structs is deprecated.\n Use new_fixed_schedule/3 with ISO 8601 strings instead.\"\n\n## Usage\n\n    mix migrate.timeline_interval_api                    # Full migration\n    mix migrate.timeline_interval_api --dry-run         # Preview changes only\n    mix migrate.timeline_interval_api --backup-dir=.bak # Custom backup location\n\n## What it does\n\nUses AST-based transformations to:\n- Replace `Interval.new(datetime1, datetime2)` with `Interval.new_fixed_schedule(iso1, iso2)`\n- Replace `Interval.new(datetime1, datetime2, opts)` with `Interval.new_fixed_schedule(iso1, iso2, opts)`\n- Wrap DateTime arguments with `DateTime.to_iso8601()` calls\n- Handle both fully-qualified and aliased module calls\n- Preserve code formatting and comments\n\n## AST-based approach\n\nThis migration uses AST transformations instead of regex patterns for:\n- Syntactic correctness\n- Proper handling of complex expressions\n- Context-aware transformations\n- Preservation of code structure\n"
  @serial_number "R25W007TINT"
  @doc "Returns the module's serial number for tracking and identification."
  @spec serial_number() :: String.t()
  def serial_number() do
    @serial_number
  end

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

    files =
      Base.discover_elixir_files()
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
        AstTransformer.transform_code_and_doctests(
          content,
          AstTransformer.timeline_interval_rules()
        )
      end

      Base.process_files(files, transformation_fn, dry_run, backup_dir)
    end
  end

  defp needs_doctest_transformation?(content) do
    String.contains?(content, "iex>") and String.contains?(content, "Interval.new(") and
      String.contains?(content, "DateTime.from_naive!")
  end
end
