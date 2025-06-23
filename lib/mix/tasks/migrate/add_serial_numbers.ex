defmodule Mix.Tasks.Migrate.AddSerialNumbers do
  @moduledoc """
  Add industrial-grade serial numbers to Aria migration tools.

  ## Usage

      mix migrate.add_serial_numbers
      mix migrate.add_serial_numbers --dry-run

  ## Serial Number Format

  Generates serial numbers in standard format: `[F][YY][W][UUU][MMMM]`

  - F: Factory/Organization (R=aRia Character Core)
  - YY: Year (25=2025)
  - W: Week (encoded using standard system)
  - UUU: Sequential unit number (001, 002, etc.)
  - MMMM: Tool code derived from filename

  ## Features

  - Scans existing migration tools in lib/mix/tasks/migrate/
  - Generates unique serial numbers following character validation rules
  - Adds @serial_number module attribute to each tool
  - Updates module documentation with serial information
  - Backs up original files before modification
  - Blocks deps folder from processing
  - Uses Timex for accurate date calculations

  ## Examples

      # Add serial numbers to all migration tools
      mix migrate.add_serial_numbers

      # Preview changes without applying them
      mix migrate.add_serial_numbers --dry-run
  """

  use Mix.Task
  alias Mix.Tasks.Migrate.SerialRegistry

  @shortdoc "Add industrial-grade serial numbers to migration tools"

  @switches [
    dry_run: :boolean,
    help: :boolean,
    membrane: :boolean
  ]

  @aliases [
    d: :dry_run,
    h: :help,
    m: :membrane
  ]

  def run(args) do
    {opts, _args, _invalid} = OptionParser.parse(args, switches: @switches, aliases: @aliases)

    if opts[:help] do
      show_help()
    else
      add_serial_numbers(opts)
    end
  end

  defp add_serial_numbers(opts) do
    factory = "R"
    dry_run = opts[:dry_run] || false
    membrane = opts[:membrane] || false

    component_type = if membrane, do: "Membrane pipeline elements", else: "migration tools"
    Mix.shell().info("Adding industrial-grade serial numbers to #{component_type}...")
    Mix.shell().info("Factory: #{decode_factory(factory)}")
    Mix.shell().info("Mode: #{if dry_run, do: "DRY RUN", else: "LIVE"}")
    Mix.shell().info("")

    files = if membrane, do: find_membrane_files(), else: find_migration_files()

    if Enum.empty?(files) do
      dir = if membrane, do: "lib/aria_engine/membrane/", else: "lib/mix/tasks/migrate/"
      Mix.shell().info("No #{component_type} found in #{dir}")
      :ok
    else
      current_week = get_current_week()
      year = get_current_year()
      start_sequence = if membrane, do: get_next_sequence_for_week(current_week), else: 1

      Mix.shell().info("Current week: #{current_week} (#{year})")
      Mix.shell().info("Found #{length(files)} #{component_type}:")
      Mix.shell().info("")

      files
      |> Enum.with_index(start_sequence)
      |> Enum.each(fn {file, index} ->
        process_file(file, factory, year, current_week, index, dry_run)
      end)

      if dry_run do
        Mix.shell().info("")
        Mix.shell().info("DRY RUN completed. No files were modified.")
        Mix.shell().info("Run without --dry-run to apply changes.")
      else
        Mix.shell().info("")
        Mix.shell().info("Serial numbers added successfully!")
        Mix.shell().info("Use 'mix migrate.decode_serial <serial>' to decode any serial number.")
      end
    end
  end

  defp find_migration_files do
    migrate_dir = "lib/mix/tasks/migrate"

    if File.exists?(migrate_dir) do
      migrate_dir
      |> File.ls!()
      |> Enum.filter(fn file ->
        String.ends_with?(file, ".ex") and
          file != "serial_registry.ex" and
          file != "add_serial_numbers.ex" and
          file != "decode_serial.ex" and
          not String.starts_with?(file, ".")
      end)
      |> Enum.map(&Path.join(migrate_dir, &1))
      |> Enum.filter(&File.exists?/1)
      |> Enum.reject(&is_deps_file?/1)
    else
      []
    end
  end

  defp find_membrane_files do
    membrane_dir = "lib/aria_engine/membrane"

    if File.exists?(membrane_dir) do
      find_elixir_files_recursive(membrane_dir)
      |> Enum.reject(&is_deps_file?/1)
    else
      []
    end
  end

  defp find_elixir_files_recursive(dir) do
    dir
    |> File.ls!()
    |> Enum.flat_map(fn item ->
      path = Path.join(dir, item)

      cond do
        File.dir?(path) ->
          find_elixir_files_recursive(path)

        String.ends_with?(item, ".ex") and not String.starts_with?(item, ".") ->
          [path]

        true ->
          []
      end
    end)
  end

  defp get_next_sequence_for_week(week) do
    SerialRegistry.next_sequence(week)
  end

  defp is_deps_file?(file_path) do
    String.contains?(file_path, "/deps/") or String.contains?(file_path, "\\deps\\")
  end

  defp process_file(file_path, factory, year, week, sequence, dry_run) do
    filename = Path.basename(file_path)
    tool_code = SerialRegistry.generate_tool_code(filename)
    week_char = SerialRegistry.encode_week(week)
    serial = generate_serial(factory, year, week_char, sequence, tool_code)

    Mix.shell().info("#{sequence}. #{filename}")
    Mix.shell().info("   Serial: #{serial}")
    Mix.shell().info("   Tool Code: #{tool_code}")

    if dry_run do
      Mix.shell().info("   [DRY RUN] Would add serial number")
    else
      case add_serial_to_file(file_path, serial) do
        :ok ->
          Mix.shell().info("   ✅ Serial number added")

        {:error, reason} ->
          Mix.shell().error("   ❌ Failed: #{reason}")
      end
    end

    Mix.shell().info("")
  end

  defp generate_serial(factory, year, week_char, sequence, tool_code) do
    year_str = String.slice(to_string(year), -2, 2)
    sequence_str = String.pad_leading(to_string(sequence), 3, "0")
    "#{factory}#{year_str}#{week_char}#{sequence_str}#{tool_code}"
  end

  defp add_serial_to_file(file_path, serial) do
    with {:ok, content} <- File.read(file_path),
         {:ok, backup_path} <- create_backup(file_path),
         {:ok, new_content} <- inject_serial(content, serial),
         :ok <- File.write(file_path, new_content) do
      Mix.shell().info("   📁 Backup: #{backup_path}")
      :ok
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp create_backup(file_path) do
    backup_path = file_path <> ".bak"

    case File.copy(file_path, backup_path) do
      {:ok, _} -> {:ok, backup_path}
      {:error, reason} -> {:error, "Failed to create backup: #{reason}"}
    end
  end

  defp inject_serial(content, serial) do
    lines = String.split(content, "\n")

    case find_injection_point(lines) do
      {:moduledoc, line_index} ->
        inject_after_moduledoc(lines, line_index, serial)

      {:defmodule, line_index} ->
        inject_after_defmodule(lines, line_index, serial)

      :not_found ->
        {:error, "Could not find suitable injection point"}
    end
  end

  defp find_injection_point(lines) do
    lines
    |> Enum.with_index()
    |> Enum.find_value(fn {line, index} ->
      cond do
        String.contains?(line, "@moduledoc") ->
          find_moduledoc_end(lines, index)

        String.contains?(line, "defmodule") ->
          {:defmodule, index}

        true ->
          nil
      end
    end) || :not_found
  end

  defp find_moduledoc_end(lines, start_index) do
    lines
    |> Enum.drop(start_index)
    |> Enum.with_index(start_index)
    |> Enum.find_value(fn {line, index} ->
      if String.contains?(line, "\"\"\"") and index > start_index do
        {:moduledoc, index}
      end
    end)
  end

  defp inject_after_moduledoc(lines, moduledoc_end_index, serial) do
    {before, after_lines} = Enum.split(lines, moduledoc_end_index + 1)

    serial_lines = [
      "",
      "  @serial_number \"#{serial}\"",
      ""
    ]

    new_content =
      (before ++ serial_lines ++ after_lines)
      |> Enum.join("\n")

    {:ok, new_content}
  end

  defp inject_after_defmodule(lines, defmodule_index, serial) do
    {before, after_lines} = Enum.split(lines, defmodule_index + 1)

    serial_lines = [
      "  @moduledoc \"\"\"",
      "  Migration tool with serial number: #{serial}",
      "",
      "  Decode: mix migrate.decode_serial #{serial}",
      "  \"\"\"",
      "",
      "  @serial_number \"#{serial}\"",
      ""
    ]

    new_content =
      (before ++ serial_lines ++ after_lines)
      |> Enum.join("\n")

    {:ok, new_content}
  end

  defp get_current_week do
    if Code.ensure_loaded?(Timex) do
      Timex.iso_week(Date.utc_today()) |> elem(1)
    else
      # Basic week calculation
      today = Date.utc_today()
      start_of_year = Date.new!(today.year, 1, 1)
      days_diff = Date.diff(today, start_of_year)
      div(days_diff, 7) + 1
    end
  end

  defp get_current_year do
    Date.utc_today().year
  end

  defp decode_factory("R"), do: "aRia Character Core"
  defp decode_factory(f), do: "Unknown Factory (#{f})"

  defp show_help do
    Mix.shell().info(@moduledoc)
  end
end
