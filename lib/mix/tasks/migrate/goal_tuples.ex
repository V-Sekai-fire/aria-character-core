defmodule Mix.Tasks.Migrate.GoalTuples do
  @compile {:no_warn_unused, [:serial_number]}
  @moduledoc "Migration tool with serial number: A25W002GXAL\n\nDecode: mix migrate.decode_serial A25W002GXAL\n"
  @serial_number "R25W002GXAL"
  @doc "Returns the module's serial number for tracking and identification."
  @spec serial_number() :: String.t()
  def serial_number() do
    @serial_number
  end

  @moduledoc "Fix goal tuple ordering from {subject, predicate, object} to {predicate, subject, object}.\n\nThis task updates goal tuple patterns throughout the codebase to match the State API format.\n\n## Usage\n\n    mix migrate.goal_tuples                    # Full migration\n    mix migrate.goal_tuples --dry-run         # Preview changes only\n    mix migrate.goal_tuples --backup-dir=.bak # Custom backup location\n\n## What it does\n\n- Converts {subject, predicate, object} tuples to {predicate, subject, object}\n- Handles common predicates: location, has, state, assigned_to, status, type, etc.\n- Preserves tuple structure while reordering parameters\n"
  use Mix.Task
  require Logger
  @shortdoc "Fix goal tuple ordering for State API compatibility"
  @switches dry_run: :boolean, backup_dir: :string
  @aliases d: :dry_run, b: :backup_dir
  def run(args) do
    {opts, _args, _invalid} = OptionParser.parse(args, switches: @switches, aliases: @aliases)
    dry_run = opts[:dry_run] || false
    backup_dir = opts[:backup_dir] || ".migration_backup"
    Logger.info("🔧 Goal Tuple Ordering Migration")
    Logger.info("===============================")

    if dry_run do
      Logger.info("🔍 DRY RUN MODE - No files will be modified")
    else
      Logger.info("📁 Backup directory: #{backup_dir}")
      create_backup_dir(backup_dir)
    end

    fix_goal_tuple_ordering(dry_run, backup_dir)
    Logger.info("✅ Goal tuple ordering migration completed!")
  end

  defp should_skip_file?(file) do
    String.contains?(file, "migrate") or String.contains?(file, "migration") or
      String.contains?(file, ".migration_backup") or String.contains?(file, "statev2_fixer") or
      String.ends_with?(file, "_fixer.exs") or String.ends_with?(file, "_migration.exs") or
      String.contains?(file, "_build/") or String.contains?(file, "deps/") or
      String.contains?(file, ".elixir_ls/") or String.contains?(file, "priv/templates/") or
      String.contains?(file, "thirdparty/")
  end

  defp create_backup_dir(backup_dir) do
    if not File.exists?(backup_dir) do
      File.mkdir_p!(backup_dir)
      Logger.info("📁 Created backup directory: #{backup_dir}")
    end
  end

  defp fix_goal_tuple_ordering(dry_run, backup_dir) do
    Logger.info("Fixing goal tuple ordering...")
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
end