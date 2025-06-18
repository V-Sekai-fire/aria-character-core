#!/usr/bin/env elixir

# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AddRequireLogger do
  @moduledoc """
  Script to add 'require Logger' to files that use Logger but don't have the require statement.
  
  Usage: mix run scripts/add_require_logger.exs
  """

  def add_require_logger_to_all_files do
    IO.puts("🔄 Adding require Logger to files that need it...")
    
    files_to_fix = find_files_needing_require_logger()
    
    IO.puts("📁 Found #{length(files_to_fix)} files needing require Logger:")
    Enum.each(files_to_fix, fn file ->
      IO.puts("   - #{file}")
    end)
    
    results = Enum.map(files_to_fix, fn file ->
      add_require_logger_to_file(file)
    end)
    
    {successful, failed} = Enum.split_with(results, &match?({:ok, _}, &1))
    
    IO.puts("\n✅ Require Logger addition completed:")
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

  def find_files_needing_require_logger do
    Path.wildcard("lib/**/*.ex")
    |> Enum.filter(fn file ->
      case File.read(file) do
        {:ok, content} ->
          uses_logger = String.contains?(content, "Logger.")
          has_require = String.contains?(content, "require Logger")
          uses_logger and not has_require
        {:error, _} ->
          false
      end
    end)
  end

  def add_require_logger_to_file(file_path) do
    case File.read(file_path) do
      {:ok, content} ->
        IO.puts("🔧 Adding require Logger to #{file_path}...")
        
        new_content = add_require_logger_to_content(content)
        
        case File.write(file_path, new_content) do
          :ok ->
            IO.puts("   ✅ Successfully updated #{file_path}")
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

  def add_require_logger_to_content(content) do
    lines = String.split(content, "\n")
    
    # Find the defmodule line
    case Enum.find_index(lines, &String.contains?(&1, "defmodule")) do
      nil ->
        # No module found, add at the top after any comments
        add_require_logger_at_top(content)
      module_index ->
        add_require_logger_after_module(lines, module_index)
    end
  end

  defp add_require_logger_at_top(content) do
    lines = String.split(content, "\n")
    
    # Find first non-comment, non-blank line
    first_code_index = Enum.find_index(lines, fn line ->
      trimmed = String.trim(line)
      trimmed != "" and not String.starts_with?(trimmed, "#")
    end)
    
    case first_code_index do
      nil ->
        content <> "\nrequire Logger\n"
      index ->
        {before, after_lines} = Enum.split(lines, index)
        (before ++ ["require Logger", ""] ++ after_lines)
        |> Enum.join("\n")
    end
  end

  defp add_require_logger_after_module(lines, module_index) do
    # Look for @moduledoc or first non-comment line after defmodule
    insertion_index = find_insertion_point(lines, module_index)
    
    # Get the indentation of the module
    module_line = Enum.at(lines, module_index)
    base_indent = get_base_indentation(module_line)
    require_line = base_indent <> "require Logger"
    
    {before, after_lines} = Enum.split(lines, insertion_index)
    (before ++ [require_line] ++ after_lines)
    |> Enum.join("\n")
  end

  defp find_insertion_point(lines, module_index) do
    # Start searching after the defmodule line
    search_start = module_index + 1
    lines_after_module = Enum.drop(lines, search_start)
    
    # Look for @moduledoc end or first significant code line
    case Enum.find_index(lines_after_module, &is_insertion_point/1) do
      nil ->
        # Insert at the end if no good point found
        search_start + length(lines_after_module)
      relative_index ->
        search_start + relative_index
    end
  end

  defp is_insertion_point(line) do
    trimmed = String.trim(line)
    
    # Skip empty lines, comments, and @moduledoc
    cond do
      trimmed == "" -> false
      String.starts_with?(trimmed, "#") -> false
      String.starts_with?(trimmed, "@moduledoc") -> false
      String.contains?(trimmed, "\"\"\"") -> false
      String.starts_with?(trimmed, "alias") -> true
      String.starts_with?(trimmed, "import") -> true
      String.starts_with?(trimmed, "use") -> true
      String.starts_with?(trimmed, "def") -> true
      String.starts_with?(trimmed, "@") -> true
      true -> true
    end
  end

  defp get_base_indentation(line) do
    # Extract indentation from the module line
    case Regex.run(~r/^(\s*)/, line) do
      [_, indent] -> indent <> "  "  # Add extra indent for module content
      _ -> "  "  # Default to 2 spaces
    end
  end
end

# Run the script if executed directly
case System.argv() do
  ["--dry-run"] ->
    files = AddRequireLogger.find_files_needing_require_logger()
    IO.puts("🔍 Dry run - Files that would be updated:")
    Enum.each(files, fn file ->
      IO.puts("   - #{file}")
    end)
    IO.puts("Total files: #{length(files)}")
    
  [] ->
    AddRequireLogger.add_require_logger_to_all_files()
    
  ["--help"] ->
    IO.puts("""
    Add require Logger Script
    
    Usage:
      mix run scripts/add_require_logger.exs           # Add require Logger to files
      mix run scripts/add_require_logger.exs --dry-run # Preview changes
      mix run scripts/add_require_logger.exs --help    # Show this help
    """)
    
  _ ->
    IO.puts("Unknown arguments. Use --help for usage information.")
end
