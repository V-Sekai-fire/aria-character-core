# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.Migrate.GoalTuples do
  @moduledoc """
  Fix goal tuple ordering from {subject, predicate, object} to {predicate, subject, object}.

  This task updates goal tuple patterns throughout the codebase to match the State API format.

  ## Usage

      mix migrate.goal_tuples                    # Full migration
      mix migrate.goal_tuples --dry-run         # Preview changes only
      mix migrate.goal_tuples --backup-dir=.bak # Custom backup location

  ## What it does

  - Converts {subject, predicate, object} tuples to {predicate, subject, object}
  - Handles common predicates: location, has, state, assigned_to, status, type, etc.
  - Preserves tuple structure while reordering parameters
  """

  use Mix.Task

  @shortdoc "Fix goal tuple ordering for State API compatibility"

  @switches [
    dry_run: :boolean,
    backup_dir: :string
  ]

  @aliases [
    d: :dry_run,
    b: :backup_dir
  ]

  def run(args) do
    {opts, _args, _invalid} = OptionParser.parse(args, switches: @switches, aliases: @aliases)

    dry_run = opts[:dry_run] || false
    backup_dir = opts[:backup_dir] || ".migration_backup"

    IO.puts("🔧 Goal Tuple Ordering Migration")
    IO.puts("===============================")

    if dry_run do
      IO.puts("🔍 DRY RUN MODE - No files will be modified")
    else
      IO.puts("📁 Backup directory: #{backup_dir}")
      create_backup_dir(backup_dir)
    end

    fix_goal_tuple_ordering(dry_run, backup_dir)

    IO.puts("✅ Goal tuple ordering migration completed!")
  end

  defp should_skip_file?(file) do
    String.contains?(file, "migrate") or
    String.contains?(file, "migration") or
    String.contains?(file, ".migration_backup") or
    String.contains?(file, "statev2_fixer") or
    String.ends_with?(file, "_fixer.exs") or
    String.ends_with?(file, "_migration.exs") or
    String.contains?(file, "_build/") or
    String.contains?(file, "deps/") or
    String.contains?(file, ".elixir_ls/") or
    String.contains?(file, "priv/templates/") or
    String.contains?(file, "thirdparty/")
  end

  defp create_backup_dir(backup_dir) do
    if not File.exists?(backup_dir) do
      File.mkdir_p!(backup_dir)
      IO.puts("📁 Created backup directory: #{backup_dir}")
    end
  end

  defp fix_goal_tuple_ordering(dry_run, backup_dir) do
    IO.puts("Fixing goal tuple ordering...")

    files_to_check = Path.wildcard("**/*.{ex,exs}", match_dot: true)

    Enum.each(files_to_check, fn file ->
      if File.exists?(file) and not should_skip_file?(file) do
        content = File.read!(file)

        # Check for goal tuple patterns that need reordering
        needs_fixing = String.contains?(content, "{\"") and
                      (String.contains?(content, "location") or
                       String.contains?(content, "has") or
                       String.contains?(content, "state") or
                       String.contains?(content, "assigned_to"))

        if needs_fixing do
          if dry_run do
            IO.puts("   📄 Would fix goal tuples in: #{file}")
          else
            backup_file(file, backup_dir)

            updated_content = content
            # Fix common goal tuple patterns: {subject, predicate, object} -> {predicate, subject, object}
            |> String.replace(~r/\{"([^"]+)",\s*"location",\s*"([^"]+)"\}/, "{\"location\", \"\\1\", \"\\2\"}")
            |> String.replace(~r/\{"([^"]+)",\s*"has",\s*"([^"]+)"\}/, "{\"has\", \"\\1\", \"\\2\"}")
            |> String.replace(~r/\{"([^"]+)",\s*"has_key",\s*([^}]+)\}/, "{\"has_key\", \"\\1\", \\2}")
            |> String.replace(~r/\{"([^"]+)",\s*"state",\s*"([^"]+)"\}/, "{\"state\", \"\\1\", \"\\2\"}")
            |> String.replace(~r/\{"([^"]+)",\s*"assigned_to",\s*"([^"]+)"\}/, "{\"assigned_to\", \"\\1\", \"\\2\"}")
            |> String.replace(~r/\{"([^"]+)",\s*"status",\s*"([^"]+)"\}/, "{\"status\", \"\\1\", \"\\2\"}")
            |> String.replace(~r/\{"([^"]+)",\s*"type",\s*"([^"]+)"\}/, "{\"type\", \"\\1\", \"\\2\"}")
            |> String.replace(~r/\{"([^"]+)",\s*"available",\s*([^}]+)\}/, "{\"available\", \"\\1\", \\2}")
            |> String.replace(~r/\{"([^"]+)",\s*"capacity",\s*([^}]+)\}/, "{\"capacity\", \"\\1\", \\2}")
            |> String.replace(~r/\{"([^"]+)",\s*"weight",\s*([^}]+)\}/, "{\"weight\", \"\\1\", \\2}")
            |> String.replace(~r/\{"([^"]+)",\s*"battery",\s*([^}]+)\}/, "{\"battery\", \"\\1\", \\2}")
            |> String.replace(~r/\{"([^"]+)",\s*"carrying",\s*([^}]+)\}/, "{\"carrying\", \"\\1\", \\2}")

            if updated_content != content do
              File.write!(file, updated_content)
              IO.puts("   ✅ Fixed goal tuples in: #{file}")
            end
          end
        end
      end
    end)
  end

  defp backup_file(file, backup_dir) do
    backup_path = Path.join(backup_dir, file)
    backup_dir_path = Path.dirname(backup_path)

    File.mkdir_p!(backup_dir_path)
    File.cp!(file, backup_path)
  end
end
