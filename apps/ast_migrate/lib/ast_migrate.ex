# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AstMigrate do
  @moduledoc """
  Git-Native Elixir AST Migration Tool

  This module provides systematic code transformations with Git integration
  for large-scale Elixir codebases.

  ## Usage

  The ast_migrate tool is designed to apply AST-based transformations to Elixir
  code with Git integration for safe, reversible changes.

  Currently, this is a clean foundation ready for future transformation rules.
  Rules should implement the `AstMigrate.Rules.Behaviour` interface.

  ## Example Future Usage

      # Apply a transformation rule
      AstMigrate.apply_rule(:example_rule, files: ["lib/**/*.ex"])

      # Preview changes without applying them
      AstMigrate.apply_rule(:example_rule, files: ["lib/**/*.ex"], dry_run: true)

      # Apply and commit changes
      AstMigrate.apply_rule(:example_rule,
        files: ["lib/**/*.ex"],
        commit: "Apply example transformation")
  """

  require Logger
  alias AstMigrate.Git

  @type transformation_result :: {:ok, String.t()} | {:error, String.t()}
  @type file_result :: {:ok, String.t()} | {:error, String.t()}
  @type rule_name :: atom()

  @doc """
  Apply a transformation rule to files and optionally commit the changes.

  ## Options

  - `:files` - List of file patterns to transform (default: ["lib/**/*.ex", "test/**/*.exs"])
  - `:dry_run` - Preview changes without applying them (default: false)
  - `:commit` - Commit message to use if changes are made (optional)

  ## Returns

  - `{:ok, result_map}` - Transformation completed successfully
  - `{:error, reason}` - Transformation failed

  The result map contains:
  - `:rule` - The rule name that was applied
  - `:files_processed` - Number of files that were processed
  - `:files_changed` - Number of files that were actually modified
  - `:commit_hash` - Git commit hash if changes were committed
  """
  @spec apply_rule(rule_name(), keyword()) :: {:ok, map()} | {:error, String.t()}
  def apply_rule(rule_name, opts \\ []) do
    start_time = System.monotonic_time(:millisecond)

    Logger.info("Starting AST transformation",
      module: :ast_migrate,
      operation: :apply_rule,
      rule: rule_name,
      dry_run: Keyword.get(opts, :dry_run, false),
      commit_requested: Keyword.has_key?(opts, :commit)
    )

    with {:ok, rule_module} <- get_rule_module(rule_name),
         {:ok, files} <- get_target_files(rule_module, opts),
         :ok <- validate_preconditions(rule_module, files),
         {:ok, results} <- apply_transformations(rule_module, files, opts),
         :ok <- maybe_commit_changes(results, opts) do
      duration_ms = System.monotonic_time(:millisecond) - start_time

      Logger.info("AST transformation completed successfully",
        module: :ast_migrate,
        operation: :apply_rule,
        rule: rule_name,
        files_processed: length(results.transformed_files),
        files_changed: length(results.changed_files),
        commit_hash: results.commit_hash,
        duration_ms: duration_ms
      )

      {:ok,
       %{
         rule: rule_name,
         files_processed: length(results.transformed_files),
         files_changed: length(results.changed_files),
         changed_files: results.changed_files,
         commit_hash: results.commit_hash
       }}
    else
      error ->
        duration_ms = System.monotonic_time(:millisecond) - start_time

        Logger.error("AST transformation failed",
          module: :ast_migrate,
          operation: :apply_rule,
          rule: rule_name,
          error: inspect(error),
          duration_ms: duration_ms
        )

        error
    end
  end

  @doc """
  List available transformation rules.

  Returns all available AST migration rules for cross-app dependency detection
  and systematic code transformations.
  """
  @spec list_rules() :: [atom()]
  def list_rules do
    [:cross_app_dependency_detector, :fix_timeline_legacy_namespace]
  end

  @doc """
  Get information about a specific transformation rule.

  Returns rule metadata including name, module, and description.
  """
  @spec rule_info(rule_name()) :: {:error, String.t()}
  def rule_info(rule_name) do
    get_rule_module(rule_name)
  end

  # Private functions

  defp get_rule_module(rule_name) do
    case rule_name do
      :cross_app_dependency_detector ->
        {:ok, AstMigrate.Rules.CrossAppDependencyDetector}

      :fix_timeline_legacy_namespace ->
        {:ok, AstMigrate.Rules.FixTimelineLegacyNamespace}

      _ ->
        {:error, "Unknown rule: #{rule_name}"}
    end
  end

  defp get_target_files(rule_module, opts) do
    patterns =
      case Keyword.get(opts, :files) do
        nil -> rule_module.file_patterns()
        custom_files -> custom_files
      end

    # Expand patterns and resolve relative paths
    files =
      patterns
      |> Enum.flat_map(fn pattern ->
        # If pattern starts with ../, resolve it relative to current directory
        expanded_pattern =
          if String.starts_with?(pattern, "../") do
            Path.expand(pattern)
          else
            pattern
          end

        Path.wildcard(expanded_pattern)
      end)
      # Ensure all paths are absolute
      |> Enum.map(&Path.expand/1)
      # Remove duplicates
      |> Enum.uniq()

    Logger.debug("Target files identified",
      module: :ast_migrate,
      operation: :get_target_files,
      patterns: patterns,
      files_count: length(files)
    )

    {:ok, files}
  end

  defp validate_preconditions(rule_module, files) do
    case rule_module.validate_preconditions(files) do
      :ok -> :ok
      {:error, reason} -> {:error, "Precondition failed: #{reason}"}
    end
  end

  defp apply_transformations(rule_module, files, opts) do
    if Keyword.get(opts, :dry_run, false) do
      preview_transformations(rule_module, files)
    else
      execute_transformations(rule_module, files)
    end
  end

  defp preview_transformations(rule_module, files) do
    Logger.debug("Starting preview transformations",
      module: :ast_migrate,
      operation: :preview_transformations,
      rule_module: rule_module,
      files_count: length(files)
    )

    results =
      Enum.map(files, fn file ->
        case rule_module.transform_file(file) do
          {:ok, transformed_content} ->
            original_content = File.read!(file)

            if original_content != transformed_content do
              {:changed, file, original_content, transformed_content}
            else
              {:unchanged, file}
            end

          {:error, reason} ->
            {:error, file, reason}
        end
      end)

    changed_files = Enum.filter(results, &match?({:changed, _, _, _}, &1))

    {:ok,
     %{
       transformed_files: files,
       changed_files: Enum.map(changed_files, fn {:changed, file, _, _} -> file end),
       preview: results,
       commit_hash: nil
     }}
  end

  defp execute_transformations(rule_module, files) do
    Logger.debug("Starting file transformations",
      module: :ast_migrate,
      operation: :execute_transformations,
      rule_module: rule_module,
      files_count: length(files)
    )

    results =
      Enum.map(files, fn file ->
        case rule_module.transform_file(file) do
          {:ok, transformed_content} ->
            original_content = File.read!(file)

            if original_content != transformed_content do
              File.write!(file, transformed_content)
              {:changed, file}
            else
              {:unchanged, file}
            end

          {:error, reason} ->
            {:error, file, reason}
        end
      end)

    changed_files =
      Enum.filter(results, &match?({:changed, _}, &1))
      |> Enum.map(fn {:changed, file} -> file end)

    {:ok, %{transformed_files: files, changed_files: changed_files, commit_hash: nil}}
  end

  defp maybe_commit_changes(results, opts) do
    case Keyword.get(opts, :commit) do
      nil ->
        :ok

      commit_message when is_binary(commit_message) ->
        if length(results.changed_files) > 0 do
          case Git.commit_transformations(results.changed_files, commit_message) do
            {:ok, _commit_hash} -> :ok
            error -> error
          end
        else
          :ok
        end
    end
  end
end
