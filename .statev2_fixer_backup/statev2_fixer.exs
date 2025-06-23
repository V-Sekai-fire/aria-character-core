#!/usr/bin/env elixir

# StateV2 to State Migration Fixer Tool
# Comprehensive tool for migrating StateV2 references to State throughout codebase
# Based on successful migration patterns from migrate_statev2.exs

defmodule StateV2Fixer do
  @moduledoc """
  Comprehensive StateV2 to State migration tool.

  Features:
  - Automatic detection of all StateV2 references
  - Smart transformations with parameter reordering
  - Dry-run mode for safe previewing
  - Automatic backups and rollback capability
  - Detailed transformation reports
  - Context-aware handling (code, comments, docs)
  """

  require Logger

  defp transformations do
    [
      # Function call transformations with parameter reordering
      {:function_call, ~r/StateV2\.update_fact\(([^,]+),\s*([^,]+),\s*([^,]+),\s*([^)]+)\)/,
       "State.set_fact(\\1, \\3, \\2, \\4)", "update_fact → set_fact with parameter reorder"},

      {:function_call, ~r/StateV2\.matches_exactly\?\(([^,]+),\s*([^,]+),\s*([^,]+),\s*([^)]+)\)/,
       "State.matches?(\\1, \\3, \\2, \\4)", "matches_exactly? → matches? with parameter reorder"},

      # Simple function name changes
      {:function_name, ~r/StateV2\.matches_exactly\?/, "State.matches?", "matches_exactly? → matches?"},
      {:function_name, ~r/StateV2\.get_fact/, "State.get_fact", "get_fact function"},
      {:function_name, ~r/StateV2\.set_fact/, "State.set_fact", "set_fact function"},
      {:function_name, ~r/StateV2\.new/, "State.new", "new function"},
      {:function_name, ~r/StateV2\.has_predicate\?/, "State.has_predicate?", "has_predicate? function"},

      # Struct patterns
      {:struct_pattern, ~r/%StateV2\{/, "%State{", "struct pattern"},

      # Module references in aliases and imports
      {:alias_import, ~r/alias\s+AriaEngine\.StateV2/, "alias State", "alias statement"},
      {:alias_import, ~r/alias\s+StateV2/, "alias State", "alias statement"},
      {:alias_import, ~r/import\s+AriaEngine\.StateV2/, "import State", "import statement"},
      {:alias_import, ~r/import\s+StateV2/, "import State", "import statement"},

      # Standalone module references (be careful not to match in comments/strings)
      {:module_ref, ~r/\bStateV2\b(?!\w)/, "State", "module reference"},

      # Type annotations
      {:type_annotation, ~r/StateV2\.t\(\)/, "State.t()", "type annotation"},
      {:type_annotation, ~r/@type.*StateV2/, "@type State", "type definition"},
    ]
  end

  @file_extensions [".ex", ".exs"]
  @backup_dir ".statev2_fixer_backup"

  def main(args \\ []) do
    case parse_args(args) do
      {:help} -> print_help()
      {:scan, directory} -> scan_codebase(directory)
      {:preview, file_path} -> preview_changes(file_path)
      {:fix, files, opts} -> apply_fixes(files, opts)
      {:rollback, backup_dir} -> rollback_changes(backup_dir)
      {:error, message} -> IO.puts("Error: #{message}")
    end
  end

  def scan_codebase(directory \\ ".") do
    IO.puts("🔍 Scanning codebase for StateV2 references...")

    files = find_elixir_files(directory)
    results = Enum.map(files, &scan_file/1)

    files_with_issues = Enum.filter(results, fn {_file, issues} -> length(issues) > 0 end)

    if length(files_with_issues) == 0 do
      IO.puts("✅ No StateV2 references found!")
    else
      IO.puts("\n📋 Found StateV2 references in #{length(files_with_issues)} files:")

      Enum.each(files_with_issues, fn {file, issues} ->
        IO.puts("\n📄 #{file} (#{length(issues)} issues)")
        Enum.each(issues, fn {line_num, line, type, description} ->
          IO.puts("  Line #{line_num}: #{type} - #{description}")
          IO.puts("    #{String.trim(line)}")
        end)
      end)

      total_issues = files_with_issues |> Enum.map(fn {_, issues} -> length(issues) end) |> Enum.sum()
      IO.puts("\n📊 Total: #{total_issues} StateV2 references across #{length(files_with_issues)} files")

      IO.puts("\n💡 To fix these issues:")
      IO.puts("  Preview changes: ./statev2_fixer.exs preview <file>")
      IO.puts("  Fix all files:   ./statev2_fixer.exs fix --all")
      IO.puts("  Fix specific:    ./statev2_fixer.exs fix file1.ex file2.ex")
    end

    files_with_issues
  end

  def preview_changes(file_path) do
    IO.puts("🔍 Previewing changes for: #{file_path}")

    case File.read(file_path) do
      {:ok, content} ->
        {_new_content, changes} = apply_transformations(content, file_path, dry_run: true)

        if length(changes) == 0 do
          IO.puts("✅ No StateV2 references found in this file.")
        else
          IO.puts("\n📝 Proposed changes (#{length(changes)} transformations):")

          Enum.each(changes, fn {line_num, old_line, new_line, type, description} ->
            IO.puts("\nLine #{line_num}: #{type} - #{description}")
            IO.puts("  - #{String.trim(old_line)}")
            IO.puts("  + #{String.trim(new_line)}")
          end)

          IO.puts("\n💾 To apply these changes:")
          IO.puts("  ./statev2_fixer.exs fix #{file_path}")
        end

      {:error, reason} ->
        IO.puts("❌ Error reading file: #{reason}")
    end
  end

  def apply_fixes(files, opts \\ []) do
    dry_run = Keyword.get(opts, :dry_run, false)
    backup = Keyword.get(opts, :backup, true)

    if dry_run do
      IO.puts("🔍 Dry run mode - no files will be modified")
    else
      IO.puts("🔧 Applying StateV2 to State fixes...")
    end

    # Create backup directory if needed
    if backup and not dry_run do
      create_backup_dir()
    end

    results = Enum.map(files, fn file ->
      fix_file(file, opts)
    end)

    generate_report(results, opts)

    if not dry_run do
      IO.puts("\n✅ Migration complete!")
      IO.puts("💡 Run tests to verify: mix test")
      if backup do
        IO.puts("🔄 To rollback: ./statev2_fixer.exs rollback #{@backup_dir}")
      end
    end

    results
  end

  def fix_file(file_path, opts \\ []) do
    dry_run = Keyword.get(opts, :dry_run, false)
    backup = Keyword.get(opts, :backup, true)

    case File.read(file_path) do
      {:ok, content} ->
        {new_content, changes} = apply_transformations(content, file_path, dry_run: dry_run)

        if length(changes) > 0 and not dry_run do
          # Create backup
          if backup do
            backup_file(file_path)
          end

          # Write new content
          case File.write(file_path, new_content) do
            :ok ->
              {:ok, file_path, length(changes), changes}
            {:error, reason} ->
              {:error, file_path, reason}
          end
        else
          {:ok, file_path, length(changes), changes}
        end

      {:error, reason} ->
        {:error, file_path, reason}
    end
  end

  def rollback_changes(backup_dir \\ @backup_dir) do
    IO.puts("🔄 Rolling back changes from: #{backup_dir}")

    if not File.exists?(backup_dir) do
      IO.puts("❌ Backup directory not found: #{backup_dir}")
    else
      backup_files = find_backup_files(backup_dir)

      Enum.each(backup_files, fn backup_file ->
        original_file = restore_original_path(backup_file, backup_dir)

        case File.copy(backup_file, original_file) do
          {:ok, _} ->
            IO.puts("✅ Restored: #{original_file}")
          {:error, reason} ->
            IO.puts("❌ Failed to restore #{original_file}: #{reason}")
        end
      end)

      IO.puts("\n🔄 Rollback complete!")
      IO.puts("💡 Run tests to verify: mix test")
    end
  end

  # Private functions

  defp parse_args([]), do: {:scan, "."}
  defp parse_args(["help"]), do: {:help}
  defp parse_args(["--help"]), do: {:help}
  defp parse_args(["-h"]), do: {:help}
  defp parse_args(["scan"]), do: {:scan, "."}
  defp parse_args(["scan", directory]), do: {:scan, directory}
  defp parse_args(["preview", file]), do: {:preview, file}
  defp parse_args(["fix", "--all"]) do
    files = find_elixir_files(".")
    {:fix, files, []}
  end
  defp parse_args(["fix", "--all", "--dry-run"]) do
    files = find_elixir_files(".")
    {:fix, files, [dry_run: true]}
  end
  defp parse_args(["fix" | files]) when length(files) > 0 do
    {:fix, files, []}
  end
  defp parse_args(["rollback"]), do: {:rollback, @backup_dir}
  defp parse_args(["rollback", backup_dir]), do: {:rollback, backup_dir}
  defp parse_args(_), do: {:error, "Invalid arguments. Use --help for usage."}

  defp print_help do
    IO.puts("""
    StateV2 to State Migration Fixer Tool

    Usage:
      ./statev2_fixer.exs [command] [options]

    Commands:
      scan [directory]           Scan for StateV2 references (default: current directory)
      preview <file>             Preview changes for a specific file
      fix --all                  Fix all files with StateV2 references
      fix --all --dry-run        Preview fixes for all files (no changes)
      fix <file1> <file2> ...    Fix specific files
      rollback [backup_dir]      Rollback changes from backup
      help                       Show this help message

    Examples:
      ./statev2_fixer.exs scan
      ./statev2_fixer.exs preview test/some_test.exs
      ./statev2_fixer.exs fix --all
      ./statev2_fixer.exs fix lib/some_module.ex test/some_test.exs
      ./statev2_fixer.exs rollback

    Features:
      - Automatic StateV2 → State migration
      - Parameter reordering for function calls
      - Safe preview mode before applying changes
      - Automatic backups with rollback capability
      - Detailed transformation reports
    """)
  end

  defp find_elixir_files(directory) do
    Path.wildcard("#{directory}/**/*.{ex,exs}")
    |> Enum.filter(&File.regular?/1)
    |> Enum.sort()
  end

  defp scan_file(file_path) do
    case File.read(file_path) do
      {:ok, content} ->
        issues = find_statev2_references(content)
        {file_path, issues}
      {:error, _} ->
        {file_path, []}
    end
  end

  defp find_statev2_references(content) do
    lines = String.split(content, "\n")

    lines
    |> Enum.with_index(1)
    |> Enum.flat_map(fn {line, line_num} ->
      Enum.flat_map(transformations(), fn {type, regex, _replacement, description} ->
        if Regex.match?(regex, line) do
          [{line_num, line, type, description}]
        else
          []
        end
      end)
    end)
  end

  defp apply_transformations(content, file_path, opts \\ []) do
    dry_run = Keyword.get(opts, :dry_run, false)
    lines = String.split(content, "\n")
    changes = []

    {new_lines, all_changes} =
      lines
      |> Enum.with_index(1)
      |> Enum.map_reduce(changes, fn {line, line_num}, acc_changes ->
        {new_line, line_changes} = transform_line(line, line_num)
        {new_line, acc_changes ++ line_changes}
      end)

    new_content = Enum.join(new_lines, "\n")

    if not dry_run and length(all_changes) > 0 do
      Logger.info("Applied #{length(all_changes)} transformations to #{file_path}")
    end

    {new_content, all_changes}
  end

  defp transform_line(line, line_num) do
    {new_line, changes} =
      Enum.reduce(transformations(), {line, []}, fn {type, regex, replacement, description}, {current_line, acc_changes} ->
        if Regex.match?(regex, current_line) do
          transformed_line = Regex.replace(regex, current_line, replacement)
          change = {line_num, line, transformed_line, type, description}
          {transformed_line, [change | acc_changes]}
        else
          {current_line, acc_changes}
        end
      end)

    {new_line, Enum.reverse(changes)}
  end

  defp create_backup_dir do
    if not File.exists?(@backup_dir) do
      File.mkdir_p!(@backup_dir)
      IO.puts("📁 Created backup directory: #{@backup_dir}")
    end
  end

  defp backup_file(file_path) do
    backup_path = Path.join(@backup_dir, String.replace(file_path, "/", "_"))

    case File.copy(file_path, backup_path) do
      {:ok, _} ->
        Logger.debug("Backed up: #{file_path} → #{backup_path}")
      {:error, reason} ->
        Logger.warn("Failed to backup #{file_path}: #{reason}")
    end
  end

  defp find_backup_files(backup_dir) do
    Path.wildcard("#{backup_dir}/*")
    |> Enum.filter(&File.regular?/1)
  end

  defp restore_original_path(backup_file, backup_dir) do
    relative_backup = Path.relative_to(backup_file, backup_dir)
    String.replace(relative_backup, "_", "/")
  end

  defp generate_report(results, opts \\ []) do
    dry_run = Keyword.get(opts, :dry_run, false)

    successful = Enum.filter(results, fn
      {:ok, _, _, _} -> true
      _ -> false
    end)

    failed = Enum.filter(results, fn
      {:error, _, _} -> true
      _ -> false
    end)

    total_changes = successful
    |> Enum.map(fn {:ok, _, count, _} -> count end)
    |> Enum.sum()

    IO.puts("\n📊 Migration Report:")
    IO.puts("  Files processed: #{length(results)}")
    IO.puts("  Files modified: #{length(successful)}")
    IO.puts("  Total changes: #{total_changes}")

    if length(failed) > 0 do
      IO.puts("  Failed files: #{length(failed)}")
      Enum.each(failed, fn {:error, file, reason} ->
        IO.puts("    ❌ #{file}: #{reason}")
      end)
    end

    if dry_run do
      IO.puts("\n💡 This was a dry run - no files were modified")
      IO.puts("  To apply changes: remove --dry-run flag")
    end
  end
end

# Run the tool if called directly
if System.argv() != [] or __ENV__.file == Path.absname("statev2_fixer.exs") do
  StateV2Fixer.main(System.argv())
end
