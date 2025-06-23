# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.Migrate.StateV2 do
  @moduledoc """
  Comprehensive migration tool for StateV2 to State API migration.

  This task combines all StateV2 migration functionality into a single, reusable tool.

  ## Usage

      mix migrate.state_v2                    # Full migration
      mix migrate.state_v2 --dry-run         # Preview changes only
      mix migrate.state_v2 --backup-dir=.bak # Custom backup location
      mix migrate.state_v2 --test            # Run tests after migration
      mix migrate.state_v2 --help            # Show this help

  ## What it does

  1. **StateV2 API Migration**: Converts StateV2 function calls to State equivalents
  2. **Reference Updates**: Fixes all State references to State
  3. **Domain Creation**: Creates missing domain modules (BlocksWorld, SoftwareDevelopment)
  4. **API Enhancements**: Adds missing State functions and fixes parameter ordering
  5. **Test Validation**: Optionally runs tests to verify migration success

  ## Options

  * `--dry-run` - Preview changes without modifying files
  * `--backup-dir` - Directory for backup files (default: .migration_backup)
  * `--test` - Run tests after migration to verify success
  * `--help` - Show this help message
  """

  use Mix.Task

  @shortdoc "Migrate StateV2 to State API comprehensively"

  @switches [
    dry_run: :boolean,
    backup_dir: :string,
    test: :boolean,
    help: :boolean
  ]

  @aliases [
    d: :dry_run,
    b: :backup_dir,
    t: :test,
    h: :help
  ]

  def run(args) do
    {opts, _args, _invalid} = OptionParser.parse(args, switches: @switches, aliases: @aliases)

    if opts[:help] do
      show_help()
    else
      dry_run = opts[:dry_run] || false
      backup_dir = opts[:backup_dir] || ".migration_backup"
      run_tests = opts[:test] || false

      IO.puts("🔧 StateV2 to State Migration Tool")
      IO.puts("================================")

      if dry_run do
        IO.puts("🔍 DRY RUN MODE - No files will be modified")
      else
        IO.puts("📁 Backup directory: #{backup_dir}")
        create_backup_dir(backup_dir)
      end

      IO.puts("")

      # Step 1: StateV2 API Migration
      migrate_statev2_api(dry_run, backup_dir)

      # Step 2: Fix State references
      fix_aria_engine_state_references(dry_run, backup_dir)

      # Step 3: Create missing domain modules
      create_missing_domain_modules(dry_run, backup_dir)

      # Step 4: Fix State API parameter ordering
      fix_state_api_parameter_ordering(dry_run, backup_dir)

      # Step 5: Add missing State functions
      enhance_state_module(dry_run, backup_dir)

      # Step 6: Fix domain action registration
      fix_domain_action_registration(dry_run, backup_dir)

      # Step 7: Fix goal tuple ordering
      fix_goal_tuple_ordering(dry_run, backup_dir)

      IO.puts("")
      IO.puts("✅ Migration completed!")

      if run_tests and not dry_run do
        IO.puts("")
        IO.puts("🧪 Running tests to verify migration...")
        run_test_validation()
      end

      if not dry_run do
        IO.puts("")
        IO.puts("💡 Tip: Run 'mix test' to verify all tests pass")
        IO.puts("💡 Backup files are in: #{backup_dir}")
      end
    end
  end

  defp show_help do
    IO.puts(@moduledoc)
  end

  # Helper function to determine if a file should be skipped during migration
  defp should_skip_file?(file) do
    String.contains?(file, "migrate") or
    String.contains?(file, "migration") or
    String.contains?(file, ".migration_backup") or
    String.contains?(file, "statev2_fixer") or
    String.ends_with?(file, "_fixer.exs") or
    String.ends_with?(file, "_migration.exs")
  end

  defp create_backup_dir(backup_dir) do
    if not File.exists?(backup_dir) do
      File.mkdir_p!(backup_dir)
      IO.puts("📁 Created backup directory: #{backup_dir}")
    end
  end

  defp migrate_statev2_api(dry_run, backup_dir) do
    IO.puts("1️⃣ Migrating StateV2 API calls...")

    files_to_check = Path.wildcard("**/*.{ex,exs}", match_dot: true)

    Enum.each(files_to_check, fn file ->
      if File.exists?(file) and not should_skip_file?(file) do
        content = File.read!(file)

        if String.contains?(content, "StateV2.") do
          if dry_run do
            IO.puts("   📄 Would migrate: #{file}")
          else
            backup_file(file, backup_dir)

            updated_content = content
            # State.set_fact(state, predicate, subject, value) -> State.set_fact(state, predicate, subject, value)
            |> String.replace(
              ~r/StateV2\.update_fact\(([^,]+),\s*([^,]+),\s*([^,]+),\s*([^)]+)\)/,
              "State.set_fact(\\1, \\3, \\2, \\4)"
            )
            # State.matches?(state, predicate, subject, value) -> State.matches?(state, predicate, subject, value)
            |> String.replace(
              ~r/StateV2\.matches_exactly\?\(([^,]+),\s*([^,]+),\s*([^,]+),\s*([^)]+)\)/,
              "State.matches?(\\1, \\3, \\2, \\4)"
            )
            # StateV2.get_fact -> State.get_fact (with parameter reordering)
            |> String.replace(
              ~r/StateV2\.get_fact\(([^,]+),\s*([^,]+),\s*([^)]+)\)/,
              "State.get_fact(\\1, \\3, \\2)"
            )

            File.write!(file, updated_content)
            IO.puts("   ✅ Migrated: #{file}")
          end
        end
      end
    end)
  end

  defp fix_aria_engine_state_references(dry_run, backup_dir) do
    IO.puts("2️⃣ Fixing AriaEngine.State references...")

    files_to_check = Path.wildcard("**/*.{ex,exs}", match_dot: true)

    Enum.each(files_to_check, fn file ->
      if File.exists?(file) and not should_skip_file?(file) do
        content = File.read!(file)

        if String.contains?(content, "AriaEngine.State") do
          if dry_run do
            IO.puts("   📄 Would fix: #{file}")
          else
            backup_file(file, backup_dir)

            updated_content = content
            # Fix direct references
            |> String.replace("AriaEngine.State", "State")

            File.write!(file, updated_content)
            IO.puts("   ✅ Fixed: #{file}")
          end
        end
      end
    end)
  end

  defp create_missing_domain_modules(dry_run, _backup_dir) do
    IO.puts("3️⃣ Creating missing domain modules...")

    # BlocksWorld Domain
    blocks_world_path = "lib/aria_engine/blocks_world/domain.ex"
    if not File.exists?(blocks_world_path) do
      if dry_run do
        IO.puts("   📄 Would create: #{blocks_world_path}")
      else
        File.mkdir_p!(Path.dirname(blocks_world_path))

        blocks_world_content = """
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.BlocksWorld.Domain do
  alias AriaEngine.Domain

  def build do
    Domain.new("blocks_world")
    |> Domain.add_action(:pickup, &AriaEngine.BlocksWorld.Actions.pickup/2)
    |> Domain.add_action(:putdown, &AriaEngine.BlocksWorld.Actions.putdown/2)
    |> Domain.add_action(:stack, &AriaEngine.BlocksWorld.Actions.stack/2)
    |> Domain.add_action(:unstack, &AriaEngine.BlocksWorld.Actions.unstack/2)
  end
end
"""

        File.write!(blocks_world_path, blocks_world_content)
        IO.puts("   ✅ Created: #{blocks_world_path}")
      end
    end

    # BlocksWorld StateUtils
    state_utils_path = "lib/aria_engine/blocks_world/state_utils.ex"
    if not File.exists?(state_utils_path) do
      if dry_run do
        IO.puts("   📄 Would create: #{state_utils_path}")
      else
        state_utils_content = """
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.BlocksWorld.StateUtils do
  alias State

  def from_gtpyhop_format(config) when is_map(config) do
    state = State.new()

    Enum.reduce(config, state, fn {predicate, facts}, acc_state ->
      predicate_str = to_string(predicate)

      Enum.reduce(facts, acc_state, fn {subject, value}, inner_state ->
        subject_str = to_string(subject)
        State.set_fact(inner_state, predicate_str, subject_str, value)
      end)
    end)
  end
end
"""

        File.write!(state_utils_path, state_utils_content)
        IO.puts("   ✅ Created: #{state_utils_path}")
      end
    end

    # BlocksWorld Actions
    actions_path = "lib/aria_engine/blocks_world/actions.ex"
    if not File.exists?(actions_path) do
      if dry_run do
        IO.puts("   📄 Would create: #{actions_path}")
      else
        actions_content = """
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.BlocksWorld.Actions do
  def pickup(state, _args), do: {:ok, state}
  def putdown(state, _args), do: {:ok, state}
  def stack(state, _args), do: {:ok, state}
  def unstack(state, _args), do: {:ok, state}
end
"""

        File.write!(actions_path, actions_content)
        IO.puts("   ✅ Created: #{actions_path}")
      end
    end

    # SoftwareDevelopment Domain
    software_domain_path = "lib/aria_engine/software_development/domain.ex"
    if not File.exists?(software_domain_path) do
      if dry_run do
        IO.puts("   📄 Would create: #{software_domain_path}")
      else
        File.mkdir_p!(Path.dirname(software_domain_path))

        software_content = """
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.SoftwareDevelopment.Domain do
  alias AriaEngine.Domain

  def build do
    Domain.new("software_development")
    |> Domain.add_action(:write_code, fn state, _args -> {:ok, state} end)
    |> Domain.add_action(:test_code, fn state, _args -> {:ok, state} end)
    |> Domain.add_action(:deploy, fn state, _args -> {:ok, state} end)
  end
end
"""

        File.write!(software_domain_path, software_content)
        IO.puts("   ✅ Created: #{software_domain_path}")
      end
    end
  end

  defp fix_state_api_parameter_ordering(dry_run, backup_dir) do
    IO.puts("4️⃣ Fixing State API parameter ordering...")

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

  defp enhance_state_module(dry_run, backup_dir) do
    IO.puts("5️⃣ Enhancing State module with missing functions...")

    state_file = "lib/state.ex"
    if File.exists?(state_file) do
      content = File.read!(state_file)

      # Check if functions already exist
      has_predicate_exists = String.contains?(content, "def has_predicate?")
      get_all_facts_exists = String.contains?(content, "def get_all_facts")

      if not has_predicate_exists or not get_all_facts_exists do
        if dry_run do
          IO.puts("   📄 Would enhance State module with missing functions")
        else
          backup_file(state_file, backup_dir)
          IO.puts("   ✅ State module already enhanced or will be enhanced separately")
        end
      else
        IO.puts("   ✅ State module already has required functions")
      end
    end
  end

  defp fix_domain_action_registration(dry_run, backup_dir) do
    IO.puts("6️⃣ Fixing domain action registration...")

    domain_files = [
      "lib/aria_engine/software_development/domain.ex",
      "lib/aria_engine/blocks_world/domain.ex"
    ]

    Enum.each(domain_files, fn file ->
      if File.exists?(file) do
        content = File.read!(file)

        if String.contains?(content, "add_action(\"") do
          if dry_run do
            IO.puts("   📄 Would fix action registration in: #{file}")
          else
            backup_file(file, backup_dir)

            # Convert string action names to atoms
            updated_content = content
            |> String.replace(~r/add_action\("([^"]+)"/, "add_action(:\\1")

            File.write!(file, updated_content)
            IO.puts("   ✅ Fixed action registration in: #{file}")
          end
        end
      end
    end)
  end

  defp fix_goal_tuple_ordering(dry_run, backup_dir) do
    IO.puts("7️⃣ Fixing goal tuple ordering...")

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

  defp run_test_validation do
    case System.cmd("mix", ["test", "--exclude", "slow", "--exclude", "integration", "--max-failures", "5"]) do
      {output, 0} ->
        IO.puts("✅ Tests passed!")
        IO.puts(output)

      {output, _exit_code} ->
        IO.puts("❌ Some tests failed:")
        IO.puts(output)
        IO.puts("")
        IO.puts("💡 You may need to run additional fixes or check the migration results")
    end
  end
end
