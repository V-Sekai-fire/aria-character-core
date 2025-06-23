defmodule Mix.Tasks.Migrate.LoggerConversion do
  @compile {:no_warn_unused, [:serial_number]}
  @moduledoc "Migration tool with serial number: A25W003LXGG\n\nDecode: mix migrate.decode_serial A25W003LXGG\n"
  @serial_number "R25W003LXGG"
  @doc "Returns the module's serial number for tracking and identification."
  @spec serial_number() :: String.t()
  def serial_number() do
    @serial_number
  end

  @moduledoc "Convert IO.puts calls to Logger calls in migration tasks.\n\nThis task automatically updates migration task files to use proper Logger calls\ninstead of IO.puts for better logging practices and configurability.\n\n## Usage\n\n    mix migrate.logger_conversion                    # Full conversion\n    mix migrate.logger_conversion --dry-run         # Preview changes only\n    mix migrate.logger_conversion --backup-dir=.bak # Custom backup location\n\n## What it does\n\n- Converts IO.puts to appropriate Logger calls (info, debug, warn)\n- Adds required Logger imports to modules\n- Preserves help text as IO.puts (user-facing documentation)\n- Maintains emoji and formatting for readability\n\n## Conversion Rules\n\n- Progress messages (🔧, ✅) → Logger.info\n- File operations (📄, ✅ with filenames) → Logger.debug\n- Dry run warnings (🔍) → Logger.warn\n- Help text in show_help() functions → Keep as IO.puts\n"
  use Mix.Task
  @shortdoc "Convert IO.puts to Logger calls in migration tasks"
  @switches dry_run: :boolean, backup_dir: :string, help: :boolean
  @aliases d: :dry_run, b: :backup_dir, h: :help
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
        updated_content = content |> add_logger_require() |> convert_io_puts_to_logger()
        File.write!(file, updated_content)
        IO.puts("   ✅ Converted: #{file}")
      end
    else
      IO.puts("   ✅ Already converted: #{file}")
    end
  end

  defp needs_conversion?(content) do
    has_io_puts =
      String.contains?(content, "IO.puts(") and not String.contains?(content, "Logger.info(")

    lines = String.split(content, "\n")
    io_puts_lines = Enum.filter(lines, &String.contains?(&1, "IO.puts("))

    non_help_io_puts =
      Enum.any?(io_puts_lines, fn line ->
        not String.contains?(line, "@moduledoc") and not in_show_help_function?(content, line)
      end)

    has_io_puts and non_help_io_puts
  end

  defp in_show_help_function?(content, line) do
    lines = String.split(content, "\n")
    line_index = Enum.find_index(lines, &(&1 == line))

    if line_index do
      preceding_lines = Enum.take(lines, line_index) |> Enum.reverse()
      show_help_start = Enum.find_index(preceding_lines, &String.contains?(&1, "defp show_help"))
      function_end = Enum.find_index(preceding_lines, &String.match?(&1, ~r/^\s*end\s*$/))

      case {show_help_start, function_end} do
        {nil, _} -> false
        {_start_idx, nil} -> true
        {start_idx, end_idx} -> start_idx < end_idx
      end
    else
      false
    end
  end

  defp add_logger_require(content) do
    if String.contains?(content, "require Logger") do
      content
    else
      String.replace(content, ~r/(use Mix\.Task\n)/, "\\1\n  require Logger\n")
    end
  end

  defp convert_io_puts_to_logger(content) do
    content
    |> String.replace(~r/IO\.puts\("([🔧✅📁💡][^"]*?)"\)/, "Logger.info(\"\\1\")")
    |> String.replace(~r/IO\.puts\("(\s*[📄✅⚠️][^"]*?)"\)/, "Logger.debug(\"\\1\")")
    |> String.replace(~r/IO\.puts\("([🔍][^"]*?)"\)/, "Logger.warn(\"\\1\")")
    |> String.replace(~r/IO\.puts\("(=+)"\)/, "Logger.info(\"\\1\")")
    |> String.replace(~r/IO\.puts\(""\)/, "Logger.info(\"\")")
    |> convert_remaining_io_puts()
  end

  defp convert_remaining_io_puts(content) do
    lines = String.split(content, "\n")

    converted_lines =
      Enum.map(lines, fn line ->
        if String.contains?(line, "IO.puts(") and not in_show_help_context?(content, line) and
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
      preceding_lines = Enum.take(lines, line_index + 1) |> Enum.reverse()

      recent_function =
        Enum.find(preceding_lines, fn line ->
          String.contains?(line, "defp show_help") or String.match?(line, ~r/^\s*def\w*\s+\w+/) or
            String.match?(line, ~r/^\s*end\s*$/)
        end)

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