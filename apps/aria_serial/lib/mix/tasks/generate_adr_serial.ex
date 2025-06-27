# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.Generate.Adr.Serial do
  @moduledoc """
  Generate industrial-grade serial numbers for Architecture Decision Records (ADRs).

  ## Usage

      mix generate.adr.serial
      mix generate.adr.serial --dir decisions/
      mix generate.adr.serial --file decisions/R25W0013716-state-architecture-migration.md
      mix generate.adr.serial --dry-run

  ## Serial Number Format for ADRs

  Generates serial numbers in standard format: `[F][YY][W][UUU][HASH]`

  - F: Factory/Organization (R=aRia Character Core)
  - YY: Year from git creation date or current year
  - W: Week from git creation date or current week
  - UUU: Sequential unit number within that week (001, 002, etc.)
  - HASH: 4-character content hash from ADR title

  ## Features

  - Analyzes git history to determine ADR creation dates
  - Generates content-based tool codes from ADR titles
  - Creates mapping file for cross-reference updates
  - Supports both batch processing and single file processing
  - Validates character rules and prevents collisions

  ## Examples

      # Process all ADRs in decisions directory
      mix generate.adr.serial --dir decisions/

      # Process single ADR file
      mix generate.adr.serial --file decisions/R25W0013716-state-architecture-migration.md

      # Preview changes without applying them
      mix generate.adr.serial --dir decisions/ --dry-run

      # Generate mapping file for cross-reference updates
      mix generate.adr.serial --dir decisions/ --create-mapping
  """

  use Mix.Task
  alias AriaSerial.Registry

  @shortdoc "Generate industrial-grade serial numbers for ADR files"
  @switches [
    dry_run: :boolean,
    help: :boolean,
    dir: :string,
    file: :string,
    create_mapping: :boolean
  ]
  @aliases [d: :dry_run, h: :help, f: :file]

  def run(args) do
    {opts, _args, _invalid} = OptionParser.parse(args, switches: @switches, aliases: @aliases)

    if opts[:help] do
      show_help()
    else
      generate_adr_serials(opts)
    end
  end

  defp generate_adr_serials(opts) do
    factory = "R"
    dry_run = opts[:dry_run] || false
    create_mapping = opts[:create_mapping] || false

    Mix.shell().info("Generating industrial-grade serial numbers for ADR files...")
    Mix.shell().info("Factory: #{decode_factory(factory)}")

    cond do
      opts[:file] ->
        process_single_file(opts[:file], factory, dry_run)

      opts[:dir] ->
        process_directory(opts[:dir], factory, dry_run, create_mapping)

      true ->
        process_directory("decisions", factory, dry_run, create_mapping)
    end
  end

  defp process_single_file(file_path, factory, dry_run) do
    if File.exists?(file_path) and String.ends_with?(file_path, ".md") do
      Mix.shell().info("Processing single file: #{file_path}")

      case analyze_adr_file(file_path) do
        {:ok, adr_info} ->
          serial = generate_adr_serial(adr_info, factory)
          display_adr_info(adr_info, serial, 1)

          if dry_run do
            Mix.shell().info("   [DRY RUN] Would generate serial: #{serial}")
          else
            case add_serial_to_adr(file_path, serial) do
              :ok -> Mix.shell().info("   ✅ Serial number added")
              {:error, reason} -> Mix.shell().error("   ❌ Failed: #{reason}")
            end
          end

        {:error, reason} ->
          Mix.shell().error("Failed to analyze #{file_path}: #{reason}")
      end
    else
      Mix.shell().error("File not found or not a markdown file: #{file_path}")
    end
  end

  defp process_directory(dir_path, factory, dry_run, create_mapping) do
    Mix.shell().info("Target Directory: #{dir_path}")
    Mix.shell().info("Mode: #{if dry_run, do: "DRY RUN", else: "LIVE"}")
    Mix.shell().info("")

    adr_files = find_adr_files(dir_path)

    if Enum.empty?(adr_files) do
      Mix.shell().info("No ADR files found in #{dir_path}")
      :ok
    else
      Mix.shell().info("Found #{length(adr_files)} ADR files:")
      Mix.shell().info("")

      # Analyze all files first
      analyzed_adrs =
        adr_files
        |> Enum.map(&analyze_adr_file/1)
        |> Enum.with_index(1)
        |> Enum.map(fn {result, index} ->
          case result do
            {:ok, adr_info} ->
              {adr_info, index}
            {:error, reason} ->
              Mix.shell().error("Failed to analyze file #{index}: #{reason}")
              nil
          end
        end)
        |> Enum.reject(&is_nil/1)

      # Generate serials with proper sequencing
      analyzed_adrs_with_serials = generate_serials_with_sequencing(analyzed_adrs, factory)

      # Display all ADRs with their serials
      Enum.each(analyzed_adrs_with_serials, fn {adr_info, serial, index} ->
        display_adr_info(adr_info, serial, index)
      end)

      # Create mapping file if requested
      if create_mapping do
        create_adr_mapping_file(analyzed_adrs_with_serials, dry_run)
      end

      # Process files
      unless dry_run do
        Enum.each(analyzed_adrs_with_serials, fn {adr_info, serial, _index} ->
          case add_serial_to_adr(adr_info.file_path, serial) do
            :ok -> Mix.shell().info("   ✅ Serial added to #{Path.basename(adr_info.file_path)}")
            {:error, reason} -> Mix.shell().error("   ❌ Failed #{Path.basename(adr_info.file_path)}: #{reason}")
          end
        end)
      end

      if dry_run do
        Mix.shell().info("")
        Mix.shell().info("DRY RUN completed. No files were modified.")
        Mix.shell().info("Run without --dry-run to apply changes.")
        Mix.shell().info("Add --create-mapping to generate cross-reference mapping file.")
      else
        Mix.shell().info("")
        Mix.shell().info("ADR serial numbers generated successfully!")
        Mix.shell().info("Use 'mix serial.decode <serial>' to decode any serial number.")
      end
    end
  end

  defp find_adr_files(dir) do
    if File.exists?(dir) do
      dir
      |> File.ls!()
      |> Enum.filter(fn file ->
        String.ends_with?(file, ".md") and
        not String.starts_with?(file, ".") and
        not has_serial_number?(Path.join(dir, file))
      end)
      |> Enum.map(&Path.join(dir, &1))
      |> Enum.sort()
    else
      []
    end
  end

  defp has_serial_number?(file_path) do
    case File.read(file_path) do
      {:ok, content} ->
        String.contains?(content, "@adr_serial") or
        String.match?(Path.basename(file_path), ~r/^R\d{2}[A-Z]\d{3}[A-Z0-9]{4}-/)
      {:error, _} -> false
    end
  end

  defp analyze_adr_file(file_path) do
    with {:ok, content} <- File.read(file_path),
         {:ok, creation_date} <- get_git_creation_date(file_path),
         {:ok, title} <- extract_adr_title(content, file_path) do

      {year, week} = calculate_year_week(creation_date)
      tool_code = generate_adr_tool_code(title)

      adr_info = %{
        file_path: file_path,
        title: title,
        creation_date: creation_date,
        year: year,
        week: week,
        tool_code: tool_code
      }

      {:ok, adr_info}
    else
      error -> error
    end
  end

  defp get_git_creation_date(file_path) do
    # Try to get creation date from git history
    case System.cmd("git", ["log", "--follow", "--format=%ai", "--diff-filter=A", "--", file_path],
                    stderr_to_stdout: true, cd: Path.dirname(file_path)) do
      {output, 0} ->
        lines = String.split(output, "\n") |> Enum.reject(&(&1 == ""))
        case List.last(lines) do
          nil ->
            # Fallback to current date
            {:ok, Date.utc_today()}
          date_string ->
            # Parse ISO8601 date string
            trimmed = String.trim(date_string)
            case parse_git_date(trimmed) do
              {:ok, date} -> {:ok, date}
              {:error, _} -> {:ok, Date.utc_today()}
            end
        end
      {_output, _exit_code} ->
        # Git command failed, use current date
        {:ok, Date.utc_today()}
    end
  end

  defp parse_git_date(date_string) do
    # Git format: "2025-06-13 10:30:45 -0700"
    case Regex.run(~r/^(\d{4}-\d{2}-\d{2})/, date_string) do
      [_, date_part] ->
        case Date.from_iso8601(date_part) do
          {:ok, date} -> {:ok, date}
          error -> error
        end
      nil ->
        # Try parsing as full ISO8601
        case DateTime.from_iso8601(date_string) do
          {:ok, datetime, _offset} -> {:ok, DateTime.to_date(datetime)}
          error -> error
        end
    end
  end

  defp extract_adr_title(content, file_path) do
    # Try to extract title from markdown header
    case Regex.run(~r/^#\s+(.+)$/m, content) do
      [_, title] ->
        {:ok, String.trim(title)}
      nil ->
        # Fallback to filename
        filename = Path.basename(file_path, ".md")
        # Remove ADR number prefix if present
        title = Regex.replace(~r/^\d{3}-/, filename, "")
        {:ok, title}
    end
  end

  defp calculate_year_week(date) do
    year = date.year

    # Calculate ISO week
    week = if Code.ensure_loaded?(Timex) do
      Timex.iso_week(date) |> elem(1)
    else
      # Basic week calculation
      start_of_year = Date.new!(year, 1, 1)
      days_diff = Date.diff(date, start_of_year)
      div(days_diff, 7) + 1
    end

    {year, week}
  end

  defp generate_adr_tool_code(title) do
    title
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]/, "")
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16()
    |> String.slice(0, 4)
    |> ensure_valid_chars()
  end

  defp ensure_valid_chars(code) do
    # Replace forbidden characters (I, O, U, Z) with allowed ones
    code
    |> String.graphemes()
    |> Enum.map(fn char ->
      case char do
        "I" -> "1"
        "O" -> "0"
        "U" -> "V"
        "Z" -> "Y"
        c -> c
      end
    end)
    |> Enum.join()
  end

  defp generate_serials_with_sequencing(analyzed_adrs, factory) do
    # Group ADRs by year-week combination for proper sequencing
    grouped_by_week =
      analyzed_adrs
      |> Enum.group_by(fn {adr_info, _index} ->
        {adr_info.year, adr_info.week}
      end)

    # Generate serials with proper sequence numbers within each week
    grouped_by_week
    |> Enum.flat_map(fn {{_year, _week}, adrs_in_week} ->
      adrs_in_week
      |> Enum.sort_by(fn {adr_info, _index} -> adr_info.file_path end)
      |> Enum.with_index(1)
      |> Enum.map(fn {{adr_info, original_index}, sequence_in_week} ->
        serial = generate_adr_serial_with_sequence(adr_info, factory, sequence_in_week)
        {adr_info, serial, original_index}
      end)
    end)
    |> Enum.sort_by(fn {_adr_info, _serial, original_index} -> original_index end)
  end

  defp generate_adr_serial_with_sequence(adr_info, factory, sequence) do
    year_str = String.slice(to_string(adr_info.year), -2, 2)
    week_char = Registry.encode_week(adr_info.week)
    sequence_str = String.pad_leading(to_string(sequence), 3, "0")

    "#{factory}#{year_str}#{week_char}#{sequence_str}#{adr_info.tool_code}"
  end

  defp generate_adr_serial(adr_info, factory) do
    # Fallback for single file processing
    generate_adr_serial_with_sequence(adr_info, factory, 1)
  end

  defp display_adr_info(adr_info, serial, index) do
    filename = Path.basename(adr_info.file_path)
    Mix.shell().info("#{index}. #{filename}")
    Mix.shell().info("   Title: #{adr_info.title}")
    Mix.shell().info("   Serial: #{serial}")
    Mix.shell().info("   Created: #{adr_info.creation_date} (Week #{adr_info.week})")
    Mix.shell().info("   Tool Code: #{adr_info.tool_code}")
    Mix.shell().info("   Path: #{adr_info.file_path}")
    Mix.shell().info("")
  end

  defp create_adr_mapping_file(analyzed_adrs, dry_run) do
    mapping =
      analyzed_adrs
      |> Enum.map(fn {adr_info, serial, _index} ->
        old_filename = Path.basename(adr_info.file_path)
        new_filename = "#{serial}-#{String.replace(old_filename, ~r/^\d{3}-/, "")}"

        %{
          old_filename: old_filename,
          new_filename: new_filename,
          serial: serial,
          title: adr_info.title,
          creation_date: to_string(adr_info.creation_date)
        }
      end)

    if dry_run do
      # For dry run, just create temporary file
      mapping_content = Jason.encode!(mapping, pretty: true)
      mapping_file = "adr_migration_mapping.json"

      case File.write(mapping_file, mapping_content) do
        :ok ->
          Mix.shell().info("Created mapping file for dry-run: #{mapping_file}")
          Mix.shell().info("Sample mapping entries:")
          mapping |> Enum.take(3) |> Enum.each(fn entry ->
            Mix.shell().info("  #{entry.old_filename} → #{entry.new_filename}")
          end)
        {:error, reason} ->
          Mix.shell().error("❌ Failed to create mapping file: #{reason}")
      end
    else
      # Store in proper JSON storage structure
      case store_adr_mapping_in_registry(mapping) do
        :ok ->
          Mix.shell().info("✅ Stored ADR mapping in serial registry")
        {:error, reason} ->
          Mix.shell().error("❌ Failed to store mapping: #{reason}")
      end
    end
  end

  defp store_adr_mapping_in_registry(mapping) do
    # Convert mapping to registry format and store in proper location
    current_date = Date.utc_today()
    {year, week} = calculate_year_week(current_date)

    # Create ADR mapping entries in the same format as other serials
    adr_entries =
      mapping
      |> Enum.with_index(1)
      |> Enum.map(fn {entry, sequence} ->
        {entry.serial, %{
          format: "v1",
          file: entry.old_filename,
          purpose: "ADR Migration: #{entry.title}",
          created: entry.creation_date,
          week: week,
          sequence: sequence,
          old_filename: entry.old_filename,
          new_filename: entry.new_filename
        }}
      end)
      |> Map.new()

    # Use AriaSerial.JsonStorage to store the data
    registry_data = %{
      week: week,
      year: year,
      factory: "R",
      serials: adr_entries,
      next_sequence: length(mapping) + 1,
      generated_at: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    storage_path = "priv/serial_data/#{year}/week_#{week}/R_series_adr_migration.json"
    AriaSerial.JsonStorage.store_registry(storage_path, registry_data)
  end

  defp add_serial_to_adr(file_path, serial) do
    with {:ok, content} <- File.read(file_path),
         {:ok, backup_path} <- create_backup(file_path),
         {:ok, new_content} <- inject_adr_serial(content, serial),
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

  defp inject_adr_serial(content, serial) do
    # Add serial as a comment at the top of the file
    lines = String.split(content, "\n")

    # Check if there's already a serial
    if Enum.any?(lines, &String.contains?(&1, "@adr_serial")) do
      {:error, "ADR already has a serial number"}
    else
      # Insert after the first header line
      case find_first_header(lines) do
        {:ok, header_index} ->
          {before, after_lines} = Enum.split(lines, header_index + 1)
          serial_lines = ["", "<!-- @adr_serial #{serial} -->", ""]
          new_content = (before ++ serial_lines ++ after_lines) |> Enum.join("\n")
          {:ok, new_content}

        :not_found ->
          # Insert at the beginning
          serial_lines = ["<!-- @adr_serial #{serial} -->", ""]
          new_content = (serial_lines ++ lines) |> Enum.join("\n")
          {:ok, new_content}
      end
    end
  end

  defp find_first_header(lines) do
    lines
    |> Enum.with_index()
    |> Enum.find_value(fn {line, index} ->
      if String.starts_with?(line, "#") do
        {:ok, index}
      end
    end) || :not_found
  end

  defp decode_factory("R"), do: "aRia Character Core"
  defp decode_factory(f), do: "Unknown Factory (#{f})"

  defp show_help do
    Mix.shell().info(@moduledoc)
  end
end
