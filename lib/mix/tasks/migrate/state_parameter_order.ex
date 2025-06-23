# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.Migrate.StateParameterOrder do
  @moduledoc """
  Migration tool with serial number: A25W001STAT

  Decode: mix migrate.decode_serial A25W001STAT
  """

  @serial_number "R25W001STAT"

  @moduledoc """
  Fixes State.set_fact parameter order from StateV2 migration.

  During the StateV2 to State migration, some test files retained the old parameter order:
  - Old: State.set_fact(subject, predicate, value)
  - New: State.set_fact(predicate, subject, value)

  This tool automatically detects and fixes these parameter order issues.

  ## Usage

      mix migrate.state_parameter_order [options]

  ## Options

      --dry-run    Show what would be changed without making modifications
      --help       Show this help message

  ## Examples

      # Preview changes without modifying files
      mix migrate.state_parameter_order --dry-run

      # Apply the parameter order fixes
      mix migrate.state_parameter_order
  """

  use Mix.Task
  require Logger

  @shortdoc "Fix State.set_fact parameter order from StateV2 migration"

  def run(args) do
    {opts, _args, _invalid} = OptionParser.parse(args,
      switches: [dry_run: :boolean, help: :boolean],
      aliases: [d: :dry_run, h: :help]
    )

    if opts[:help] do
      show_help()
    else
      migrate_parameter_order(opts[:dry_run] || false)
    end
  end

  defp show_help do
    IO.puts(@moduledoc)
  end

  defp migrate_parameter_order(dry_run) do
    if dry_run do
      Logger.warning("🔍 DRY RUN MODE - No files will be modified")
    end

    Logger.info("🔧 Starting State.set_fact parameter order migration")

    # Find all Elixir files that might contain State.set_fact calls
    files = find_target_files()

    Logger.info("📄 Found #{length(files)} files to check")

    results = Enum.map(files, fn file ->
      process_file(file, dry_run)
    end)

    successful_migrations = Enum.count(results, & &1)

    if successful_migrations > 0 do
      Logger.info("✅ Successfully processed #{successful_migrations} files")

      unless dry_run do
        Logger.info("📁 Original files backed up to .migration_backup directory")
      end
    else
      Logger.info("ℹ️ No State.set_fact parameter order issues found")
    end
  end

  defp find_target_files do
    # Focus on test files where the parameter order issue is most likely
    test_pattern = "test/**/*.exs"
    lib_pattern = "lib/**/*.ex"

    (Path.wildcard(test_pattern) ++ Path.wildcard(lib_pattern))
    |> Enum.filter(&File.exists?/1)
    |> Enum.filter(&contains_state_set_fact?/1)
  end

  defp contains_state_set_fact?(file_path) do
    case File.read(file_path) do
      {:ok, content} -> String.contains?(content, "State.set_fact")
      {:error, _} -> false
    end
  end

  defp process_file(file_path, dry_run) do
    case File.read(file_path) do
      {:ok, content} ->
        new_content = fix_parameter_order(content)

        if new_content != content do
          Logger.debug("📄 Processing #{file_path}")

          if dry_run do
            show_changes_preview(file_path, content, new_content)
          else
            backup_and_write_file(file_path, new_content)
          end

          true
        else
          false
        end

      {:error, reason} ->
        Logger.error("❌ Failed to read #{file_path}: #{reason}")
        false
    end
  end

  defp fix_parameter_order(content) do
    # Pattern to match State.set_fact calls with incorrect parameter order
    # Look for: State.set_fact("subject", "predicate", "value")
    # Convert to: State.set_fact("predicate", "subject", "value")

    # This regex matches State.set_fact calls in chained operations
    pattern = ~r/(\|>\s*State\.set_fact\()"([^"]+)",\s*"([^"]+)",\s*"([^"]+)"\)/

    Regex.replace(pattern, content, fn _full_match, prefix, subject, predicate, value ->
      # Swap subject and predicate parameters
      "#{prefix}\"#{predicate}\", \"#{subject}\", \"#{value}\")"
    end)
  end

  defp show_changes_preview(file_path, old_content, new_content) do
    Logger.info("🔍 Changes for #{file_path}:")

    old_lines = String.split(old_content, "\n")
    new_lines = String.split(new_content, "\n")

    Enum.with_index(old_lines)
    |> Enum.each(fn {old_line, index} ->
      new_line = Enum.at(new_lines, index, "")

      if old_line != new_line do
        Logger.info("  Line #{index + 1}:")
        Logger.info("    - #{String.trim(old_line)}")
        Logger.info("    + #{String.trim(new_line)}")
      end
    end)
  end

  defp backup_and_write_file(file_path, new_content) do
    # Create backup directory
    backup_dir = ".migration_backup"
    File.mkdir_p!(backup_dir)

    # Create backup file
    backup_path = Path.join(backup_dir, Path.basename(file_path) <> ".bak")
    case File.read(file_path) do
      {:ok, original_content} ->
        File.write!(backup_path, original_content)
        Logger.debug("✅ Backed up #{file_path} to #{backup_path}")
      {:error, reason} ->
        Logger.error("❌ Failed to backup #{file_path}: #{reason}")
        false
    end

    # Write the new content
    case File.write(file_path, new_content) do
      :ok ->
        Logger.info("✅ Fixed parameter order in #{file_path}")
        true
      {:error, reason} ->
        Logger.error("❌ Failed to write #{file_path}: #{reason}")
        false
    end
  end
end
