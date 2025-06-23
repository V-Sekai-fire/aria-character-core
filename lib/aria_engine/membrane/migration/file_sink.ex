# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Membrane.Migration.FileSink do
  @moduledoc """
  Membrane sink that writes transformed FileData structures back to files.

  This sink handles writing files to their original locations or backup locations
  based on the dry_run configuration.
  """

  use Membrane.Sink

  alias AriaEngine.Membrane.Migration.Format.FileData

  def_input_pad :input, accepted_format: FileData, flow_control: :auto

  def_options dry_run: [
                spec: boolean(),
                description: "Whether to perform a dry run (no actual file writes)",
                default: false
              ],
              backup_dir: [
                spec: String.t(),
                description: "Directory to store backup files",
                default: ".migration_backup"
              ]

  @impl true
  def handle_init(_ctx, options) do
    # Ensure backup directory exists if not in dry run mode
    unless options.dry_run do
      File.mkdir_p!(options.backup_dir)
    end

    state = %{
      dry_run: options.dry_run,
      backup_dir: options.backup_dir,
      files_written: 0,
      total_transformations: 0,
      total_files: 0
    }

    {[], state}
  end

  @impl true
  def handle_buffer(:input, %Membrane.Buffer{payload: file_data}, _ctx, state) do
    new_state = process_file(file_data, state)
    {[], new_state}
  end

  @impl true
  def handle_end_of_stream(:input, _ctx, state) do
    # Send completion notification with expected field names
    summary = %{
      total_files: state.total_files,
      changed_files: state.files_written,
      unchanged_files: state.total_files - state.files_written,
      skipped_files: 0,
      total_transformations: state.total_transformations,
      dry_run: state.dry_run
    }

    {[notify_parent: {:pipeline_complete, summary}], state}
  end

  # Private functions

  defp process_file(file_data, state) do
    updated_state = %{state | total_files: state.total_files + 1}

    if has_transformations?(file_data) do
      if state.dry_run do
        log_dry_run_changes(file_data)
      else
        write_file_with_backup(file_data, state.backup_dir)
      end

      %{updated_state |
        files_written: updated_state.files_written + 1,
        total_transformations: updated_state.total_transformations + length(file_data.transformations)
      }
    else
      # No changes, just update total files count
      updated_state
    end
  end

  defp has_transformations?(file_data) do
    length(file_data.transformations) > 0
  end

  defp log_dry_run_changes(file_data) do
    require Logger

    Logger.info("DRY RUN: Would modify #{file_data.file_path}")

    Enum.each(file_data.transformations, fn transformation ->
      Logger.info("  #{transformation.rule}: #{transformation.original} → #{transformation.replacement}")
    end)
  end

  defp write_file_with_backup(file_data, backup_dir) do
    # Create backup of original file
    backup_path = create_backup_path(file_data.file_path, backup_dir)
    backup_dir_path = Path.dirname(backup_path)
    File.mkdir_p!(backup_dir_path)

    case File.copy(file_data.file_path, backup_path) do
      {:ok, _} ->
        # Write the transformed content
        case File.write(file_data.file_path, file_data.content) do
          :ok ->
            require Logger
            Logger.info("✅ Updated #{file_data.file_path} (#{length(file_data.transformations)} changes)")

          {:error, reason} ->
            require Logger
            Logger.error("❌ Failed to write #{file_data.file_path}: #{reason}")
        end

      {:error, reason} ->
        require Logger
        Logger.error("❌ Failed to backup #{file_data.file_path}: #{reason}")
    end
  end

  defp create_backup_path(original_path, backup_dir) do
    # Create a backup path that preserves the directory structure
    relative_path = Path.relative_to_cwd(original_path)
    Path.join(backup_dir, relative_path)
  end
end
