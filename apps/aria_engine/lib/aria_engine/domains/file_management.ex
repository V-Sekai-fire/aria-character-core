# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Domains.FileManagement do
  @moduledoc """
  File management domain for AriaEngine with Porcelain-based external process actions.

  This domain provides file and directory operations using external system commands
  through Porcelain, allowing for robust file system interactions.
  """

  alias AriaEngine.{Domain, Actions, State}

  @doc """
  Creates a file management domain with Porcelain-based actions.
  """
  def create_domain do
    Domain.new("file_management")
    |> Domain.add_actions(%{
      copy_file: &Actions.copy_file/2,
      move_file: &Actions.move_file/2,
      delete_file: &Actions.delete_file/2,
      create_directory: &Actions.create_directory/2,
      list_directory: &Actions.list_directory/2,
      file_exists: &Actions.file_exists/2,
      download_file: &Actions.download_file/2,
      create_archive: &Actions.create_archive/2,
      extract_archive: &Actions.extract_archive/2,
      execute_command: &Actions.execute_command/2
    })
    |> Domain.add_task_methods("backup_files", [
      &backup_files_local/2,
      &backup_files_archive/2
    ])
    |> Domain.add_task_methods("sync_directory", [
      &sync_directory_rsync/2,
      &sync_directory_basic/2
    ])
    |> Domain.add_task_methods("cleanup_directory", [
      &cleanup_by_age/2,
      &cleanup_by_pattern/2
    ])
    |> Domain.add_unigoal_method("file_exists", &ensure_file_exists/2)
    |> Domain.add_unigoal_method("directory_exists", &ensure_directory_exists/2)
  end

  # Task methods that decompose complex file operations

  @doc """
  Backup files using local copy operations.
  """
  def backup_files_local(state, [source_dir, backup_dir]) do
    if State.get_object(state, "directory_exists", source_dir) do
      [
        {:create_directory, [backup_dir]},
        {:execute_command, ["cp", "-r", source_dir, backup_dir]}
      ]
    else
      false
    end
  end

  @doc """
  Backup files by creating an archive.
  """
  def backup_files_archive(state, [source_dir, archive_path]) do
    if State.get_object(state, "directory_exists", source_dir) do
      [
        {:create_archive, [archive_path, source_dir]}
      ]
    else
      false
    end
  end

  @doc """
  Sync directory using rsync command.
  """
  def sync_directory_rsync(_state, [source, destination]) do
    # Check if rsync is available
    [
      {:execute_command, ["which", "rsync"]},
      {:execute_command, ["rsync", "-av", source, destination]}
    ]
  end

  @doc """
  Sync directory using basic copy commands.
  """
  def sync_directory_basic(_state, [source, destination]) do
    [
      {:create_directory, [destination]},
      {:execute_command, ["cp", "-r", source, destination]}
    ]
  end

  @doc """
  Cleanup directory by removing old files.
  """
  def cleanup_by_age(_state, [directory, days]) do
    [
      {:execute_command, ["find", directory, "-type", "f", "-mtime", "+#{days}", "-delete"]}
    ]
  end

  @doc """
  Cleanup directory by removing files matching a pattern.
  """
  def cleanup_by_pattern(_state, [directory, pattern]) do
    [
      {:execute_command, ["find", directory, "-name", pattern, "-delete"]}
    ]
  end

  # Unigoal methods for achieving specific file system states

  @doc """
  Ensure a file exists (create if missing).
  """
  def ensure_file_exists(state, [subject, object]) do
    if object == true do
      case State.get_object(state, "file_exists", subject) do
        true -> []  # File already exists
        _ -> [
          {:execute_command, ["touch", subject]}
        ]
      end
    else
      false
    end
  end

  @doc """
  Ensure a directory exists (create if missing).
  """
  def ensure_directory_exists(state, [subject, object]) do
    if object == true do
      case State.get_object(state, "directory_exists", subject) do
        true -> []  # Directory already exists
        _ -> [
          {:create_directory, [subject]}
        ]
      end
    else
      false
    end
  end

  # Task methods for file operations

  @doc """
  Backup a single file to a specified location.
  """
  def backup_file(_state, [source, destination]) do
    [
      {:copy_file, [source, destination]},
      {:echo, ["Backed up #{source} to #{destination}"]}
    ]
  end

  def backup_file(_state, [source]) do
    # Generate backup destination with timestamp
    timestamp = DateTime.utc_now() |> DateTime.to_iso8601(:basic)
    backup_name = "#{source}.backup.#{timestamp}"
    [
      {:copy_file, [source, backup_name, %{force: false}]}
    ]
  end

  @doc """
  Replace a file safely by creating a backup first.
  """
  def replace_file_safely(_state, [source, destination]) do
    backup_dest = source <> ".backup"
    [
      {:copy_file, [source, backup_dest]},
      {:copy_file, [destination, source]},
      {:echo, ["Safely replaced #{source} (backup at #{backup_dest})"]}
    ]
  end

  @doc """
  Create a directory structure recursively.
  """
  def create_directory_structure(_state, [path]) do
    [
      {:create_directory, [path]},
      {:echo, ["Created directory structure: #{path}"]}
    ]
  end

  def create_directory_structure(_state, [base_path, subdirs]) when is_list(subdirs) do
    base_action = {:create_directory, [base_path, %{parents: true}]}

    create_actions = Enum.map(subdirs, fn subdir ->
      full_path = Path.join(base_path, subdir)
      {:create_directory, [full_path, %{parents: true}]}
    end)

    [base_action | create_actions]
  end

  @doc """
  Download and verify a file (placeholder implementation).
  """
  def download_and_verify(_state, [url, destination]) do
    [
      {:execute_command, ["curl", "-o", destination, url]},
      {:echo, ["Downloaded #{url} to #{destination}"]}
    ]
  end

  @doc """
  Set up a workspace directory with common subdirectories.
  """
  def setup_workspace(_state, [workspace_path]) do
    [
      {:create_directory, [workspace_path]},
      {:create_directory, [Path.join(workspace_path, "src")]},
      {:create_directory, [Path.join(workspace_path, "docs")]},
      {:create_directory, [Path.join(workspace_path, "tests")]},
      {:echo, ["Workspace setup complete at #{workspace_path}"]}
    ]
  end

  def setup_workspace(_state, [workspace_path, project_name]) do
    full_path = Path.join(workspace_path, project_name)
    [
      {:create_directory, [full_path, %{parents: true}]},
      {:create_directory, [Path.join(full_path, "src"), %{parents: true}]},
      {:create_directory, [Path.join(full_path, "test"), %{parents: true}]},
      {:create_directory, [Path.join(full_path, "docs"), %{parents: true}]},
      {:create_directory, [Path.join(full_path, "config"), %{parents: true}]},
      {:execute_command, ["touch", [Path.join(full_path, "README.md")], %{}]}
    ]
  end

  @doc """
  Clean up temporary files in a directory.
  """
  def cleanup_temp_files(_state, [directory]) do
    [
      {:execute_command, ["find", directory, "-name", "*.tmp", "-delete"]},
      {:execute_command, ["find", directory, "-name", ".DS_Store", "-delete"]},
      {:echo, ["Cleaned up temporary files in #{directory}"]}
    ]
  end

  @doc """
  Compress a directory into an archive.
  """
  def compress_directory(_state, [directory, archive_path]) do
    [
      {:execute_command, ["tar", "-czf", archive_path, "-C", Path.dirname(directory), Path.basename(directory)]},
      {:echo, ["Compressed #{directory} to #{archive_path}"]}
    ]
  end

  @doc """
  Extract an archive to a directory.
  """
  def extract_archive(_state, [archive_path, destination]) do
    [
      {:create_directory, [destination]},
      {:execute_command, ["tar", "-xzf", archive_path, "-C", destination]},
      {:echo, ["Extracted #{archive_path} to #{destination}"]}
    ]
  end

  @doc """
  Sync directories (wrapper for the sync methods).
  """
  def sync_directories(_state, [source, destination]) do
    [
      {:create_directory, [destination]},
      {:execute_command, ["rsync", "-av", source, destination]}
    ]
  end
end
