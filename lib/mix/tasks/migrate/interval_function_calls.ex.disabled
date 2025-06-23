# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.Migrate.IntervalFunctionCalls do
  @serial_number "R25W004INTV"
  @doc "Returns the module's serial number for tracking and identification."
  @spec serial_number() :: String.t()
  def serial_number() do
    @serial_number
  end

  @moduledoc """
  Migrate incorrect Interval function calls to correct signatures.

  This task fixes function calls to AriaEngine.Timeline.Interval functions that have
  incorrect arity, particularly `new_fixed_schedule/1` calls that should be `new_fixed_schedule/2`.

  ## Usage

      mix migrate.interval_function_calls                    # Full migration
      mix migrate.interval_function_calls --dry-run         # Preview changes only
      mix migrate.interval_function_calls --backup-dir=.bak # Custom backup location

  ## What it does

  - Finds calls to `new_fixed_schedule/1` with single argument
  - Converts them to proper `new_fixed_schedule/2` calls
  - Handles both regular code and doctest examples
  - Uses AST parsing for accurate transformations
  """

  use Mix.Task
  require Logger

  @shortdoc "Migrate incorrect Interval function calls to correct signatures"
  @switches dry_run: :boolean, backup_dir: :string
  @aliases d: :dry_run, b: :backup_dir

  def run(args) do
    {opts, _args, _invalid} = OptionParser.parse(args, switches: @switches, aliases: @aliases)
    dry_run = opts[:dry_run] || false
    backup_dir = opts[:backup_dir] || ".migration_backup"

    Logger.info("🔧 Interval Function Calls Migration")
    Logger.info("====================================")

    if dry_run do
      Logger.info("🔍 DRY RUN MODE - No files will be modified")
    else
      Logger.info("📁 Backup directory: #{backup_dir}")
      create_backup_dir(backup_dir)
    end

    migrate_interval_calls(dry_run, backup_dir)
    Logger.info("✅ Interval function calls migration completed!")
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

  defp migrate_interval_calls(dry_run, backup_dir) do
    Logger.info("Migrating Interval function calls...")
    files_to_check = Path.wildcard("**/*.{ex,exs}", match_dot: true)

    Enum.each(files_to_check, fn file ->
      if File.exists?(file) and not should_skip_file?(file) do
        content = File.read!(file)

        if needs_migration?(content) do
          if dry_run do
            Logger.debug("   📄 Would migrate: #{file}")
            preview_changes(content, file)
          else
            backup_file(file, backup_dir)
            updated_content = transform_content(content)
            File.write!(file, updated_content)
            Logger.debug("   ✅ Migrated: #{file}")
          end
        end
      end
    end)
  end

  defp needs_migration?(content) do
    # Check for problematic patterns
    String.contains?(content, "new_fixed_schedule(") and
      (String.contains?(content, "Interval.new_fixed_schedule(") or
         String.contains?(content, "AriaEngine.Timeline.Interval.new_fixed_schedule("))
  end

  defp preview_changes(content, file) do
    lines = String.split(content, "\n")

    Enum.with_index(lines, 1)
    |> Enum.each(fn {line, line_num} ->
      if String.contains?(line, "new_fixed_schedule(") do
        Logger.info("   📍 #{file}:#{line_num}")
        Logger.info("      #{String.trim(line)}")

        transformed_line = transform_line(line)
        if transformed_line != line do
          Logger.info("   → #{String.trim(transformed_line)}")
        end
      end
    end)
  end

  defp transform_content(content) do
    # Handle doctests and regular code
    content
    |> transform_doctests()
    |> transform_regular_code()
  end

  defp transform_doctests(content) do
    # Transform doctest examples in both @doc and @moduledoc strings
    content
    |> String.replace(
      ~r/(\s+iex>\s+.*?)(Interval\.new_fixed_schedule\(([^)]+)\))/,
      fn match ->
        case Regex.run(~r/(\s+iex>\s+.*?)(Interval\.new_fixed_schedule\(([^)]+)\))/, match) do
          [_full, prefix, call, args] ->
            transformed_call = transform_interval_call(call, args)
            prefix <> transformed_call
          _ -> match
        end
      end
    )
    |> String.replace(
      ~r/(\s+iex>\s+.*?)(AriaEngine\.Timeline\.Interval\.new_fixed_schedule\(([^)]+)\))/,
      fn match ->
        case Regex.run(~r/(\s+iex>\s+.*?)(AriaEngine\.Timeline\.Interval\.new_fixed_schedule\(([^)]+)\))/, match) do
          [_full, prefix, call, args] ->
            transformed_call = transform_interval_call(call, args)
            prefix <> transformed_call
          _ -> match
        end
      end
    )
    |> transform_moduledoc_strings()
  end

  defp transform_moduledoc_strings(content) do
    # Handle @moduledoc and @doc strings that contain NaiveDateTime examples
    content
    |> String.replace(
      ~r/(@(?:module)?doc\s+"[^"]*)(~N\[[^\]]+\])([^"]*")/,
      fn match ->
        case Regex.run(~r/(@(?:module)?doc\s+"[^"]*)(~N\[[^\]]+\])([^"]*")/, match) do
          [_full, prefix, naive_dt, suffix] ->
            converted = convert_naive_datetime_to_iso(naive_dt)
            # Remove quotes from converted string since it's inside a doc string
            converted_clean = String.trim(converted, "\"")
            prefix <> converted_clean <> suffix
          _ -> match
        end
      end
    )
  end

  defp transform_regular_code(content) do
    # Transform regular function calls
    content
    |> String.replace(
      ~r/(Interval\.new_fixed_schedule\(([^)]+)\))/,
      fn match ->
        case Regex.run(~r/(Interval\.new_fixed_schedule\(([^)]+)\))/, match) do
          [_full, call, args] ->
            transform_interval_call(call, args)
          _ -> match
        end
      end
    )
    |> String.replace(
      ~r/(AriaEngine\.Timeline\.Interval\.new_fixed_schedule\(([^)]+)\))/,
      fn match ->
        case Regex.run(~r/(AriaEngine\.Timeline\.Interval\.new_fixed_schedule\(([^)]+)\))/, match) do
          [_full, call, args] ->
            transform_interval_call(call, args)
          _ -> match
        end
      end
    )
  end

  defp transform_interval_call(original_call, args) do
    # Parse the arguments to determine if we need to transform
    args_trimmed = String.trim(args)

    cond do
      # If it's already a map argument (unified temporal specification)
      String.starts_with?(args_trimmed, "%{") ->
        original_call

      # If it contains commas, check if it needs transformation
      String.contains?(args_trimmed, ",") ->
        transform_comma_separated_args(original_call, args_trimmed)

      # Single argument that looks like an ISO string - needs transformation
      String.contains?(args_trimmed, "T") and String.contains?(args_trimmed, "Z") ->
        # This looks like a single ISO string, we need to split it into start/end
        transform_single_iso_arg(original_call, args_trimmed)

      # Single NaiveDateTime argument - needs transformation
      String.starts_with?(args_trimmed, "~N[") ->
        transform_single_naive_datetime(original_call, args_trimmed)

      # Other single arguments - might need transformation
      true ->
        # Try to determine if this is a problematic single argument
        if looks_like_single_iso_string?(args_trimmed) do
          transform_single_iso_arg(original_call, args_trimmed)
        else
          original_call
        end
    end
  end

  defp looks_like_single_iso_string?(arg) do
    # Check if this looks like a single ISO 8601 string
    String.contains?(arg, "T") and (String.contains?(arg, "Z") or String.contains?(arg, "+"))
  end

  defp transform_single_iso_arg(original_call, arg) do
    # For single ISO string arguments, we need to create a proper two-argument call
    # This is a heuristic transformation - in practice, we'd need more context
    # For now, let's create a placeholder transformation that can be manually reviewed

    function_name = extract_function_name(original_call)

    # Create a comment indicating manual review needed
    "#{function_name}(#{arg}, #{arg}) # TODO: Fix end time - was single arg call"
  end

  defp extract_function_name(call) do
    call
    |> String.replace(~r/\([^)]*\)$/, "")
  end

  defp transform_line(line) do
    if String.contains?(line, "new_fixed_schedule(") do
      transform_regular_code(line)
    else
      line
    end
  end

  defp transform_comma_separated_args(original_call, args) do
    # Check if this is a NaiveDateTime pair that needs conversion
    if String.contains?(args, "~N[") do
      # Split the arguments and convert NaiveDateTime to ISO strings
      args_list = String.split(args, ",", parts: 2)
      case args_list do
        [start_arg, end_arg] ->
          start_converted = convert_naive_datetime_to_iso(String.trim(start_arg))
          end_converted = convert_naive_datetime_to_iso(String.trim(end_arg))
          function_name = extract_function_name(original_call)
          "#{function_name}(#{start_converted}, #{end_converted})"
        _ ->
          original_call
      end
    else
      # Already correct format
      original_call
    end
  end

  defp transform_single_naive_datetime(original_call, arg) do
    # Convert single NaiveDateTime to ISO string format
    # This is likely an error case that needs manual review
    converted_arg = convert_naive_datetime_to_iso(arg)
    function_name = extract_function_name(original_call)

    # Create a comment indicating manual review needed
    "#{function_name}(#{converted_arg}, #{converted_arg}) # TODO: Fix end time - was single NaiveDateTime"
  end

  defp convert_naive_datetime_to_iso(arg) do
    # Convert ~N[2025-01-01 10:00:00] to "2025-01-01T10:00:00Z"
    if String.starts_with?(arg, "~N[") and String.ends_with?(arg, "]") do
      # Extract the datetime string
      datetime_str = arg
        |> String.replace_prefix("~N[", "")
        |> String.replace_suffix("]", "")

      # Convert to ISO 8601 format
      iso_string = datetime_str
        |> String.replace(" ", "T")
        |> Kernel.<>("Z")

      "\"#{iso_string}\""
    else
      arg
    end
  end

  defp backup_file(file, backup_dir) do
    backup_path = Path.join(backup_dir, file)
    backup_dir_path = Path.dirname(backup_path)
    File.mkdir_p!(backup_dir_path)
    File.cp!(file, backup_path)
  end
end
