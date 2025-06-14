# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaFileManagement.DomainProvider do
  @moduledoc """
  Domain provider for file management functionality.

  This implements the AriaEngine.DomainProvider behavior to provide
  file management capabilities in a clean, decoupled way.
  """

  @behaviour AriaEngine.DomainProvider

  alias AriaEngine.Domain

  @impl true
  def domain_type, do: "file_management"

  @impl true
  def available? do
    # Check if required system commands are available
    case System.find_executable("cp") do
      nil -> false
      _ -> true
    end
  end

  @impl true
  def create_domain do
    Domain.new("file_management")
    |> Domain.add_actions(%{
      copy_file: &AriaFileManagement.copy_file/2,
      move_file: &AriaFileManagement.move_file/2,
      delete_file: &AriaFileManagement.delete_file/2,
      create_directory: &AriaFileManagement.create_directory/2,
      list_directory: &AriaFileManagement.list_directory/2,
      file_exists: &AriaFileManagement.file_exists/2,
      download_file: &AriaFileManagement.download_file/2,
      create_archive: &AriaFileManagement.create_archive/2,
      extract_archive: &AriaFileManagement.extract_archive/2,
      execute_command: &AriaFileManagement.execute_command/2
    })
    |> Domain.add_task_methods("backup_files", [
      &AriaFileManagement.backup_files_local/2,
      &AriaFileManagement.backup_files_archive/2
    ])
    |> Domain.add_task_methods("sync_directory", [
      &AriaFileManagement.sync_directory_rsync/2,
      &AriaFileManagement.sync_directory_basic/2
    ])
    |> Domain.add_task_methods("cleanup_directory", [
      &AriaFileManagement.cleanup_by_age/2,
      &AriaFileManagement.cleanup_by_pattern/2
    ])
    |> Domain.add_unigoal_method("file_exists", &AriaFileManagement.ensure_file_exists/2)
    |> Domain.add_unigoal_method("directory_exists", &AriaFileManagement.ensure_directory_exists/2)
  end
end
