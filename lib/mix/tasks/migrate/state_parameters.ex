# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.Migrate.StateParameters do
  @moduledoc """
  Fix State API parameter ordering to match State.set_fact(state, predicate, subject, value).

  This task updates State.set_fact calls to use the correct parameter order.

  ## Usage

      mix migrate.state_parameters                    # Full migration
      mix migrate.state_parameters --dry-run         # Preview changes only
      mix migrate.state_parameters --backup-dir=.bak # Custom backup location

  ## What it does

  - Fixes State.set_fact parameter ordering from (state, subject, predicate, value) to (state, predicate, subject, value)
  - Handles various patterns of State.set_fact calls
  - Preserves functionality while correcting parameter order
  """

  use Mix.Task

  @shortdoc "Fix State API parameter ordering"

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

    IO.puts("🔧 State Parameter Ordering Migration")
    IO.puts("====================================")

    if dry_run do
      IO.puts("🔍 DRY RUN MODE - No files will be modified")
    else
      IO.puts("📁 Backup directory: #{backup_dir}")
      create_backup_dir(backup_dir)
    end

    fix_state_api_parameter_ordering(dry_run, backup_dir)

    IO.puts("✅ State parameter ordering migration completed!")
  end

  defp create_backup_dir(backup_dir) do
    if not File.exists?(backup_dir) do
      File.mkdir_p!(backup_dir)
      IO.puts("📁 Created backup directory: #{backup_dir}")
    end
  end

  defp fix_state_api_parameter_ordering(dry_run, backup_dir) do
    IO.puts("Fixing State API parameter ordering...")

    files_to_fix = [
      "test/aria_engine/multigoal_optimization_test.exs",
      "test/aria_engine/test/aria_engine/state_quantifiers_test.exs"
    ]

    Enum.each(files_to_fix, fn file ->
      if File.exists?(file) do
        content = File.read!(file)

        if String.contains?(content, "State.set_fact") do
          if dry_run do
            IO.puts("   📄 Would fix parameter ordering in: #{file}")
          else
            backup_file(file, backup_dir)

            # Fix various State.set_fact parameter ordering patterns
            updated_content = content
            |> String.replace(~r/State\.set_fact\(([^,]+),\s*"robot",\s*"location",\s*([^)]+)\)/, "State.set_fact(\\1, \"location\", \"robot\", \\2)")
            |> String.replace(~r/State\.set_fact\(([^,]+),\s*"package_([^"]+)",\s*"location",\s*([^)]+)\)/, "State.set_fact(\\1, \"location\", \"package_\\2\", \\3)")
            |> String.replace(~r/State\.set_fact\(([^,]+),\s*"package_([^"]+)",\s*"weight",\s*([^)]+)\)/, "State.set_fact(\\1, \"weight\", \"package_\\2\", \\3)")
            |> String.replace(~r/State\.set_fact\(([^,]+),\s*"agent_([^"]+)",\s*"location",\s*([^)]+)\)/, "State.set_fact(\\1, \"location\", \"agent_\\2\", \\3)")
            |> String.replace(~r/State\.set_fact\(([^,]+),\s*"agent_([^"]+)",\s*"capacity",\s*([^)]+)\)/, "State.set_fact(\\1, \"capacity\", \"agent_\\2\", \\3)")
            |> String.replace(~r/State\.set_fact\(([^,]+),\s*"task_([^"]+)",\s*"status",\s*([^)]+)\)/, "State.set_fact(\\1, \"status\", \"task_\\2\", \\3)")
            |> String.replace(~r/State\.set_fact\(([^,]+),\s*"task_([^"]+)",\s*"depends_on",\s*([^)]+)\)/, "State.set_fact(\\1, \"depends_on\", \"task_\\2\", \\3)")
            |> String.replace(~r/State\.set_fact\(([^,]+),\s*"resource_([^"]+)",\s*"available",\s*([^)]+)\)/, "State.set_fact(\\1, \"available\", \"resource_\\2\", \\3)")
            |> String.replace(~r/State\.set_fact\(([^,]+),\s*"resource_([^"]+)",\s*"capacity",\s*([^)]+)\)/, "State.set_fact(\\1, \"capacity\", \"resource_\\2\", \\3)")
            |> String.replace(~r/State\.set_fact\(([^,]+),\s*"goal_([^"]+)",\s*"impossible",\s*([^)]+)\)/, "State.set_fact(\\1, \"impossible\", \"goal_\\2\", \\3)")
            |> String.replace(~r/State\.set_fact\(([^,]+),\s*"([^"]+)",\s*"status",\s*"([^"]+)"\)/, "State.set_fact(\\1, \"status\", \"\\2\", \"\\3\")")
            |> String.replace(~r/State\.set_fact\(([^,]+),\s*"([^"]+)",\s*"type",\s*"([^"]+)"\)/, "State.set_fact(\\1, \"type\", \"\\2\", \"\\3\")")
            |> String.replace(~r/State\.set_fact\(([^,]+),\s*"([^"]+)",\s*"location",\s*"([^"]+)"\)/, "State.set_fact(\\1, \"location\", \"\\2\", \"\\3\")")
            |> String.replace(~r/State\.set_fact\(([^,]+),\s*"([^"]+)",\s*"available",\s*([^)]+)\)/, "State.set_fact(\\1, \"available\", \"\\2\", \\3)")

            File.write!(file, updated_content)
            IO.puts("   ✅ Fixed parameter ordering in: #{file}")
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
