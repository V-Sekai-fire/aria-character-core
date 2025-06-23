# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.Migrate.LoggerConversion do
  @moduledoc """
  Convert IO.puts calls to Logger calls in migration tasks.

  This task automatically updates migration task files to use proper Logger calls
  instead of IO.puts for better logging practices and configurability.

  ## Usage

      mix migrate.logger_conversion                    # Full conversion
      mix migrate.logger_conversion --dry-run         # Preview changes only
      mix migrate.logger_conversion --backup-dir=.bak # Custom backup location

  ## What it does

  - Converts IO.puts to appropriate Logger calls (info, debug, warn)
  - Adds required Logger imports to modules
  - Preserves help text as IO.puts (user-facing documentation)
  - Maintains emoji and formatting for readability

  ## Conversion Rules

  - Progress messages (🔧, ✅) → Logger.info
  - File operations (📄, ✅ with filenames) → Logger.debug
  - Dry run warnings (🔍) → Logger.warn
  - Help text in show_help() functions → Keep as IO.puts
  """

  use Mix.Task

  @shortdoc "Convert IO.puts to Logger calls in migration tasks"

  @switches [
    dry_run: :boolean,
    backup_dir: :string,
    help: :boolean
  ]

  @aliases [
    d: :dry_run,
    b: :backup_dir,
    h: :help
  ]

  def run(args) do
    {opts, _args, _invalid} = OptionParser.parse(args, switches: @switches, aliases: @aliases)

    if opts[:help] do
      show_help()
    else
      dry_run = opts[:dry_run] || false
      backup_dir = opts[:backup_dir] || ".migration_backup"

      IO.puts("🔧 Migration Logger Conversion Tool")
      IO.puts("==================================")

      if dry_run do
        IO.puts("🔍 DRY RUN MODE - No files will be modified")
      else
        IO.puts("📁 Backup directory: #{backup_dir}")
        create_backup_dir(backup_dir)
      end

      IO.puts("")

      convert_migration_tasks(dry_run, backup_dir)

      IO.puts("")
      IO.puts("✅ Logger conversion completed!")

      if not dry_run do
        IO.puts("")
        IO.puts("💡 Migration tasks now use Logger instead of IO.puts")
        IO.puts("💡 Backup files are in: #{backup_dir}")
      end
    end
  end

  defp show_help do
    IO.puts(@moduledoc)
  end

  defp create_backup_dir(backup_dir) do
    if not File.exists?(backup_dir) do
      File.mkdir_p!(backup_dir)
      IO.puts("📁 Created backup directory: #{backup_dir}")
    end
  end

  defp convert_migration_tasks(dry_run, backup_dir) do
    IO.puts("Converting migration tasks to use Logger...")

    migration_files = [
      "lib/mix/tasks/migrate/state_v2.ex",
      "lib/mix/tasks/migrate/statev2_api.ex",
      "lib/mix/tasks/migrate/state_parameters.ex",
      "lib/mix/tasks/migrate/goal_tuples.ex"
    ]

    Enum.each(migration_files, fn file ->
      if File.exists?(file) do
        convert_file(file, dry_run, backup_dir)
      else
        IO.puts("   ⚠️  File not found: #{file}")
      end
    end)
  end

  defp convert_file(file, dry_run, backup_dir) do
    content = File.read!(file)

    if needs_conversion?(content) do
      if dry_run do
        IO.puts("   📄 Would convert: #{file}")
      else
        backup_file(file, backup_dir)

        updated_content = content
        |> add_logger_require()
        |> convert_io_puts_to_logger()

        File.write!(file, updated_content)
        IO.puts("   ✅ Converted: #{file}")
      end
    else
      IO.puts("   ✅ Already converted: #{file}")
    end
  end

  defp needs_conversion?(content) do
    # Check if file has IO.puts calls outside of show_help functions
    # and doesn't already have Logger calls
    has_io_puts = String.contains?(content, "IO.puts(") and
                  not String.contains?(content, "Logger.info(")

    # Don't convert if it's only help text
    lines = String.split(content, "\n")
    io_puts_lines = Enum.filter(lines, &String.contains?(&1, "IO.puts("))

    # Check if IO.puts calls are outside show_help function
    non_help_io_puts = Enum.any?(io_puts_lines, fn line ->
      not String.contains?(line, "@moduledoc") and
      not in_show_help_function?(content, line)
    end)

    has_io_puts and non_help_io_puts
  end

  defp in_show_help_function?(content, line) do
    # Simple heuristic: if the line is within a show_help function
    lines = String.split(content, "\n")
    line_index = Enum.find_index(lines, &(&1 == line))

    if line_index do
      # Look backwards for show_help function definition
      preceding_lines = Enum.take(lines, line_index)
      |> Enum.reverse()

      show_help_start = Enum.find_index(preceding_lines, &String.contains?(&1, "defp show_help"))
      function_end = Enum.find_index(preceding_lines, &String.match?(&1, ~r/^\s*end\s*$/))

      # Ensure we return a boolean - if show_help_start is nil, we're not in show_help
      case {show_help_start, function_end} do
        {nil, _} -> false
        {_start_idx, nil} -> true  # Found show_help, no end found
        {start_idx, end_idx} -> start_idx < end_idx  # show_help comes before end
      end
    else
      false
    end
  end

  defp add_logger_require(content) do
    if String.contains?(content, "require Logger") do
      content
    else
      # Add require Logger after the use Mix.Task line
      String.replace(content, ~r/(use Mix\.Task\n)/, "\\1\n  require Logger\n")
    end
  end

  defp convert_io_puts_to_logger(content) do
    content
    # Convert progress messages to Logger.info
    |> String.replace(~r/IO\.puts\("([🔧✅📁💡][^"]*?)"\)/, "Logger.info(\"\\1\")")

    # Convert file operation messages to Logger.debug
    |> String.replace(~r/IO\.puts\("(\s*[📄✅⚠️][^"]*?)"\)/, "Logger.debug(\"\\1\")")

    # Convert dry run and warning messages to Logger.warn
    |> String.replace(~r/IO\.puts\("([🔍][^"]*?)"\)/, "Logger.warn(\"\\1\")")

    # Convert separator lines and headers to Logger.info
    |> String.replace(~r/IO\.puts\("(=+)"\)/, "Logger.info(\"\\1\")")
    |> String.replace(~r/IO\.puts\(""\)/, "Logger.info(\"\")")

    # Convert remaining IO.puts to Logger.info (except in show_help)
    |> convert_remaining_io_puts()
  end

  defp convert_remaining_io_puts(content) do
    lines = String.split(content, "\n")

    converted_lines = Enum.map(lines, fn line ->
      if String.contains?(line, "IO.puts(") and
         not in_show_help_context?(content, line) and
         not String.contains?(line, "@moduledoc") do
        String.replace(line, ~r/IO\.puts\(/, "Logger.info(")
      else
        line
      end
    end)

    Enum.join(converted_lines, "\n")
  end

  defp in_show_help_context?(content, target_line) do
    lines = String.split(content, "\n")
    line_index = Enum.find_index(lines, &(&1 == target_line))

    if line_index do
      # Check if we're inside a show_help function
      preceding_lines = Enum.take(lines, line_index + 1)
      |> Enum.reverse()

      # Find the most recent function definition
      recent_function = Enum.find(preceding_lines, fn line ->
        String.contains?(line, "defp show_help") or
        String.match?(line, ~r/^\s*def\w*\s+\w+/) or
        String.match?(line, ~r/^\s*end\s*$/)
      end)

      # Ensure we return a boolean
      case recent_function do
        nil -> false
        line -> String.contains?(line, "show_help")
      end
    else
      false
    end
  end

  defp backup_file(file, backup_dir) do
    backup_path = Path.join(backup_dir, file)
    backup_dir_path = Path.dirname(backup_path)

    File.mkdir_p!(backup_dir_path)
    File.cp!(file, backup_path)
  end
end
