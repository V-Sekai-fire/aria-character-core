# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AstMigrate.Git do
  @moduledoc """
  Git operations using egit library for native Elixir Git integration.

  This module provides structured error handling and type safety for all
  Git operations used by the AST migration tool.
  """

  require Logger

  @type commit_hash :: String.t()
  @type branch_name :: String.t()
  @type file_path :: String.t()

  # Private functions first

  defp open_repository do
    case :git.open(".") do
      repo when is_reference(repo) -> {:ok, repo}
      {:error, reason} -> {:error, reason}
      error -> {:error, error}
    end
  end

  defp get_author do
    %{
      name: "AST Migration Tool",
      email: "ast-migrate@localhost"
    }
  end

  defp timestamp do
    DateTime.utc_now() |> DateTime.to_unix()
  end

  defp format_commit(commit) do
    %{
      hash: commit.hash,
      message: commit.message,
      author: commit.author,
      date: commit.date,
      files_changed: length(commit.files || [])
    }
  end

  # Public API

  @doc """
  Ensure the working tree is clean before applying transformations.
  """
  @spec ensure_clean_working_tree(String.t()) :: :ok | {:error, String.t()}
  def ensure_clean_working_tree(repo_path \\ ".") do
    with {:ok, repo} <- open_repository(),
         status when is_list(status) <- :git.status(repo) do
      case status do
        [] ->
          :ok
        [%{index: []}] ->
          :ok
        _ ->
          {:error, "Working tree not clean: #{inspect(status)}"}
      end
    else
      {:error, reason} ->
        {:error, "Failed to check Git status: #{inspect(reason)}"}
      error ->
        {:error, "Git status error: #{inspect(error)}"}
    end
  end

  @doc """
  Commit transformations with proper AST migration metadata.
  """
  @spec commit_transformations([file_path()], String.t()) :: {:ok, commit_hash()} | {:error, String.t()}
  def commit_transformations(files, message) do
    commit_transformations(".", message, files)
  end

  @doc """
  Commit transformations with proper AST migration metadata (3-arity version).
  """
  @spec commit_transformations(String.t(), String.t(), [file_path()]) :: {:ok, commit_hash()} | {:error, String.t()}
  def commit_transformations(repo_path, message, files) do
    Logger.debug("Starting Git commit for transformations",
      module: :ast_migrate_git,
      operation: :commit_transformations,
      files_count: length(files),
      commit_message: message
    )

    with {:ok, repo} <- open_repository(),
         %{mode: :added} <- :git.add(repo, files),
         {:ok, commit_hash} <- :git.commit(repo, "[AST] #{message}") do

      Logger.info("AST transformation committed successfully",
        module: :ast_migrate_git,
        operation: :commit_transformations,
        files_count: length(files),
        commit_hash: commit_hash,
        commit_message: "[AST] #{message}",
        files: files
      )

      {:ok, commit_hash}
    else
      {:error, reason} ->
        Logger.error("Git commit failed",
          module: :ast_migrate_git,
          operation: :commit_transformations,
          files_count: length(files),
          error: inspect(reason),
          commit_message: message
        )
        {:error, "Git commit failed: #{inspect(reason)}"}
      error ->
        Logger.error("Git commit error",
          module: :ast_migrate_git,
          operation: :commit_transformations,
          files_count: length(files),
          error: inspect(error),
          commit_message: message
        )
        {:error, "Git commit error: #{inspect(error)}"}
    end
  end

  @doc """
  Create a transformation branch for parallel development.
  """
  @spec create_transformation_branch(String.t()) :: {:ok, branch_name()} | {:error, String.t()}
  def create_transformation_branch(rule_name) do
    branch_name = "ast-migration/#{rule_name}-#{timestamp()}"

    with {:ok, repo} <- open_repository(),
         :ok <- :git.branch_create(repo, branch_name),
         :ok <- :git.checkout(repo, branch_name) do
      Logger.info("AST Migration: Created branch #{branch_name}")
      {:ok, branch_name}
    else
      {:error, reason} ->
        {:error, "Failed to create branch: #{inspect(reason)}"}
      error ->
        {:error, "Branch creation error: #{inspect(error)}"}
    end
  end

  @doc """
  Rollback a transformation by reverting the commit.
  """
  @spec rollback_transformation(commit_hash()) :: {:ok, commit_hash()} | {:error, String.t()}
  def rollback_transformation(commit_hash) do
    with {:ok, repo} <- open_repository(),
         :ok <- :git.revert(repo, commit_hash) do
      Logger.info("AST Migration: Reverted commit #{commit_hash}")
      {:ok, commit_hash}
    else
      {:error, reason} ->
        {:error, "Failed to revert: #{inspect(reason)}"}
      error ->
        {:error, "Revert error: #{inspect(error)}"}
    end
  end

  @doc """
  Merge a transformation branch back to main.
  """
  @spec merge_transformation_branch(branch_name()) :: {:ok, commit_hash()} | {:error, String.t()}
  def merge_transformation_branch(branch_name) do
    with {:ok, repo} <- open_repository(),
         {:ok, commit_hash} <- :git.merge(repo, branch_name) do
      Logger.info("AST Migration: Merged branch #{branch_name} with #{commit_hash}")
      {:ok, commit_hash}
    else
      {:error, reason} ->
        {:error, "Failed to merge: #{inspect(reason)}"}
      error ->
        {:error, "Merge error: #{inspect(error)}"}
    end
  end

  @doc """
  Get transformation history by filtering commits with [AST] prefix.
  """
  @spec get_transformation_history() :: {:ok, [map()]} | {:error, String.t()}
  def get_transformation_history do
    with {:ok, repo} <- open_repository(),
         {:ok, commits} <- :git.log(repo, grep: "[AST]") do
      {:ok, Enum.map(commits, &format_commit/1)}
    else
      {:error, reason} ->
        {:error, "Failed to get history: #{inspect(reason)}"}
      error ->
        {:error, "History error: #{inspect(error)}"}
    end
  end

  @doc """
  Check if the current repository is a valid Git repository.
  """
  @spec validate_repository() :: :ok | {:error, String.t()}
  def validate_repository do
    case open_repository() do
      {:ok, _repo} -> :ok
      {:error, :not_a_repository} ->
        {:error, "Current directory is not a Git repository"}
      {:error, reason} ->
        {:error, "Git repository validation failed: #{inspect(reason)}"}
    end
  end
end
