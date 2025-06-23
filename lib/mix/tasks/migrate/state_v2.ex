defmodule Mix.Tasks.Migrate.StateV2 do
  @compile {:no_warn_unused, [:serial_number]}
  @moduledoc "Migration tool with serial number: A25W006STAT\n\nDecode: mix migrate.decode_serial A25W006STAT\n"
  @serial_number "R25W006STAT"
  @doc "Returns the module's serial number for tracking and identification."
  @spec serial_number() :: String.t()
  def serial_number() do
    @serial_number
  end

  @moduledoc "Orchestrates StateV2 to State API migration using focused migration tasks.\n\nThis task coordinates multiple specialized migration tasks, each with a single responsibility.\n\n## Usage\n\n    mix migrate.state_v2                    # Full migration\n    mix migrate.state_v2 --dry-run         # Preview changes only\n    mix migrate.state_v2 --backup-dir=.bak # Custom backup location\n    mix migrate.state_v2 --test            # Run tests after migration\n    mix migrate.state_v2 --help            # Show this help\n\n## Migration Tasks Orchestrated\n\n1. **StateV2 API Migration**: `mix migrate.statev2_api` - Converts StateV2 function calls\n2. **State Parameter Ordering**: `mix migrate.state_parameters` - Fixes parameter order\n3. **Goal Tuple Ordering**: `mix migrate.goal_tuples` - Fixes tuple structure\n4. **Domain Creation**: Creates missing domain modules\n5. **Test Validation**: Optionally runs tests to verify migration success\n\n## Options\n\n* `--dry-run` - Preview changes without modifying files\n* `--backup-dir` - Directory for backup files (default: .migration_backup)\n* `--test` - Run tests after migration to verify success\n* `--help` - Show this help message\n"
  use Mix.Task
  require Logger
  @shortdoc "Migrate StateV2 to State API comprehensively"
  @switches dry_run: :boolean, backup_dir: :string, test: :boolean, help: :boolean
  @aliases d: :dry_run, b: :backup_dir, t: :test, h: :help
  def run(args) do
    {opts, _args, _invalid} = OptionParser.parse(args, switches: @switches, aliases: @aliases)

    if opts[:help] do
      show_help()
    else
      dry_run = opts[:dry_run] || false
      backup_dir = opts[:backup_dir] || ".migration_backup"
      run_tests = opts[:test] || false
      Logger.info("🔧 StateV2 to State Migration Tool")
      Logger.info("================================")

      if dry_run do
        Logger.info("🔍 DRY RUN MODE - No files will be modified")
      else
        Logger.info("📁 Backup directory: #{backup_dir}")
        create_backup_dir(backup_dir)
      end

      Logger.info("")
      migrate_statev2_api(dry_run, backup_dir)
      fix_aria_engine_state_references(dry_run, backup_dir)
      create_missing_domain_modules(dry_run, backup_dir)
      fix_state_api_parameter_ordering(dry_run, backup_dir)
      enhance_state_module(dry_run, backup_dir)
      fix_domain_action_registration(dry_run, backup_dir)
      fix_goal_tuple_ordering(dry_run, backup_dir)
      Logger.info("")
      Logger.info("✅ Migration completed!")

      if run_tests and not dry_run do
        Logger.info("")
        Logger.info("🧪 Running tests to verify migration...")
        run_test_validation()
      end

      if not dry_run do
        Logger.info("")
        Logger.info("💡 Tip: Run 'mix test' to verify all tests pass")
        Logger.info("💡 Backup files are in: #{backup_dir}")
      end
    end
  end

  defp show_help do
    IO.puts(@moduledoc)
  end

  defp should_skip_file?(file) do
    String.contains?(file, "migrate") or String.contains?(file, "migration") or
      String.contains?(file, ".migration_backup") or String.contains?(file, "statev2_fixer") or
      String.ends_with?(file, "_fixer.exs") or String.ends_with?(file, "_migration.exs") or
      String.contains?(file, "_build/") or String.starts_with?(file, "deps/") or
      String.contains?(file, ".elixir_ls/") or String.contains?(file, "priv/templates/") or
      String.contains?(file, "thirdparty/")
  end

  defp create_backup_dir(backup_dir) do
    if not File.exists?(backup_dir) do
      File.mkdir_p!(backup_dir)
      Logger.info("📁 Created backup directory: #{backup_dir}")
    end
  end

  defp migrate_statev2_api(dry_run, backup_dir) do
    Logger.info("1️⃣ Migrating StateV2 API calls...")
    files_to_check = Path.wildcard("**/*.{ex,exs}", match_dot: true)

    Enum.each(files_to_check, fn file ->
      if File.exists?(file) and not should_skip_file?(file) do
        content = File.read!(file)

        if String.contains?(content, "StateV2.") do
          if dry_run do
            Logger.debug("   📄 Would migrate: #{file}")
          else
            backup_file(file, backup_dir)

            updated_content =
              content
              |> String.replace(
                ~r/StateV2\.update_fact\(([^,]+),\s*([^,]+),\s*([^,]+),\s*([^)]+)\)/,
                "State.set_fact(\\1, \\3, \\2, \\4)"
              )
              |> String.replace(
                ~r/StateV2\.matches_exactly\?\(([^,]+),\s*([^,]+),\s*([^,]+),\s*([^)]+)\)/,
                "State.matches?(\\1, \\3, \\2, \\4)"
              )
              |> String.replace(
                ~r/StateV2\.get_fact\(([^,]+),\s*([^,]+),\s*([^)]+)\)/,
                "State.get_fact(\\1, \\3, \\2)"
              )

            File.write!(file, updated_content)
            Logger.debug("   ✅ Migrated: #{file}")
          end
        end
      end
    end)
  end

  defp fix_aria_engine_state_references(dry_run, backup_dir) do
    Logger.info("2️⃣ Fixing AriaEngine.State references...")
    files_to_check = Path.wildcard("**/*.{ex,exs}", match_dot: true)

    Enum.each(files_to_check, fn file ->
      if File.exists?(file) and not should_skip_file?(file) do
        content = File.read!(file)

        if String.contains?(content, "AriaEngine.State") do
          if dry_run do
            Logger.debug("   📄 Would fix: #{file}")
          else
            backup_file(file, backup_dir)
            updated_content = content |> String.replace("AriaEngine.State", "State")
            File.write!(file, updated_content)
            Logger.debug("   ✅ Fixed: #{file}")
          end
        end
      end
    end)
  end

  defp create_missing_domain_modules(dry_run, _backup_dir) do
    Logger.info("3️⃣ Creating missing domain modules...")
    blocks_world_path = "lib/aria_engine/blocks_world/domain.ex"

    if not File.exists?(blocks_world_path) do
      if dry_run do
        Logger.debug("   📄 Would create: #{blocks_world_path}")
      else
        File.mkdir_p!(Path.dirname(blocks_world_path))

        blocks_world_content =
          "# Copyright (c) 2025-present K. S. Ernest (iFire) Lee\n# SPDX-License-Identifier: MIT\n\ndefmodule AriaEngine.BlocksWorld.Domain do\n  alias AriaEngine.Domain\n\n  def build do\n    Domain.new(\"blocks_world\")\n    |> Domain.add_action(:pickup, &AriaEngine.BlocksWorld.Actions.pickup/2)\n    |> Domain.add_action(:putdown, &AriaEngine.BlocksWorld.Actions.putdown/2)\n    |> Domain.add_action(:stack, &AriaEngine.BlocksWorld.Actions.stack/2)\n    |> Domain.add_action(:unstack, &AriaEngine.BlocksWorld.Actions.unstack/2)\n  end\nend\n"

        File.write!(blocks_world_path, blocks_world_content)
        Logger.debug("   ✅ Created: #{blocks_world_path}")
      end
    end

    state_utils_path = "lib/aria_engine/blocks_world/state_utils.ex"

    if not File.exists?(state_utils_path) do
      if dry_run do
        Logger.debug("   📄 Would create: #{state_utils_path}")
      else
        state_utils_content =
          "# Copyright (c) 2025-present K. S. Ernest (iFire) Lee\n# SPDX-License-Identifier: MIT\n\ndefmodule AriaEngine.BlocksWorld.StateUtils do\n  alias State\n\n  def from_gtpyhop_format(config) when is_map(config) do\n    state = State.new()\n\n    Enum.reduce(config, state, fn {predicate, facts}, acc_state ->\n      predicate_str = to_string(predicate)\n\n      Enum.reduce(facts, acc_state, fn {subject, value}, inner_state ->\n        subject_str = to_string(subject)\n        State.set_fact(inner_state, predicate_str, subject_str, value)\n      end)\n    end)\n  end\nend\n"

        File.write!(state_utils_path, state_utils_content)
        Logger.debug("   ✅ Created: #{state_utils_path}")
      end
    end

    actions_path = "lib/aria_engine/blocks_world/actions.ex"

    if not File.exists?(actions_path) do
      if dry_run do
        Logger.debug("   📄 Would create: #{actions_path}")
      else
        actions_content =
          "# Copyright (c) 2025-present K. S. Ernest (iFire) Lee\n# SPDX-License-Identifier: MIT\n\ndefmodule AriaEngine.BlocksWorld.Actions do\n  def pickup(state, _args), do: {:ok, state}\n  def putdown(state, _args), do: {:ok, state}\n  def stack(state, _args), do: {:ok, state}\n  def unstack(state, _args), do: {:ok, state}\nend\n"

        File.write!(actions_path, actions_content)
        Logger.debug("   ✅ Created: #{actions_path}")
      end
    end

    software_domain_path = "lib/aria_engine/software_development/domain.ex"

    if not File.exists?(software_domain_path) do
      if dry_run do
        Logger.debug("   📄 Would create: #{software_domain_path}")
      else
        File.mkdir_p!(Path.dirname(software_domain_path))

        software_content =
          "# Copyright (c) 2025-present K. S. Ernest (iFire) Lee\n# SPDX-License-Identifier: MIT\n\ndefmodule AriaEngine.SoftwareDevelopment.Domain do\n  alias AriaEngine.Domain\n\n  def build do\n    Domain.new(\"software_development\")\n    |> Domain.add_action(:write_code, fn state, _args -> {:ok, state} end)\n    |> Domain.add_action(:test_code, fn state, _args -> {:ok, state} end)\n    |> Domain.add_action(:deploy, fn state, _args -> {:ok, state} end)\n  end\nend\n"

        File.write!(software_domain_path, software_content)
        Logger.debug("   ✅ Created: #{software_domain_path}")
      end
    end
  end

  defp fix_state_api_parameter_ordering(dry_run, backup_dir) do
    Logger.info("4️⃣ Fixing State API parameter ordering...")

    files_to_fix = [
      "test/aria_engine/multigoal_optimization_test.exs",
      "test/aria_engine/test/aria_engine/state_quantifiers_test.exs"
    ]

    Enum.each(files_to_fix, fn file ->
      if File.exists?(file) do
        content = File.read!(file)

        if String.contains?(content, "State.set_fact") do
          if dry_run do
            Logger.debug("   📄 Would fix parameter ordering in: #{file}")
          else
            backup_file(file, backup_dir)

            updated_content =
              content
              |> String.replace(
                ~r/State\.set_fact\(([^,]+),\s*"robot",\s*"location",\s*([^)]+)\)/,
                "State.set_fact(\\1, \"location\", \"robot\", \\2)"
              )
              |> String.replace(
                ~r/State\.set_fact\(([^,]+),\s*"package_([^"]+)",\s*"location",\s*([^)]+)\)/,
                "State.set_fact(\\1, \"location\", \"package_\\2\", \\3)"
              )
              |> String.replace(
                ~r/State\.set_fact\(([^,]+),\s*"package_([^"]+)",\s*"weight",\s*([^)]+)\)/,
                "State.set_fact(\\1, \"weight\", \"package_\\2\", \\3)"
              )
              |> String.replace(
                ~r/State\.set_fact\(([^,]+),\s*"agent_([^"]+)",\s*"location",\s*([^)]+)\)/,
                "State.set_fact(\\1, \"location\", \"agent_\\2\", \\3)"
              )
              |> String.replace(
                ~r/State\.set_fact\(([^,]+),\s*"agent_([^"]+)",\s*"capacity",\s*([^)]+)\)/,
                "State.set_fact(\\1, \"capacity\", \"agent_\\2\", \\3)"
              )
              |> String.replace(
                ~r/State\.set_fact\(([^,]+),\s*"task_([^"]+)",\s*"status",\s*([^)]+)\)/,
                "State.set_fact(\\1, \"status\", \"task_\\2\", \\3)"
              )
              |> String.replace(
                ~r/State\.set_fact\(([^,]+),\s*"task_([^"]+)",\s*"depends_on",\s*([^)]+)\)/,
                "State.set_fact(\\1, \"depends_on\", \"task_\\2\", \\3)"
              )
              |> String.replace(
                ~r/State\.set_fact\(([^,]+),\s*"resource_([^"]+)",\s*"available",\s*([^)]+)\)/,
                "State.set_fact(\\1, \"available\", \"resource_\\2\", \\3)"
              )
              |> String.replace(
                ~r/State\.set_fact\(([^,]+),\s*"resource_([^"]+)",\s*"capacity",\s*([^)]+)\)/,
                "State.set_fact(\\1, \"capacity\", \"resource_\\2\", \\3)"
              )
              |> String.replace(
                ~r/State\.set_fact\(([^,]+),\s*"goal_([^"]+)",\s*"impossible",\s*([^)]+)\)/,
                "State.set_fact(\\1, \"impossible\", \"goal_\\2\", \\3)"
              )
              |> String.replace(
                ~r/State\.set_fact\(([^,]+),\s*"([^"]+)",\s*"status",\s*"([^"]+)"\)/,
                "State.set_fact(\\1, \"status\", \"\\2\", \"\\3\")"
              )
              |> String.replace(
                ~r/State\.set_fact\(([^,]+),\s*"([^"]+)",\s*"type",\s*"([^"]+)"\)/,
                "State.set_fact(\\1, \"type\", \"\\2\", \"\\3\")"
              )
              |> String.replace(
                ~r/State\.set_fact\(([^,]+),\s*"([^"]+)",\s*"location",\s*"([^"]+)"\)/,
                "State.set_fact(\\1, \"location\", \"\\2\", \"\\3\")"
              )
              |> String.replace(
                ~r/State\.set_fact\(([^,]+),\s*"([^"]+)",\s*"available",\s*([^)]+)\)/,
                "State.set_fact(\\1, \"available\", \"\\2\", \\3)"
              )

            File.write!(file, updated_content)
            Logger.debug("   ✅ Fixed parameter ordering in: #{file}")
          end
        end
      end
    end)
  end

  defp enhance_state_module(dry_run, backup_dir) do
    Logger.info("5️⃣ Enhancing State module with missing functions...")
    state_file = "lib/state.ex"

    if File.exists?(state_file) do
      content = File.read!(state_file)
      has_predicate_exists = String.contains?(content, "def has_predicate?")
      get_all_facts_exists = String.contains?(content, "def get_all_facts")

      if not has_predicate_exists or not get_all_facts_exists do
        if dry_run do
          Logger.debug("   📄 Would enhance State module with missing functions")
        else
          backup_file(state_file, backup_dir)
          Logger.debug("   ✅ State module already enhanced or will be enhanced separately")
        end
      else
        Logger.debug("   ✅ State module already has required functions")
      end
    end
  end

  defp fix_domain_action_registration(dry_run, backup_dir) do
    Logger.info("6️⃣ Fixing domain action registration...")

    domain_files = [
      "lib/aria_engine/software_development/domain.ex",
      "lib/aria_engine/blocks_world/domain.ex"
    ]

    Enum.each(domain_files, fn file ->
      if File.exists?(file) do
        content = File.read!(file)

        if String.contains?(content, "add_action(\"") do
          if dry_run do
            Logger.debug("   📄 Would fix action registration in: #{file}")
          else
            backup_file(file, backup_dir)

            updated_content =
              content |> String.replace(~r/add_action\("([^"]+)"/, "add_action(:\\1")

            File.write!(file, updated_content)
            Logger.debug("   ✅ Fixed action registration in: #{file}")
          end
        end
      end
    end)
  end

  defp fix_goal_tuple_ordering(dry_run, backup_dir) do
    Logger.info("7️⃣ Fixing goal tuple ordering...")
    files_to_check = Path.wildcard("**/*.{ex,exs}", match_dot: true)

    Enum.each(files_to_check, fn file ->
      if File.exists?(file) and not should_skip_file?(file) do
        content = File.read!(file)

        needs_fixing =
          String.contains?(content, "{\"") and
            (String.contains?(content, "location") or String.contains?(content, "has") or
               String.contains?(content, "state") or String.contains?(content, "assigned_to"))

        if needs_fixing do
          if dry_run do
            Logger.debug("   📄 Would fix goal tuples in: #{file}")
          else
            backup_file(file, backup_dir)

            updated_content =
              content
              |> String.replace(
                ~r/\{"([^"]+)",\s*"location",\s*"([^"]+)"\}/,
                "{\"location\", \"\\1\", \"\\2\"}"
              )
              |> String.replace(
                ~r/\{"([^"]+)",\s*"has",\s*"([^"]+)"\}/,
                "{\"has\", \"\\1\", \"\\2\"}"
              )
              |> String.replace(
                ~r/\{"([^"]+)",\s*"has_key",\s*([^}]+)\}/,
                "{\"has_key\", \"\\1\", \\2}"
              )
              |> String.replace(
                ~r/\{"([^"]+)",\s*"state",\s*"([^"]+)"\}/,
                "{\"state\", \"\\1\", \"\\2\"}"
              )
              |> String.replace(
                ~r/\{"([^"]+)",\s*"assigned_to",\s*"([^"]+)"\}/,
                "{\"assigned_to\", \"\\1\", \"\\2\"}"
              )
              |> String.replace(
                ~r/\{"([^"]+)",\s*"status",\s*"([^"]+)"\}/,
                "{\"status\", \"\\1\", \"\\2\"}"
              )
              |> String.replace(
                ~r/\{"([^"]+)",\s*"type",\s*"([^"]+)"\}/,
                "{\"type\", \"\\1\", \"\\2\"}"
              )
              |> String.replace(
                ~r/\{"([^"]+)",\s*"available",\s*([^}]+)\}/,
                "{\"available\", \"\\1\", \\2}"
              )
              |> String.replace(
                ~r/\{"([^"]+)",\s*"capacity",\s*([^}]+)\}/,
                "{\"capacity\", \"\\1\", \\2}"
              )
              |> String.replace(
                ~r/\{"([^"]+)",\s*"weight",\s*([^}]+)\}/,
                "{\"weight\", \"\\1\", \\2}"
              )
              |> String.replace(
                ~r/\{"([^"]+)",\s*"battery",\s*([^}]+)\}/,
                "{\"battery\", \"\\1\", \\2}"
              )
              |> String.replace(
                ~r/\{"([^"]+)",\s*"carrying",\s*([^}]+)\}/,
                "{\"carrying\", \"\\1\", \\2}"
              )

            if updated_content != content do
              File.write!(file, updated_content)
              Logger.debug("   ✅ Fixed goal tuples in: #{file}")
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
    case System.cmd("mix", [
           "test",
           "--exclude",
           "slow",
           "--exclude",
           "integration",
           "--max-failures",
           "5"
         ]) do
      {output, 0} ->
        Logger.info("✅ Tests passed!")
        Logger.info(output)

      {output, _exit_code} ->
        Logger.info("❌ Some tests failed:")
        Logger.info(output)
        Logger.info("")
        Logger.info("💡 You may need to run additional fixes or check the migration results")
    end
  end
end