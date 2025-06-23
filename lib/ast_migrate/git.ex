defmodule AstMigrate.Git do
  @moduledoc "Git operations using system Git commands for reliable integration.\n\nThis module provides structured error handling and type safety for all\nGit operations used by the AST migration tool.\n"
  require Logger
  @type commit_hash :: String.t()
  @type branch_name :: String.t()
  @type file_path :: String.t()
  defp get_author do
    %{name: "AST Migration Tool", email: "ast-migrate@localhost"}
  end

  defp timestamp do
    DateTime.utc_now() |> DateTime.to_unix()
  end

  defp run_git_command(args, opts \\ []) do
    case System.cmd("git", args, opts) do
      {output, 0} -> {:ok, String.trim(output)}
      {error, code} -> {:error, "Git command failed (exit #{code}): #{String.trim(error)}"}
    end
  end

  @doc "Ensure the working tree is clean before applying transformations.\n"
  @spec ensure_clean_working_tree(String.t()) :: :ok | {:error, String.t()}
  def ensure_clean_working_tree(_repo_path \\ ".") do
    case run_git_command(["status", "--porcelain"]) do
      {:ok, ""} -> :ok
      {:ok, output} -> {:error, "Working tree not clean:
#{output}"}
      {:error, reason} -> {:error, "Failed to check Git status: #{reason}"}
    end
  end

  @doc "Commit transformations with proper AST migration metadata.\n"
  @spec commit_transformations([file_path()], String.t()) ::
          {:ok, commit_hash()} | {:error, String.t()}
  def commit_transformations(files, message) do
    commit_transformations(".", message, files)
  end

  @doc "Commit transformations with proper AST migration metadata (3-arity version).\n"
  @spec commit_transformations(String.t(), String.t(), [file_path()]) ::
          {:ok, commit_hash()} | {:error, String.t()}
  def commit_transformations(_repo_path, message, files) do
    Logger.debug("Starting Git commit for transformations",
      module: :ast_migrate_git,
      operation: :commit_transformations,
      files_count: length(files),
      commit_message: message
    )

    with :ok <- ensure_clean_working_tree(),
         {:ok, _} <- run_git_command(["add"] ++ files),
         {:ok, _} <- run_git_command(["commit", "-m", "[AST] #{message}"]),
         {:ok, commit_hash} <- run_git_command(["rev-parse", "HEAD"]) do
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

  @doc "Create a transformation branch for parallel development.\n"
  @spec create_transformation_branch(String.t()) :: {:ok, branch_name()} | {:error, String.t()}
  def create_transformation_branch(rule_name) do
    branch_name = "ast-migration/#{rule_name}-#{timestamp()}"

    with {:ok, _} <- run_git_command(["checkout", "-b", branch_name]) do
      Logger.info("AST Migration: Created branch #{branch_name}")
      {:ok, branch_name}
    else
      {:error, reason} -> {:error, "Failed to create branch: #{reason}"}
    end
  end

  @doc "Rollback a transformation by reverting the commit.\n"
  @spec rollback_transformation(commit_hash()) :: {:ok, commit_hash()} | {:error, String.t()}
  def rollback_transformation(commit_hash) do
    with {:ok, _} <- run_git_command(["revert", "--no-edit", commit_hash]),
         {:ok, new_commit_hash} <- run_git_command(["rev-parse", "HEAD"]) do
      Logger.info("AST Migration: Reverted commit #{commit_hash}")
      {:ok, new_commit_hash}
    else
      {:error, reason} -> {:error, "Failed to revert: #{reason}"}
    end
  end

  @doc "Merge a transformation branch back to main.\n"
  @spec merge_transformation_branch(branch_name()) :: {:ok, commit_hash()} | {:error, String.t()}
  def merge_transformation_branch(branch_name) do
    with {:ok, _} <- run_git_command(["merge", branch_name]),
         {:ok, commit_hash} <- run_git_command(["rev-parse", "HEAD"]) do
      Logger.info("AST Migration: Merged branch #{branch_name} with #{commit_hash}")
      {:ok, commit_hash}
    else
      {:error, reason} -> {:error, "Failed to merge: #{reason}"}
    end
  end

  @doc "Get transformation history by filtering commits with [AST] prefix.\n"
  @spec get_transformation_history() :: {:ok, [map()]} | {:error, String.t()}
  def get_transformation_history do
    with {:ok, output} <- run_git_command(["log", "--oneline", "--grep=\\[AST\\]"]) do
      commits =
        output
        |> String.split("\n", trim: true)
        |> Enum.map(fn line ->
          [hash | message_parts] = String.split(line, " ", parts: 2)
          message = Enum.join(message_parts, " ")
          %{hash: hash, message: message}
        end)

      {:ok, commits}
    else
      {:error, reason} -> {:error, "Failed to get history: #{reason}"}
    end
  end

  @doc "Check if the current repository is a valid Git repository.\n"
  @spec validate_repository() :: :ok | {:error, String.t()}
  def validate_repository do
    case run_git_command(["rev-parse", "--git-dir"]) do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, "Git repository validation failed: #{reason}"}
    end
  end
end