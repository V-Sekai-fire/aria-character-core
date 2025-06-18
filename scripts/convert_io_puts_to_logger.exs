#!/usr/bin/env elixir

# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule IOPutsToLoggerConverter do
  @moduledoc """
  Automated conversion tool to convert IO.puts and TestOutput.trace_puts to Logger calls.
  
  Usage: mix run scripts/convert_io_puts_to_logger.exs
  """

  @doc """
  Main conversion function that processes all .ex files in the project.
  """
  def convert_all_files do
    IO.puts("🔄 Starting IO.puts and TestOutput.trace_puts to Logger conversion...")
    
    files_to_convert = find_files_with_io_puts()
    
    IO.puts("📁 Found #{length(files_to_convert)} files to convert:")
    Enum.each(files_to_convert, fn {file, count} ->
      IO.puts("   - #{file} (#{count} instances)")
    end)
    
    results = Enum.map(files_to_convert, fn {file, _count} ->
      convert_file(file)
    end)
    
    {successful, failed} = Enum.split_with(results, &match?({:ok, _}, &1))
    
    IO.puts("\n✅ Conversion completed:")
    IO.puts("   Successful: #{length(successful)}")
    IO.puts("   Failed: #{length(failed)}")
    
    if length(failed) > 0 do
      IO.puts("\n❌ Failed files:")
      Enum.each(failed, fn {:error, {file, reason}} ->
        IO.puts("   - #{file}: #{reason}")
      end)
    end
    
    {:ok, %{successful: length(successful), failed: length(failed)}}
  end

  @doc """
  Finds all .ex files that contain IO.puts or TestOutput.trace_puts.
  """
  def find_files_with_io_puts do
    Path.wildcard("lib/**/*.ex")
    |> Enum.map(fn file ->
      case File.read(file) do
        {:ok, content} ->
          io_puts_count = count_matches(content, ~r/IO\.puts/)
          trace_puts_count = count_matches(content, ~r/TestOutput\.trace_puts/)
          total_count = io_puts_count + trace_puts_count
          
          if total_count > 0 do
            {file, total_count}
          else
            nil
          end
        {:error, _} ->
          nil
      end
    end)
    |> Enum.filter(&(&1 != nil))
  end

  @doc """
  Converts a single file by replacing IO.puts and TestOutput.trace_puts with Logger calls.
  """
  def convert_file(file_path) do
    case File.read(file_path) do
      {:ok, content} ->
        IO.puts("🔧 Converting #{file_path}...")
        
        # Check if file already has require Logger
        has_require_logger = String.contains?(content, "require Logger")
        
        # Apply conversions
        new_content = 
          content
          |> convert_test_output_trace_puts_to_logger()
          |> convert_io_puts_to_logger()
          |> add_require_logger_if_needed(has_require_logger)
        
        # Write back the file
        case File.write(file_path, new_content) do
          :ok ->
            IO.puts("   ✅ Successfully converted #{file_path}")
            {:ok, file_path}
          {:error, reason} ->
            IO.puts("   ❌ Failed to write #{file_path}: #{reason}")
            {:error, {file_path, reason}}
        end
        
      {:error, reason} ->
        IO.puts("   ❌ Failed to read #{file_path}: #{reason}")
        {:error, {file_path, reason}}
    end
  end

  @doc """
  Converts IO.puts statements to appropriate Logger calls based on content.
  """
  def convert_io_puts_to_logger(content) do
    content
    |> convert_debug_io_puts()
    |> convert_error_io_puts()
    |> convert_info_io_puts()
    |> convert_remaining_io_puts()
  end

  @doc """
  Converts TestOutput.trace_puts to Logger.debug calls.
  """
  def convert_test_output_trace_puts_to_logger(content) do
    # Convert TestOutput.trace_puts to Logger.debug
    Regex.replace(
      ~r/TestOutput\.trace_puts\(/,
      content,
      "Logger.debug("
    )
  end

  @doc """
  Adds require Logger to the module if needed and not already present.
  """
  def add_require_logger_if_needed(content, has_require_logger) do
    if has_require_logger or not needs_logger_require(content) do
      content
    else
      # Find the module definition and add require Logger after it
      case Regex.run(~r/(defmodule\s+\w+(?:\.\w+)*\s+do\s*\n(?:\s*@moduledoc.*?\n)?)/s, content) do
        [match, module_def] ->
          replacement = module_def <> "  require Logger\n"
          String.replace(content, match, replacement, global: false)
        nil ->
          # If no module found, add at the top after any copyright header
          case Regex.run(~r/((?:#.*\n)*)/s, content) do
            [_, header] ->
              String.replace(content, header, header <> "require Logger\n\n", global: false)
            nil ->
              "require Logger\n\n" <> content
          end
      end
    end
  end

  # Private helper functions

  defp count_matches(content, regex) do
    Regex.scan(regex, content) |> length()
  end

  defp needs_logger_require(content) do
    String.contains?(content, "Logger.") and not String.contains?(content, "require Logger")
  end

  # Convert debug-related IO.puts
  defp convert_debug_io_puts(content) do
    content = Regex.replace(~r/IO\.puts\("DEBUG: ([^"]+)"\)/, content, "Logger.debug(\"\\1\")")
    content = Regex.replace(~r/IO\.puts\("❌ DEBUG: ([^"]+)"\)/, content, "Logger.debug(\"\\1\")")
    # Verbose mode conditional patterns  
    content = Regex.replace(~r/if verbose > \d+ do\s*\n\s*IO\.puts\(([^)]+)\)/, content, "if verbose > 2 do\n        Logger.debug(\\1)")
    content = Regex.replace(~r/if Application\.get_env\([^)]+\) do\s*\n\s*IO\.puts\(([^)]+)\)/, content, "Logger.debug(\\1)")
    content
  end

  # Convert error-related IO.puts  
  defp convert_error_io_puts(content) do
    # Error emoji and patterns
    content = Regex.replace(~r/IO\.puts\("❌([^"]+)"\)/, content, "Logger.error(\"\\1\")")
    content = Regex.replace(~r/IO\.puts\("✗([^"]+)"\)/, content, "Logger.error(\"\\1\")")
    # Failure patterns
    content = Regex.replace(~r/IO\.puts\("([^"]*[Ff]ailed[^"]*)"\)/, content, "Logger.error(\"\\1\")")
    content = Regex.replace(~r/IO\.puts\("([^"]*[Ee]rror[^"]*)"\)/, content, "Logger.error(\"\\1\")")
    content
  end

  # Convert info-related IO.puts
  defp convert_info_io_puts(content) do
    # Success emoji and patterns
    content = Regex.replace(~r/IO\.puts\("✅([^"]+)"\)/, content, "Logger.info(\"\\1\")")
    content = Regex.replace(~r/IO\.puts\("✓([^"]+)"\)/, content, "Logger.info(\"\\1\")")
    # Progress and status patterns
    content = Regex.replace(~r/IO\.puts\("🔄([^"]+)"\)/, content, "Logger.info(\"\\1\")")
    content = Regex.replace(~r/IO\.puts\("📋([^"]+)"\)/, content, "Logger.info(\"\\1\")")
    content = Regex.replace(~r/IO\.puts\("📁([^"]+)"\)/, content, "Logger.info(\"\\1\")")
    content = Regex.replace(~r/IO\.puts\("📊([^"]+)"\)/, content, "Logger.info(\"\\1\")")
    content = Regex.replace(~r/IO\.puts\("🏥([^"]+)"\)/, content, "Logger.info(\"\\1\")")
    content = Regex.replace(~r/IO\.puts\("🗑️([^"]+)"\)/, content, "Logger.info(\"\\1\")")
    # Warning patterns
    content = Regex.replace(~r/IO\.puts\("⚠️([^"]+)"\)/, content, "Logger.warning(\"\\1\")")
    content
  end

  # Convert remaining IO.puts to Logger.debug (conservative approach)
  defp convert_remaining_io_puts(content) do
    # Simple string patterns
    content = Regex.replace(~r/IO\.puts\("([^"]+)"\)/, content, "Logger.debug(\"\\1\")")
    # Complex interpolation patterns - be more careful
    content = Regex.replace(~r/IO\.puts\(([^)]+)\)/, content, "Logger.debug(\\1)")
    content
  end
end

# Run the conversion if this script is executed directly
case System.argv() do
  ["--dry-run"] ->
    files = IOPutsToLoggerConverter.find_files_with_io_puts()
    IO.puts("🔍 Dry run - Files that would be converted:")
    Enum.each(files, fn {file, count} ->
      IO.puts("   - #{file} (#{count} instances)")
    end)
    IO.puts("Total files: #{length(files)}")
    
  [] ->
    IOPutsToLoggerConverter.convert_all_files()
    
  ["--help"] ->
    IO.puts("""
    IO.puts to Logger Converter
    
    Usage:
      mix run scripts/convert_io_puts_to_logger.exs           # Run conversion
      mix run scripts/convert_io_puts_to_logger.exs --dry-run # Preview changes
      mix run scripts/convert_io_puts_to_logger.exs --help    # Show this help
    """)
    
  _ ->
    IO.puts("Unknown arguments. Use --help for usage information.")
end
