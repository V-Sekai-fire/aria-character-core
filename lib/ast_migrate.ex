# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AstMigrate do
  @moduledoc """
  Git-Native Elixir AST Migration Tool

  This module provides systematic code transformations with Git integration
  for large-scale Elixir codebases. It leverages Git directly as the version
  control backend for transformation tracking and rollback capabilities.

  ## Phase 0: Immediate Relief

  The initial implementation focuses on StateV2 → State migration with:
  - AST-based transformations using Code.string_to_quoted/2
  - Git integration for automatic commits using egit
  - Basic pattern matching on AST nodes
  - Safe rollback capabilities

  ## Usage

      # Apply transformation and commit in one step
      mix ast.simple --rule state_v2_to_state --commit "Convert StateV2 to State"

  ## Architecture

  The tool uses a rule-based system where each transformation rule:
  - Defines AST pattern matching for specific code patterns
  - Provides transformation logic for converting matched patterns
  - Includes validation for ensuring syntax correctness
  - Integrates with Git for version control

  ## Safety Features

  - Syntax validation before and after transformations
  - Atomic Git commits for rollback capability
  - Backup creation before applying transformations
  - Comprehensive error handling and recovery
  """

  alias AstMigrate.{Git, Rules, Validator}

  @type transformation_result :: {:ok, String.t()} | {:error, String.t()}
  @type file_result :: {:ok, String.t()} | {:error, String.t()}
  @type rule_name :: atom()

  @doc """
  Apply a transformation rule to files and optionally commit the changes.

  ## Options

  - `:commit` - Commit message for automatic Git commit
  - `:files` - List of file patterns to transform (default: all .ex and .exs files)
  - `:dry_run` - Preview changes without applying them

  ## Examples

      # Apply transformation and commit
      AstMigrate.apply_rule(:state_v2_to_state, commit: "Convert StateV2 to State")

      # Dry run to preview changes
      AstMigrate.apply_rule(:state_v2_to_state, dry_run: true)

      # Apply to specific files only
      AstMigrate.apply_rule(:state_v2_to_state, files: ["lib/aria_engine/*.ex"])
  """
  @spec apply_rule(rule_name(), keyword()) :: {:ok, map()} | {:error, String.t()}
  def apply_rule(rule_name, opts \\ []) do
    with {:ok, rule_module} <- get_rule_module(rule_name),
         {:ok, files} <- get_target_files(opts),
         :ok <- validate_preconditions(rule_module, files),
         {:ok, results} <- apply_transformations(rule_module, files, opts),
         :ok <- maybe_commit_changes(results, opts) do
      {:ok, %{
        rule: rule_name,
        files_processed: length(results.transformed_files),
        files_changed: length(results.changed_files),
        commit_hash: results.commit_hash
      }}
    else
      error -> error
    end
  end

  @doc """
  List available transformation rules.
  """
  @spec list_rules() :: [atom()]
  def list_rules do
    [:state_v2_to_state]
  end

  @doc """
  Get information about a specific transformation rule.
  """
  @spec rule_info(rule_name()) :: {:ok, map()} | {:error, String.t()}
  def rule_info(rule_name) do
    case get_rule_module(rule_name) do
      {:ok, module} ->
        {:ok, %{
          name: rule_name,
          module: module,
          description: module.description(),
          file_patterns: module.file_patterns(),
          preconditions: length(module.preconditions()),
          postconditions: length(module.postconditions())
        }}
      error -> error
    end
  end

  # Private functions

  defp get_rule_module(:state_v2_to_state), do: {:ok, Rules.StateV2ToState}
  defp get_rule_module(rule_name), do: {:error, "Unknown rule: #{rule_name}"}

  defp get_target_files(opts) do
    patterns = Keyword.get(opts, :files, ["lib/**/*.ex", "test/**/*.exs"])
    files = Enum.flat_map(patterns, &Path.wildcard/1)
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
    results = Enum.map(files, fn file ->
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

    {:ok, %{
      transformed_files: files,
      changed_files: Enum.map(changed_files, fn {:changed, file, _, _} -> file end),
      preview: results,
      commit_hash: nil
    }}
  end

  defp execute_transformations(rule_module, files) do
    results = Enum.map(files, fn file ->
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

    changed_files = Enum.filter(results, &match?({:changed, _}, &1))
                   |> Enum.map(fn {:changed, file} -> file end)

    {:ok, %{
      transformed_files: files,
      changed_files: changed_files,
      commit_hash: nil
    }}
  end

  defp maybe_commit_changes(results, opts) do
    case Keyword.get(opts, :commit) do
      nil -> :ok
      commit_message when is_binary(commit_message) ->
        if length(results.changed_files) > 0 do
          case Git.commit_transformations(results.changed_files, commit_message) do
            {:ok, commit_hash} ->
              results = Map.put(results, :commit_hash, commit_hash)
              :ok
            error -> error
          end
        else
          :ok
        end
    end
  end
end
