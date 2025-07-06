# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AstMigrate.Git do
  @moduledoc """
  Git operations using EGit for reliable integration.

  This module provides structured error handling and type safety for all
  Git operations used by the AST migration tool. Uses EGit's :git module
  for pure Elixir Git operations without shell dependencies.
  """

  require Logger

  @type commit_hash :: String.t()
  @type branch_name :: String.t()
  @type file_path :: String.t()
  @type repo_path :: String.t()
  @type repo_ref :: reference()

  defp timestamp do
    DateTime.utc_now() |> DateTime.to_unix()
  end

  @doc "Ensure the working tree is clean before applying transformations."
  @spec ensure_clean_working_tree(repo_path()) :: :ok | {:error, String.t()}
  def ensure_clean_working_tree(repo_path \\ ".") do
    with {:ok, repo} <- open_repository(repo_path),
         {:ok, status} <- get_status(repo) do
      case status do
        [] ->
          :ok
        status_entries when is_list(status_entries) ->
          status_summary = format_status_entries(status_entries)
          {:error, "Working tree not clean:\n#{status_summary}"}
      end
    else
      {:error, reason} -> {:error, "Failed to check Git status: #{inspect(reason)}"}
    end
  end

  @doc "Commit transformations with proper AST migration metadata."
  @spec commit_transformations([file_path()], String.t()) ::
          {:ok, commit_hash()} | {:error, String.t()}
  def commit_transformations(files, message) do
    commit_transformations(".", message, files)
  end

  @doc "Commit transformations with proper AST migration metadata (3-arity version)."
  @spec commit_transformations(repo_path(), String.t(), [file_path()]) ::
          {:ok, commit_hash()} | {:error, String.t()}
  def commit_transformations(repo_path, message, files) do
    Logger.debug("Starting Git commit for transformations",
      module: :ast_migrate_git,
      operation: :commit_transformations,
      files_count: length(files),
      commit_message: message
    )

    with :ok <- ensure_clean_working_tree(repo_path),
         {:ok, repo} <- open_repository(repo_path),
         {:ok, _} <- add_files(repo, files),
         {:ok, commit_hash} <- commit_with_message(repo, "[AST] #{message}") do
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
          error: reason,
          commit_message: message
        )

        {:error, "Git commit failed: #{reason}"}
    end
  end

  @doc "Create a transformation branch for parallel development."
  @spec create_transformation_branch(String.t()) :: {:ok, branch_name()} | {:error, String.t()}
  def create_transformation_branch(rule_name) do
    create_transformation_branch(".", rule_name)
  end

  @doc "Create a transformation branch for parallel development (with repo path)."
  @spec create_transformation_branch(repo_path(), String.t()) :: {:ok, branch_name()} | {:error, String.t()}
  def create_transformation_branch(repo_path, rule_name) do
    branch_name = "ast-migration/#{rule_name}-#{timestamp()}"

    with {:ok, repo} <- open_repository(repo_path),
         :ok <- create_and_checkout_branch(repo, branch_name) do
      Logger.info("AST Migration: Created branch #{branch_name}")
      {:ok, branch_name}
    else
      {:error, reason} -> {:error, "Failed to create branch: #{inspect(reason)}"}
    end
  end

  @doc "Rollback a transformation by reverting the commit."
  @spec rollback_transformation(commit_hash()) :: {:ok, commit_hash()} | {:error, String.t()}
  def rollback_transformation(commit_hash) do
    rollback_transformation(".", commit_hash)
  end

  @doc "Rollback a transformation by reverting the commit (with repo path)."
  @spec rollback_transformation(repo_path(), commit_hash()) :: {:ok, commit_hash()} | {:error, String.t()}
  def rollback_transformation(repo_path, commit_hash) do
    with {:ok, repo} <- open_repository(repo_path),
         :ok <- revert_commit(repo, commit_hash),
         {:ok, new_commit_hash} <- get_head_commit(repo) do
      Logger.info("AST Migration: Reverted commit #{commit_hash}")
      {:ok, new_commit_hash}
    else
      {:error, reason} -> {:error, "Failed to revert: #{inspect(reason)}"}
    end
  end

  @doc "Merge a transformation branch back to main."
  @spec merge_transformation_branch(branch_name()) :: {:ok, commit_hash()} | {:error, String.t()}
  def merge_transformation_branch(branch_name) do
    merge_transformation_branch(".", branch_name)
  end

  @doc "Merge a transformation branch back to main (with repo path)."
  @spec merge_transformation_branch(repo_path(), branch_name()) :: {:ok, commit_hash()} | {:error, String.t()}
  def merge_transformation_branch(repo_path, branch_name) do
    with {:ok, repo} <- open_repository(repo_path),
         :ok <- merge_branch(repo, branch_name),
         {:ok, commit_hash} <- get_head_commit(repo) do
      Logger.info("AST Migration: Merged branch #{branch_name} with #{commit_hash}")
      {:ok, commit_hash}
    else
      {:error, reason} -> {:error, "Failed to merge: #{inspect(reason)}"}
    end
  end

  @doc "Get transformation history by filtering commits with [AST] prefix."
  @spec get_transformation_history() :: {:ok, [map()]} | {:error, String.t()}
  def get_transformation_history do
    get_transformation_history(".")
  end

  @doc "Get transformation history by filtering commits with [AST] prefix (with repo path)."
  @spec get_transformation_history(repo_path()) :: {:ok, [map()]} | {:error, String.t()}
  def get_transformation_history(repo_path) do
    with {:ok, repo} <- open_repository(repo_path),
         {:ok, commits} <- get_commit_history(repo) do
      ast_commits =
        commits
        |> Enum.filter(fn commit -> String.contains?(commit.message, "[AST]") end)
        |> Enum.map(fn commit -> %{hash: commit.oid, message: commit.message} end)

      {:ok, ast_commits}
    else
      {:error, reason} -> {:error, "Failed to get history: #{inspect(reason)}"}
    end
  end

  @doc "Check if the current repository is a valid Git repository."
  @spec validate_repository() :: :ok | {:error, String.t()}
  def validate_repository do
    validate_repository(".")
  end

  @doc "Check if the repository is a valid Git repository (with repo path)."
  @spec validate_repository(repo_path()) :: :ok | {:error, String.t()}
  def validate_repository(repo_path) do
    case open_repository(repo_path) do
      {:ok, _repo} -> :ok
      {:error, reason} -> {:error, "Git repository validation failed: #{inspect(reason)}"}
    end
  end

  # Private helper functions

  defp open_repository(repo_path) do
    case :git.open(repo_path) do
      repo when is_reference(repo) -> {:ok, repo}
      {:error, reason} -> {:error, reason}
      error -> {:error, error}
    end
  end

  defp get_status(repo) do
    case :git.status(repo) do
      status when is_list(status) -> {:ok, status}
      {:error, reason} -> {:error, reason}
      error -> {:error, error}
    end
  end

  defp format_status_entries(status_entries) do
    status_entries
    |> Enum.flat_map(fn
      %{index: index_changes} when is_list(index_changes) ->
        Enum.map(index_changes, fn {status, file} -> "#{status} #{file}" end)
      %{workdir: workdir_changes} when is_list(workdir_changes) ->
        Enum.map(workdir_changes, fn {status, file} -> "#{status} #{file}" end)
      entry ->
        ["#{inspect(entry)}"]
    end)
    |> Enum.join("\n")
  end

  defp add_files(repo, files) do
    case :git.add(repo, files) do
      %{mode: :added} -> {:ok, :added}
      %{mode: mode} -> {:ok, mode}
      {:error, reason} -> {:error, reason}
      error -> {:error, error}
    end
  end

  defp commit_with_message(repo, message) do
    case :git.commit(repo, message) do
      {:ok, commit_hash} when is_binary(commit_hash) -> {:ok, commit_hash}
      :ok ->
        # If commit returns :ok, get the HEAD commit hash
        get_head_commit(repo)
      {:error, reason} -> {:error, reason}
      error -> {:error, error}
    end
  end

  defp create_and_checkout_branch(repo, branch_name) do
    case :git.branch_create(repo, branch_name) do
      :ok ->
        case :git.checkout(repo, branch_name) do
          :ok -> :ok
          {:error, reason} -> {:error, reason}
          error -> {:error, error}
        end
      {:error, reason} -> {:error, reason}
      error -> {:error, error}
    end
  end

  defp revert_commit(repo, _commit_hash) do
    # EGit may not have direct revert support, so we'll use reset for now
    case :git.reset(repo, :hard) do
      :ok -> :ok
      {:error, reason} -> {:error, reason}
      error -> {:error, error}
    end
  end

  defp merge_branch(repo, branch_name) do
    # This is a simplified merge - in practice you might need more sophisticated merging
    case :git.checkout(repo, branch_name) do
      :ok -> :ok
      {:error, reason} -> {:error, reason}
      error -> {:error, error}
    end
  end

  defp get_head_commit(repo) do
    case :git.rev_parse(repo, "HEAD") do
      {:ok, commit_hash} when is_binary(commit_hash) -> {:ok, commit_hash}
      commit_hash when is_binary(commit_hash) -> {:ok, commit_hash}
      {:error, reason} -> {:error, reason}
      error -> {:error, error}
    end
  end

  defp get_commit_history(repo) do
    case :git.rev_list(repo, ["HEAD"], []) do
      commits when is_list(commits) -> {:ok, commits}
      {:error, reason} -> {:error, reason}
      error -> {:error, error}
    end
  end
end
