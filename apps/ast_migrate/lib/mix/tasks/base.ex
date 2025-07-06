# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule Mix.Tasks.Migrate.Base do
  @moduledoc """
  Base module providing common migration functionality.

  Provides shared utilities for all migration tasks including:
  - CLI option parsing and help text
  - File discovery and filtering
  - Backup management
  - Dry-run handling
  - Logging utilities
  - AST transformation pipeline
  """

  require Logger

  @doc """
  Standard CLI switches used by all migration tasks.
  """
  def standard_switches do
    [
      dry_run: :boolean,
      backup_dir: :string,
      help: :boolean
    ]
  end

  @doc """
  Standard CLI aliases used by all migration tasks.
  """
  def standard_aliases do
    [
      d: :dry_run,
      b: :backup_dir,
      h: :help
    ]
  end

  @doc """
  Parse CLI arguments with standard options.
  """
  def parse_args(args) do
    OptionParser.parse(args, switches: standard_switches(), aliases: standard_aliases())
  end

  @doc """
  Determine if a file should be skipped during migration.
  """
  def should_skip_file?(file) do
    String.contains?(file, "migrate") or
      String.contains?(file, "migration") or
      String.contains?(file, ".migration_backup") or
      String.contains?(file, "statev2_fixer") or
      String.ends_with?(file, "_fixer.exs") or
      String.ends_with?(file, "_migration.exs") or
      String.contains?(file, "_build/") or
      String.starts_with?(file, "deps/") or
      String.contains?(file, ".elixir_ls/") or
      String.contains?(file, "priv/templates/") or
      String.contains?(file, "thirdparty/")
  end

  @doc """
  Create backup directory if it doesn't exist.
  """
  def create_backup_dir(backup_dir) do
    if not File.exists?(backup_dir) do
      File.mkdir_p!(backup_dir)
      Logger.info("📁 Created backup directory: #{backup_dir}")
    end
  end

  @doc """
  Create a backup of a file before modification.
  """
  def backup_file(file, backup_dir) do
    backup_path = Path.join(backup_dir, file)
    backup_dir_path = Path.dirname(backup_path)

    File.mkdir_p!(backup_dir_path)
    File.cp!(file, backup_path)
  end

  @doc """
  Discover Elixir files for migration.
  """
  def discover_elixir_files do
    Path.wildcard("**/*.{ex,exs}", match_dot: true)
    |> Enum.filter(&File.exists?/1)
    |> Enum.reject(&should_skip_file?/1)
  end

  @doc """
  Log migration start with standard format.
  """
  def log_migration_start(tool_name, dry_run, backup_dir) do
    Logger.info("🔧 #{tool_name}")
    Logger.info(String.duplicate("=", String.length(tool_name) + 2))

    if dry_run do
      Logger.info("🔍 DRY RUN MODE - No files will be modified")
    else
      Logger.info("📁 Backup directory: #{backup_dir}")
      create_backup_dir(backup_dir)
    end

    Logger.info("")
  end

  @doc """
  Log migration completion.
  """
  def log_migration_complete(tool_name, dry_run, backup_dir) do
    Logger.info("")
    Logger.info("✅ #{tool_name} completed!")

    if not dry_run do
      Logger.info("")
      Logger.info("💡 Backup files are in: #{backup_dir}")
    end
  end

  @doc """
  Process a single file with transformation function.
  """
  def process_file(file, transformation_fn, dry_run, backup_dir) do
    content = File.read!(file)

    case transformation_fn.(content) do
      {:changed, new_content} ->
        if dry_run do
          Logger.debug("   📄 Would modify: #{file}")
        else
          backup_file(file, backup_dir)
          File.write!(file, new_content)
          Logger.debug("   ✅ Modified: #{file}")
        end

        :changed

      :unchanged ->
        Logger.debug("   ✅ No changes needed: #{file}")
        :unchanged

      {:error, reason} ->
        Logger.warning("   ⚠️  Error processing #{file}: #{reason}")
        :error
    end
  end

  @doc """
  Process multiple files with a transformation function.
  """
  def process_files(files, transformation_fn, dry_run, backup_dir) do
    results =
      Enum.map(files, fn file ->
        {file, process_file(file, transformation_fn, dry_run, backup_dir)}
      end)

    changed_count = Enum.count(results, fn {_, result} -> result == :changed end)
    error_count = Enum.count(results, fn {_, result} -> result == :error end)

    Logger.info(
      "📊 Processed #{length(files)} files: #{changed_count} changed, #{error_count} errors"
    )

    results
  end
end
