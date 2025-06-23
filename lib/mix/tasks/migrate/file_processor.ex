# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.Migrate.FileProcessor do
  @moduledoc """
  Handles file operations for migrations.

  Single responsibility: Manage file discovery, backup creation, and file I/O
  operations without any transformation logic.
  """

  require Logger

  @doc """
  Discover all Elixir files eligible for migration.
  """
  @spec discover_elixir_files() :: [String.t()]
  def discover_elixir_files do
    Path.wildcard("**/*.{ex,exs}", match_dot: true)
    |> Enum.filter(&File.exists?/1)
    |> Enum.filter(&should_process_file?/1)
  end

  @doc """
  Determine if a file should be processed during migration.
  """
  @spec should_process_file?(String.t()) :: boolean()
  def should_process_file?(file) do
    not should_skip_file?(file)
  end

  @doc """
  Create backup directory if it doesn't exist.
  """
  @spec create_backup_dir(String.t()) :: :ok
  def create_backup_dir(backup_dir) do
    if not File.exists?(backup_dir) do
      File.mkdir_p!(backup_dir)
      Logger.info("📁 Created backup directory: #{backup_dir}")
    end

    :ok
  end

  @doc """
  Create a backup of a file before modification.
  """
  @spec backup_file(String.t(), String.t()) :: :ok
  def backup_file(file, backup_dir) do
    backup_path = Path.join(backup_dir, file)
    backup_dir_path = Path.dirname(backup_path)

    File.mkdir_p!(backup_dir_path)
    File.cp!(file, backup_path)

    :ok
  end

  @doc """
  Read file content safely.
  """
  @spec read_file(String.t()) :: {:ok, String.t()} | {:error, term()}
  def read_file(file_path) do
    File.read(file_path)
  end

  @doc """
  Write content to file safely.
  """
  @spec write_file(String.t(), String.t()) :: :ok | {:error, term()}
  def write_file(file_path, content) do
    File.write(file_path, content)
  end

  # Private functions

  defp should_skip_file?(file) do
    # Skip migration-related files
    String.contains?(file, "migrate") or
      String.contains?(file, "migration") or
      String.contains?(file, ".migration_backup") or
      String.contains?(file, "statev2_fixer") or
      String.ends_with?(file, "_fixer.exs") or
      String.ends_with?(file, "_migration.exs") or
      # Skip build and dependency directories
      String.contains?(file, "_build/") or
      String.starts_with?(file, "deps/") or
      String.contains?(file, ".elixir_ls/") or
      # Skip template and third-party directories
      String.contains?(file, "priv/templates/") or
      String.contains?(file, "thirdparty/") or
      # Skip backup files
      String.ends_with?(file, ".bak") or
      String.ends_with?(file, ".backup") or
      # Skip disabled files
      String.ends_with?(file, ".disabled")
  end
end
