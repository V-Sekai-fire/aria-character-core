#!/usr/bin/env elixir

# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule IOPutsToLoggerConverterAST do
  @moduledoc """
  AST-based conversion tool to convert IO.puts and TestOutput.trace_puts to Logger calls.
  
  This version uses Elixir's Abstract Syntax Tree for precise, context-aware transformations
  instead of error-prone regex patterns.
  
  Usage: mix run scripts/convert_io_puts_to_logger_ast.exs
  """

  @doc """
  Main conversion function that processes all .ex files in the project.
  """
  def convert_all_files do
    IO.puts("🔄 Starting AST-based IO.puts and TestOutput.trace_puts to Logger conversion...")
    
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
          case Code.string_to_quoted(content) do
            {:ok, ast} ->
              count = count_io_puts_in_ast(ast)
              if count > 0 do
                {file, count}
              else
                nil
              end
            {:error, _} ->
              # Fall back to regex for files that don't parse
              io_puts_count = count_matches_regex(content, ~r/IO\.puts/)
              trace_puts_count = count_matches_regex(content, ~r/TestOutput\.trace_puts/)
              total_count = io_puts_count + trace_puts_count
              if total_count > 0 do
                {file, total_count}
              else
                nil
              end
          end
        {:error, _} ->
          nil
      end
    end)
    |> Enum.filter(&(&1 != nil))
  end

  @doc """
  Converts a single file using AST transformation.
  """
  def convert_file(file_path) do
    case File.read(file_path) do
      {:ok, content} ->
        IO.puts("🔧 Converting #{file_path}...")
        
        case Code.string_to_quoted(content) do
          {:ok, ast} ->
            # Transform the AST
            {new_ast, needs_logger} = transform_ast(ast)
            
            # Convert back to string
            new_content = Macro.to_string(new_ast)
            
            # Add require Logger if needed and not present
            final_content = if needs_logger and not has_require_logger(content) do
              add_require_logger(new_content)
            else
              new_content
            end
            
            # Write back the file
            case File.write(file_path, final_content) do
              :ok ->
                IO.puts("   ✅ Successfully converted #{file_path}")
                {:ok, file_path}
              {:error, reason} ->
                IO.puts("   ❌ Failed to write #{file_path}: #{reason}")
                {:error, {file_path, reason}}
            end
            
          {:error, reason} ->
            IO.puts("   ⚠️ Failed to parse #{file_path} as AST: #{inspect(reason)}, falling back to regex")
            convert_file_with_regex_fallback(file_path, content)
        end
        
      {:error, reason} ->
        IO.puts("   ❌ Failed to read #{file_path}: #{reason}")
        {:error, {file_path, reason}}
    end
  end

  @doc """
  Transforms an AST by converting IO.puts and TestOutput.trace_puts to Logger calls.
  Returns {transformed_ast, needs_logger_require}.
  """
  def transform_ast(ast) do
    {new_ast, needs_logger} = Macro.prewalk(ast, false, fn node, acc ->
      case transform_node(node) do
        {:transformed, new_node} -> {new_node, true}
        {:unchanged, node} -> {node, acc}
      end
    end)
    
    {new_ast, needs_logger}
  end

  # Pattern match and transform specific AST nodes
  defp transform_node(node) do
    case node do
      # IO.puts("string")
      {{:., _, [{:__aliases__, _, [:IO]}, :puts]}, _, [string]} ->
        logger_call = determine_logger_level_from_string(string)
        {:transformed, logger_call}
      
      # TestOutput.trace_puts("string")  
      {{:., _, [{:__aliases__, _, [:TestOutput]}, :trace_puts]}, _, [string]} ->
        logger_call = {{:., [], [{:__aliases__, [], [:Logger]}, :debug]}, [], [string]}
        {:transformed, logger_call}
      
      # IO.puts(interpolated_string)
      {{:., _, [{:__aliases__, _, [:IO]}, :puts]}, _, [interpolated]} ->
        logger_call = determine_logger_level_from_content(interpolated)
        {:transformed, logger_call}
      
      # TestOutput.trace_puts(interpolated_string)
      {{:., _, [{:__aliases__, _, [:TestOutput]}, :trace_puts]}, _, [interpolated]} ->
        logger_call = {{:., [], [{:__aliases__, [], [:Logger]}, :debug]}, [], [interpolated]}
        {:transformed, logger_call}
      
      _ ->
        {:unchanged, node}
    end
  end

  defp determine_logger_level_from_string(string_node) do
    # Extract string content for analysis
    content = case string_node do
      {:<<>>, _, parts} when is_list(parts) ->
        # String interpolation - get first string part
        first_string = Enum.find(parts, &is_binary/1)
        first_string || ""
      binary when is_binary(binary) ->
        binary
      _ ->
        ""
    end
    
    logger_level = cond do
      String.contains?(content, "DEBUG:") -> :debug
      String.contains?(content, "❌") -> :error
      String.contains?(content, "✗") -> :error
      String.contains?(content, "failed") or String.contains?(content, "Failed") -> :error
      String.contains?(content, "error") or String.contains?(content, "Error") -> :error
      String.contains?(content, "✅") -> :info
      String.contains?(content, "✓") -> :info
      String.contains?(content, "🔄") -> :info
      String.contains?(content, "📋") -> :info
      String.contains?(content, "📁") -> :info
      String.contains?(content, "⚠️") -> :warning
      true -> :debug  # Default to debug for unknown patterns
    end
    
    {{:., [], [{:__aliases__, [], [:Logger]}, logger_level]}, [], [string_node]}
  end

  defp determine_logger_level_from_content(_interpolated) do
    # For complex interpolated strings, default to debug level
    # Could be enhanced to analyze interpolated content
    {{:., [], [{:__aliases__, [], [:Logger]}, :debug]}, [], [_interpolated]}
  end

  defp count_io_puts_in_ast(ast) do
    {_, count} = Macro.prewalk(ast, 0, fn node, acc ->
      case node do
        {{:., _, [{:__aliases__, _, [:IO]}, :puts]}, _, _} -> {node, acc + 1}
        {{:., _, [{:__aliases__, _, [:TestOutput]}, :trace_puts]}, _, _} -> {node, acc + 1}
        _ -> {node, acc}
      end
    end)
    count
  end

  defp has_require_logger(content) do
    String.contains?(content, "require Logger")
  end

  defp add_require_logger(content) do
    # Find the module definition and add require Logger after it
    case String.split(content, "\n") do
      lines ->
        case Enum.find_index(lines, &String.contains?(&1, "defmodule")) do
          nil ->
            # No module found, add at the top
            "require Logger\n\n" <> content
          index ->
            {before, [module_line | after_lines]} = Enum.split(lines, index + 1)
            
            # Insert require Logger after module line
            new_lines = before ++ [module_line, "  require Logger"] ++ after_lines
            Enum.join(new_lines, "\n")
        end
    end
  end

  # Fallback regex conversion for files that don't parse as AST
  defp convert_file_with_regex_fallback(file_path, content) do
    # Use simplified regex for unparseable files
    new_content = content
    |> String.replace(~r/TestOutput\.trace_puts\(/, "Logger.debug(")
    |> String.replace(~r/IO\.puts\(/, "Logger.debug(")
    
    final_content = if not has_require_logger(content) do
      add_require_logger(new_content)
    else
      new_content
    end
    
    case File.write(file_path, final_content) do
      :ok ->
        IO.puts("   ✅ Successfully converted #{file_path} (regex fallback)")
        {:ok, file_path}
      {:error, reason} ->
        IO.puts("   ❌ Failed to write #{file_path}: #{reason}")
        {:error, {file_path, reason}}
    end
  end

  defp count_matches_regex(content, regex) do
    Regex.scan(regex, content) |> length()
  end
end


# Run the conversion if this script is executed directly
case System.argv() do
  ["--dry-run"] ->
    files = IOPutsToLoggerConverterAST.find_files_with_io_puts()
    IO.puts("🔍 Dry run - Files that would be converted:")
    Enum.each(files, fn {file, count} ->
      IO.puts("   - #{file} (#{count} instances)")
    end)
    IO.puts("Total files: #{length(files)}")
    
  [] ->
    IOPutsToLoggerConverterAST.convert_all_files()
    
  ["--help"] ->
    IO.puts("""
    AST-based IO.puts to Logger Converter
    
    Usage:
      mix run scripts/convert_io_puts_to_logger_ast.exs           # Run conversion
      mix run scripts/convert_io_puts_to_logger_ast.exs --dry-run # Preview changes
      mix run scripts/convert_io_puts_to_logger_ast.exs --help    # Show this help
    """)
    
  _ ->
    IO.puts("Unknown arguments. Use --help for usage information.")
end
