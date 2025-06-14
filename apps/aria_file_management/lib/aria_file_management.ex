# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaFileManagement.Domain do
  @moduledoc """
  Prepackaged file management domain for AriaEngine.
  """
  alias AriaEngine.{Domain, State}

  @spec domain() :: Domain.t()
  def domain do
    Domain.new("file_management")
    |> Domain.add_actions(%{
      copy_file: &copy_file/2,
      move_file: &move_file/2,
      delete_file: &delete_file/2,
      create_directory: &create_directory/2,
      list_directory: &list_directory/2,
      file_exists: &file_exists/2,
      download_file: &download_file/2,
      create_archive: &create_archive/2,
      extract_archive: &extract_archive/2,
      execute_command: &execute_command/2
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
    |> Domain.add_task_methods("backup_file", [
      &backup_file/2
    ])
    |> Domain.add_task_methods("setup_workspace", [
      &setup_workspace/2
    ])
    |> Domain.add_task_methods("create_directory_structure", [
      &create_directory_structure/2
    ])
    |> Domain.add_task_methods("replace_file_safely", [
      &replace_file_safely/2
    ])
    |> Domain.add_task_methods("download_and_verify", [
      &download_and_verify/2
    ])
    |> Domain.add_task_methods("cleanup_temp_files", [
      &cleanup_temp_files/2
    ])
    |> Domain.add_task_methods("compress_directory", [
      &compress_directory/2
    ])
    |> Domain.add_task_methods("sync_directories", [
      &sync_directories/2
    ])
    |> Domain.add_unigoal_method("file_exists", &ensure_file_exists/2)
    |> Domain.add_unigoal_method("directory_exists", &ensure_directory_exists/2)
  end

  # Placeholder action implementations - these would need to be implemented with actual file operations
  @spec copy_file(State.t(), list()) :: State.t() | false
  def copy_file(_state, [_source, _destination]), do: false
  def copy_file(_state, [_source, _destination, _opts]), do: false

  @spec move_file(State.t(), list()) :: State.t() | false
  def move_file(_state, [_source, _destination]), do: false

  @spec delete_file(State.t(), list()) :: State.t() | false
  def delete_file(_state, [_file_path]), do: false

  @spec create_directory(State.t(), list()) :: State.t() | false
  def create_directory(_state, [_dir_path]), do: false
  def create_directory(_state, [_dir_path, _opts]), do: false

  @spec list_directory(State.t(), list()) :: State.t() | false
  def list_directory(_state, [_dir_path]), do: false

  @spec file_exists(State.t(), list()) :: State.t() | false
  def file_exists(_state, [_file_path]), do: false

  @spec download_file(State.t(), list()) :: State.t() | false
  def download_file(_state, [_url, _destination]), do: false

  @spec create_archive(State.t(), list()) :: State.t() | false
  def create_archive(_state, [_archive_path, _source]), do: false

  @spec execute_command(State.t(), list()) :: State.t() | false
  def execute_command(state, [_command | _args]) do
    # Simulate successful command execution
    AriaEngine.State.set_object(state, "last_command", "success", true)
  end

  # Task methods that decompose complex file operations

  @doc """
  Backup files using local copy operations.
  """
  @spec backup_files_local(State.t(), [String.t()]) :: [tuple()] | false
  def backup_files_local(_state, [_source_dir, _backup_dir]) do
    [
      {:create_directory, ["backup_dir"]},
      {:execute_command, ["cp", "-r", "source", "backup"]}
    ]
  end

  @doc """
  Backup files by creating an archive.
  """
  @spec backup_files_archive(State.t(), [String.t()]) :: [tuple()] | false
  def backup_files_archive(_state, [_source_dir, _archive_path]) do
    [
      {:create_archive, ["archive_path", "source_dir"]}
    ]
  end

  @doc """
  Sync directory using rsync command.
  """
  @spec sync_directory_rsync(State.t(), [String.t()]) :: [tuple()]
  def sync_directory_rsync(_state, [source, destination]) do
    [
      {:execute_command, ["which", "rsync"]},
      {:execute_command, ["rsync", "-av", source, destination]}
    ]
  end

  @doc """
  Sync directory using basic copy commands.
  """
  @spec sync_directory_basic(State.t(), [String.t()]) :: [tuple()]
  def sync_directory_basic(_state, [source, destination]) do
    [
      {:create_directory, [destination]},
      {:execute_command, ["cp", "-r", source, destination]}
    ]
  end

  @doc """
  Cleanup directory by removing old files.
  """
  @spec cleanup_by_age(State.t(), [String.t() | integer()]) :: [tuple()]
  def cleanup_by_age(_state, [directory, days]) do
    [
      {:execute_command, ["find", directory, "-type", "f", "-mtime", "+#{days}", "-delete"]}
    ]
  end

  @doc """
  Cleanup directory by removing files matching a pattern.
  """
  @spec cleanup_by_pattern(State.t(), [String.t()]) :: [tuple()]
  def cleanup_by_pattern(_state, [directory, pattern]) do
    [
      {:execute_command, ["find", directory, "-name", pattern, "-delete"]}
    ]
  end

  # Unigoal methods for achieving specific file system states

  @doc """
  Ensure a file exists (create if missing).
  """
  @spec ensure_file_exists(State.t(), [String.t()]) :: [tuple()] | false
  def ensure_file_exists(_state, [_subject, object]) do
    if object == true do
      [
        {:execute_command, ["touch", "subject"]}
      ]
    else
      false
    end
  end

  @doc """
  Ensure a directory exists (create if missing).
  """
  @spec ensure_directory_exists(State.t(), [String.t()]) :: [tuple()] | false
  def ensure_directory_exists(_state, [_subject, object]) do
    if object == true do
      [
        {:create_directory, ["subject"]}
      ]
    else
      false
    end
  end

  # Task methods for file operations

  @doc """
  Backup a single file to a specified location.
  """
  @spec backup_file(State.t(), [String.t()]) :: [tuple()]
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
  @spec replace_file_safely(State.t(), [String.t()]) :: [tuple()]
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
  @spec create_directory_structure(State.t(), [String.t()]) :: [tuple()]
  def create_directory_structure(_state, [path]) do
    [
      {:create_directory, [path]},
      {:echo, ["Created directory structure: #{path}"]}
    ]
  end

  @spec create_directory_structure(State.t(), {String.t(), [String.t()]}) :: [tuple()]
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
  @spec download_and_verify(State.t(), [String.t()]) :: [tuple()]
  def download_and_verify(_state, [url, destination]) do
    [
      {:execute_command, ["curl", "-o", destination, url]},
      {:echo, ["Downloaded #{url} to #{destination}"]}
    ]
  end

  @doc """
  Set up a workspace directory with common subdirectories.
  """
  @spec setup_workspace(State.t(), [String.t()]) :: [tuple()]
  def setup_workspace(_state, [workspace_path]) do
    [
      {:create_directory, [workspace_path]},
      {:create_directory, [Path.join(workspace_path, "src")]},
      {:create_directory, [Path.join(workspace_path, "docs")]},
      {:create_directory, [Path.join(workspace_path, "tests")]},
      {:echo, ["Workspace setup complete at #{workspace_path}"]}
    ]
  end

  @spec setup_workspace(State.t(), {String.t(), String.t()}) :: [tuple()]
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
  @spec cleanup_temp_files(State.t(), [String.t()]) :: [tuple()]
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
  @spec compress_directory(State.t(), [String.t()]) :: [tuple()]
  def compress_directory(_state, [directory, archive_path]) do
    [
      {:execute_command, ["tar", "-czf", archive_path, "-C", Path.dirname(directory), Path.basename(directory)]},
      {:echo, ["Compressed #{directory} to #{archive_path}"]}
    ]
  end

  @doc """
  Extract an archive to a directory.
  """
  @spec extract_archive(State.t(), [String.t()]) :: [tuple()]
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
  @spec sync_directories(State.t(), [String.t()]) :: [tuple()]
  def sync_directories(_state, [source, destination]) do
    [
      {:create_directory, [destination]},
      {:execute_command, ["rsync", "-av", source, destination]}
    ]
  end
end

# Main module just references the prepackaged domain

defmodule AriaFileManagement do
  @moduledoc """
  File management domain for AriaEngine with Porcelain-based external process actions.
  """

  def domain, do: AriaFileManagement.Domain.domain()

  # Delegate all public API functions to the Domain submodule for compatibility
  defdelegate create_domain(), to: AriaFileManagement.Domain, as: :domain
  defdelegate copy_file(state, args), to: AriaFileManagement.Domain
  defdelegate move_file(state, args), to: AriaFileManagement.Domain
  defdelegate delete_file(state, args), to: AriaFileManagement.Domain
  defdelegate create_directory(state, args), to: AriaFileManagement.Domain
  defdelegate list_directory(state, args), to: AriaFileManagement.Domain
  defdelegate file_exists(state, args), to: AriaFileManagement.Domain
  defdelegate download_file(state, args), to: AriaFileManagement.Domain
  defdelegate create_archive(state, args), to: AriaFileManagement.Domain
  defdelegate extract_archive(state, args), to: AriaFileManagement.Domain
  defdelegate execute_command(state, args), to: AriaFileManagement.Domain
  defdelegate backup_files_local(state, args), to: AriaFileManagement.Domain
  defdelegate backup_files_archive(state, args), to: AriaFileManagement.Domain
  defdelegate sync_directory_rsync(state, args), to: AriaFileManagement.Domain
  defdelegate sync_directory_basic(state, args), to: AriaFileManagement.Domain
  defdelegate cleanup_by_age(state, args), to: AriaFileManagement.Domain
  defdelegate cleanup_by_pattern(state, args), to: AriaFileManagement.Domain
  defdelegate ensure_file_exists(state, args), to: AriaFileManagement.Domain
  defdelegate ensure_directory_exists(state, args), to: AriaFileManagement.Domain
  defdelegate backup_file(state, args), to: AriaFileManagement.Domain
  defdelegate replace_file_safely(state, args), to: AriaFileManagement.Domain
  defdelegate create_directory_structure(state, args), to: AriaFileManagement.Domain
  defdelegate download_and_verify(state, args), to: AriaFileManagement.Domain
  defdelegate setup_workspace(state, args), to: AriaFileManagement.Domain
  defdelegate cleanup_temp_files(state, args), to: AriaFileManagement.Domain
  defdelegate compress_directory(state, args), to: AriaFileManagement.Domain
  defdelegate sync_directories(state, args), to: AriaFileManagement.Domain
end
