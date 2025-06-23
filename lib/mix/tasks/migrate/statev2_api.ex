# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.Migrate.Statev2Api do
  @moduledoc """
  Migrate StateV2 API calls to State API.

  This task converts StateV2 function calls to their State equivalents with proper parameter ordering.

  ## Usage

      mix migrate.statev2_api                    # Full migration
      mix migrate.statev2_api --dry-run         # Preview changes only
      mix migrate.statev2_api --backup-dir=.bak # Custom backup location

  ## What it does

  - StateV2.update_fact -> State.set_fact (with parameter reordering)
  - StateV2.matches_exactly? -> State.matches? (with parameter reordering)
  - StateV2.get_fact -> State.get_fact (with parameter reordering)
  """

  use Mix.Task

  require Logger

  @shortdoc "Migrate StateV2 API calls to State API"

  @switches [
    dry_run: :boolean,
    backup_dir: :string
  ]

  @aliases [
    d: :dry_run,
    b: :backup_dir
  ]

  def run(args) do
    {opts, _args, _invalid} = OptionParser.parse(args, switches: @switches, aliases: @aliases)

    dry_run = opts[:dry_run] || false
    backup_dir = opts[:backup_dir] || ".migration_backup"

    Logger.info("🔧 StateV2 API Migration")
    Logger.info("=======================")

    if dry_run do
      Logger.info("🔍 DRY RUN MODE - No files will be modified")
    else
      Logger.info("📁 Backup directory: #{backup_dir}")
      create_backup_dir(backup_dir)
    end

    migrate_statev2_api(dry_run, backup_dir)

    Logger.info("✅ StateV2 API migration completed!")
  end

  defp should_skip_file?(file) do
    String.contains?(file, "migrate") or
    String.contains?(file, "migration") or
    String.contains?(file, ".migration_backup") or
    String.contains?(file, "statev2_fixer") or
    String.ends_with?(file, "_fixer.exs") or
    String.ends_with?(file, "_migration.exs")
  end

  defp create_backup_dir(backup_dir) do
    if not File.exists?(backup_dir) do
      File.mkdir_p!(backup_dir)
      Logger.info("📁 Created backup directory: #{backup_dir}")
    end
  end

  defp migrate_statev2_api(dry_run, backup_dir) do
    Logger.info("Migrating StateV2 API calls...")

    files_to_check = Path.wildcard("**/*.{ex,exs}", match_dot: true)

    Enum.each(files_to_check, fn file ->
      if File.exists?(file) and not should_skip_file?(file) do
        content = File.read!(file)

        if String.contains?(content, "StateV2.") do
          if dry_run do
            Logger.debug("   📄 Would migrate: #{file}")
          else
            backup_file(file, backup_dir)

            updated_content = content
            # State.set_fact(state, predicate, subject, value) -> State.set_fact(state, predicate, subject, value)
            |> String.replace(
              ~r/StateV2\.update_fact\(([^,]+),\s*([^,]+),\s*([^,]+),\s*([^)]+)\)/,
              "State.set_fact(\\1, \\3, \\2, \\4)"
            )
            # State.matches?(state, predicate, subject, value) -> State.matches?(state, predicate, subject, value)
            |> String.replace(
              ~r/StateV2\.matches_exactly\?\(([^,]+),\s*([^,]+),\s*([^,]+),\s*([^)]+)\)/,
              "State.matches?(\\1, \\3, \\2, \\4)"
            )
            # StateV2.get_fact -> State.get_fact (with parameter reordering)
            |> String.replace(
              ~r/StateV2\.get_fact\(([^,]+),\s*([^,]+),\s*([^)]+)\)/,
              "State.get_fact(\\1, \\3, \\2)"
            )

            File.write!(file, updated_content)
            Logger.debug("   ✅ Migrated: #{file}")
          end
        end
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
