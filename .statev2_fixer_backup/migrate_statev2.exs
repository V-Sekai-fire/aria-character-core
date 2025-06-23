#!/usr/bin/env elixir

# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule StateV2Migrator do
  @moduledoc """
  Migrates StateV2 references to State throughout the codebase.

  Usage:
    elixir migrate_statev2.exs --dry-run
    elixir migrate_statev2.exs --apply-all
    elixir migrate_statev2.exs --file path/to/file.ex
  """

  defstruct files_processed: 0,
            total_changes: 0,
            changes_by_type: %{},
            errors: []

  @type t :: %__MODULE__{
          files_processed: integer(),
          total_changes: integer(),
          changes_by_type: map(),
          errors: [String.t()]
        }

  def main(args \\ []) do
    case parse_args(args) do
      {:dry_run} ->
        IO.puts("🔍 StateV2 → State Migration Dry Run")
        IO.puts("=" |> String.duplicate(50))
        migrate_all(dry_run: true)

      {:apply_all} ->
        IO.puts("🚀 Applying StateV2 → State Migration")
        IO.puts("=" |> String.duplicate(50))
        migrate_all(dry_run: false)

      {:file, path} ->
        IO.puts("🔧 Migrating single file: #{path}")
        migrate_file(path, dry_run: false)

      {:help} ->
        print_help()

      {:error, msg} ->
        IO.puts("❌ Error: #{msg}")
        print_help()
    end
  end

  defp parse_args([]), do: {:dry_run}
  defp parse_args(["--dry-run"]), do: {:dry_run}
  defp parse_args(["--apply-all"]), do: {:apply_all}
  defp parse_args(["--file", path]), do: {:file, path}
  defp parse_args(["--help"]), do: {:help}
  defp parse_args(["-h"]), do: {:help}
  defp parse_args(_), do: {:error, "Invalid arguments"}

  defp print_help do
    IO.puts("""
    StateV2 Migration Tool

    Usage:
      elixir migrate_statev2.exs [options]

    Options:
      --dry-run     Show what would be changed (default)
      --apply-all   Apply all changes
      --file PATH   Migrate specific file
      --help, -h    Show this help
    """)
  end

  def migrate_all(opts \\ []) do
    dry_run = Keyword.get(opts, :dry_run, true)

    files = find_files_with_statev2()

    if dry_run do
      IO.puts("📁 Found #{length(files)} files with StateV2 references:")
      Enum.each(files, &IO.puts("  • #{&1}"))
      IO.puts("")
    end

    stats = %__MODULE__{}

    final_stats =
      Enum.reduce(files, stats, fn file, acc ->
        case migrate_file(file, dry_run: dry_run) do
          {:ok, file_stats} ->
            %{acc |
              files_processed: acc.files_processed + 1,
              total_changes: acc.total_changes + file_stats.total_changes,
              changes_by_type: merge_changes(acc.changes_by_type, file_stats.changes_by_type)
            }
          {:error, error} ->
            %{acc | errors: [error | acc.errors]}
        end
      end)

    print_summary(final_stats, dry_run)
  end

  def migrate_file(file_path, opts \\ []) do
    dry_run = Keyword.get(opts, :dry_run, true)

    case File.read(file_path) do
      {:ok, content} ->
        {new_content, changes} = apply_transformations(content, file_path)

        if changes.total_changes > 0 do
          if dry_run do
            print_file_changes(file_path, content, new_content, changes)
          else
            case File.write(file_path, new_content) do
              :ok ->
                IO.puts("✅ Updated #{file_path} (#{changes.total_changes} changes)")
              {:error, reason} ->
                {:error, "Failed to write #{file_path}: #{reason}"}
            end
          end
        end

        {:ok, changes}

      {:error, reason} ->
        {:error, "Failed to read #{file_path}: #{reason}"}
    end
  end

  def find_files_with_statev2 do
    ["lib/**/*.ex", "test/**/*.exs"]
    |> Enum.flat_map(&Path.wildcard/1)
    |> Enum.filter(&has_statev2_references?/1)
    |> Enum.sort()
  end

  defp has_statev2_references?(file_path) do
    case File.read(file_path) do
      {:ok, content} -> String.contains?(content, "StateV2")
      {:error, _} -> false
    end
  end

  def apply_transformations(content, _file_path) do
    changes = %__MODULE__{changes_by_type: %{}}

    # Apply transformations in order
    transformations = [
      {"update_fact calls", &transform_update_fact/1},
      {"matches_exactly calls", &transform_matches_exactly/1},
      {"get_fact calls", &transform_get_fact/1},
      {"exists calls", &transform_exists/1},
      {"forall calls", &transform_forall/1},
      {"evaluate_condition calls", &transform_evaluate_condition/1},
      {"get_subjects_with_fact calls", &transform_get_subjects_with_fact/1},
      {"get_subjects_with_predicate calls", &transform_get_subjects_with_predicate/1},
      {"type annotations", &transform_type_annotations/1},
      {"module references", &transform_module_references/1},
      {"new() calls", &transform_new_calls/1}
    ]

    {final_content, final_changes} =
      Enum.reduce(transformations, {content, changes}, fn {name, transform_fn}, {acc_content, acc_changes} ->
        {new_content, change_count} = transform_fn.(acc_content)

        updated_changes = if change_count > 0 do
          %{acc_changes |
            total_changes: acc_changes.total_changes + change_count,
            changes_by_type: Map.put(acc_changes.changes_by_type, name, change_count)
          }
        else
          acc_changes
        end

        {new_content, updated_changes}
      end)

    {final_content, final_changes}
  end

  # Transform StateV2.update_fact(state, subject, predicate, value) → State.set_fact(state, predicate, subject, value)
  defp transform_update_fact(content) do
    # Use a more sophisticated pattern that handles nested parentheses and complex expressions
    pattern = ~r/StateV2\.update_fact\(([^,]+),\s*([^,]+),\s*([^,]+),\s*([^)]+)\)/

    new_content = Regex.replace(pattern, content, fn _full_match, state, subject, predicate, value ->
      "State.set_fact(#{state}, #{predicate}, #{subject}, #{value})"
    end)

    change_count = count_pattern_matches(pattern, content)

    {new_content, change_count}
  end

  # Transform StateV2.matches_exactly?(state, subject, predicate, value) → State.matches?(state, predicate, subject, value)
  defp transform_matches_exactly(content) do
    pattern = ~r/StateV2\.matches_exactly\?\(([^,]+),\s*([^,]+),\s*([^,]+),\s*([^)]+)\)/
    replacement = "State.matches?(\\1, \\3, \\2, \\4)"

    new_content = Regex.replace(pattern, content, replacement)
    change_count = count_pattern_matches(pattern, content)

    {new_content, change_count}
  end

  # Transform StateV2.get_fact(state, subject, predicate) → State.get_fact(state, predicate, subject)
  defp transform_get_fact(content) do
    pattern = ~r/StateV2\.get_fact\(([^,]+),\s*([^,]+),\s*([^)]+)\)/
    replacement = "State.get_fact(\\1, \\3, \\2)"

    new_content = Regex.replace(pattern, content, replacement)
    change_count = count_pattern_matches(pattern, content)

    {new_content, change_count}
  end

  # Transform StateV2.exists?(state, filter, predicate, value) → State.exists?(state, predicate, value, filter)
  defp transform_exists(content) do
    pattern = ~r/StateV2\.exists\?\(([^,]+),\s*([^,]+),\s*([^,]+),\s*([^)]+)\)/
    replacement = "State.exists?(\\1, \\3, \\4, \\2)"

    new_content = Regex.replace(pattern, content, replacement)
    change_count = count_pattern_matches(pattern, content)

    {new_content, change_count}
  end

  # Transform StateV2.forall?(state, filter, predicate, value) → State.forall?(state, predicate, value, filter)
  defp transform_forall(content) do
    pattern = ~r/StateV2\.forall\?\(([^,]+),\s*([^,]+),\s*([^,]+),\s*([^)]+)\)/
    replacement = "State.forall?(\\1, \\3, \\4, \\2)"

    new_content = Regex.replace(pattern, content, replacement)
    change_count = count_pattern_matches(pattern, content)

    {new_content, change_count}
  end

  # Transform StateV2.evaluate_condition(state, condition) → State.evaluate_condition(state, condition)
  defp transform_evaluate_condition(content) do
    pattern = ~r/StateV2\.evaluate_condition\(/
    replacement = "State.evaluate_condition("

    new_content = Regex.replace(pattern, content, replacement)
    change_count = count_pattern_matches(pattern, content)

    {new_content, change_count}
  end

  # Transform StateV2.get_subjects_with_fact(state, predicate, value) → State.get_subjects_with_fact(state, predicate, value)
  defp transform_get_subjects_with_fact(content) do
    pattern = ~r/StateV2\.get_subjects_with_fact\(/
    replacement = "State.get_subjects_with_fact("

    new_content = Regex.replace(pattern, content, replacement)
    change_count = count_pattern_matches(pattern, content)

    {new_content, change_count}
  end

  # Transform StateV2.get_subjects_with_predicate(state, predicate) → State.get_subjects_with_predicate(state, predicate)
  defp transform_get_subjects_with_predicate(content) do
    pattern = ~r/StateV2\.get_subjects_with_predicate\(/
    replacement = "State.get_subjects_with_predicate("

    new_content = Regex.replace(pattern, content, replacement)
    change_count = count_pattern_matches(pattern, content)

    {new_content, change_count}
  end

  # Transform type annotations: AriaEngine.StateV2.t() → State.t(), StateV2.subject() → State.subject(), etc.
  defp transform_type_annotations(content) do
    patterns_and_replacements = [
      {~r/AriaEngine\.StateV2\.t\(\)/, "State.t()"},
      {~r/StateV2\.t\(\)/, "State.t()"},
      {~r/StateV2\.subject\(\)/, "State.subject()"},
      {~r/StateV2\.predicate\(\)/, "State.predicate()"},
      {~r/StateV2\.fact_value\(\)/, "State.fact_value()"}
    ]

    {new_content, total_changes} =
      Enum.reduce(patterns_and_replacements, {content, 0}, fn {pattern, replacement}, {acc_content, acc_count} ->
        new_content = Regex.replace(pattern, acc_content, replacement)
        change_count = count_pattern_matches(pattern, acc_content)
        {new_content, acc_count + change_count}
      end)

    {new_content, total_changes}
  end

  # Transform module references: AriaEngine.StateV2 → State (but not in type annotations)
  defp transform_module_references(content) do
    pattern = ~r/AriaEngine\.StateV2(?!\.t\(\))/
    replacement = "State"

    new_content = Regex.replace(pattern, content, replacement)
    change_count = count_pattern_matches(pattern, content)

    {new_content, change_count}
  end

  # Transform StateV2.new() → State.new()
  defp transform_new_calls(content) do
    pattern = ~r/StateV2\.new\(/
    replacement = "State.new("

    new_content = Regex.replace(pattern, content, replacement)
    change_count = count_pattern_matches(pattern, content)

    {new_content, change_count}
  end

  defp count_pattern_matches(pattern, content) do
    Regex.scan(pattern, content) |> length()
  end

  defp print_file_changes(file_path, original_content, new_content, changes) do
    if changes.total_changes > 0 do
      IO.puts("\n📄 #{file_path}")
      IO.puts("   Changes: #{changes.total_changes}")

      Enum.each(changes.changes_by_type, fn {type, count} ->
        IO.puts("   • #{type}: #{count}")
      end)

      # Show diff for first few changes
      show_diff_preview(original_content, new_content)
    end
  end

  defp show_diff_preview(original, new) do
    original_lines = String.split(original, "\n")
    new_lines = String.split(new, "\n")

    # Find first few differences
    differences =
      Enum.zip(original_lines, new_lines)
      |> Enum.with_index()
      |> Enum.filter(fn {{orig, new}, _idx} -> orig != new end)
      |> Enum.take(3)

    if length(differences) > 0 do
      IO.puts("   Preview:")
      Enum.each(differences, fn {{orig, new}, idx} ->
        IO.puts("     Line #{idx + 1}:")
        IO.puts("     - #{String.trim(orig)}")
        IO.puts("     + #{String.trim(new)}")
      end)
    end
  end

  defp merge_changes(changes1, changes2) do
    Map.merge(changes1, changes2, fn _key, v1, v2 -> v1 + v2 end)
  end

  defp print_summary(stats, dry_run) do
    IO.puts("\n" <> "=" |> String.duplicate(50))

    if dry_run do
      IO.puts("📊 Dry Run Summary")
    else
      IO.puts("✅ Migration Complete")
    end

    IO.puts("Files processed: #{stats.files_processed}")
    IO.puts("Total changes: #{stats.total_changes}")

    if map_size(stats.changes_by_type) > 0 do
      IO.puts("\nChanges by type:")
      Enum.each(stats.changes_by_type, fn {type, count} ->
        IO.puts("  • #{type}: #{count}")
      end)
    end

    if length(stats.errors) > 0 do
      IO.puts("\n❌ Errors:")
      Enum.each(stats.errors, &IO.puts("  • #{&1}"))
    end

    if dry_run and stats.total_changes > 0 do
      IO.puts("\n🚀 To apply these changes, run:")
      IO.puts("   elixir migrate_statev2.exs --apply-all")
    end
  end
end

# Run the script if called directly
if __ENV__.file == :stdin do
  StateV2Migrator.main(System.argv())
else
  StateV2Migrator.main(System.argv())
end
