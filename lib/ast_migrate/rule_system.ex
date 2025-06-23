# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AstMigrate.RuleSystem do
  @moduledoc """
  Advanced transformation rule system with parallel processing and Git integration.

  This module provides the Phase 1 implementation with:
  - Task.async_stream for parallel file processing
  - Advanced rule composition and dependency management
  - Git integration for transformation tracking
  - Comprehensive error handling and recovery
  """

  require Logger

  alias AstMigrate.Parser
  alias AstMigrate.Git

  @type rule_module :: module()
  @type file_path :: String.t()
  @type transformation_result :: {:ok, String.t()} | {:error, String.t()}
  @type batch_result :: {:ok, [file_path()], [file_path()]} | {:error, String.t()}

  @doc """
  Apply transformation rules to multiple files in parallel using Task.async_stream.

  ## Options

  - `:max_concurrency` - Maximum concurrent transformations (default: System.schedulers_online())
  - `:timeout` - Timeout per file transformation in milliseconds (default: 30_000)
  - `:ordered` - Whether to maintain file order in results (default: false)
  - `:on_timeout` - Action on timeout: `:exit` or `:kill_task` (default: :exit)
  - `:git_commit` - Whether to create Git commit after transformations (default: false)
  - `:commit_message` - Custom commit message (default: auto-generated)

  ## Examples

      # Transform files in parallel
      AstMigrate.RuleSystem.transform_files(
        ["lib/module1.ex", "lib/module2.ex"],
        [AstMigrate.Rules.StateV2ToState],
        max_concurrency: 4,
        git_commit: true,
        commit_message: "Convert StateV2 to State"
      )
  """
  @spec transform_files([file_path()], [rule_module()], keyword()) :: batch_result()
  def transform_files(file_paths, rule_modules, opts \\ []) do
    options = Keyword.merge(default_transform_options(), opts)

    Logger.info("Starting parallel file transformations",
      module: :ast_migrate_rule_system,
      operation: :transform_files,
      file_count: length(file_paths),
      rule_count: length(rule_modules),
      options: options
    )

    start_time = System.monotonic_time(:millisecond)

    # Validate rules before processing
    with :ok <- validate_rules(rule_modules),
         :ok <- validate_files(file_paths) do

      # Process files in parallel using Task.async_stream
      stream_options = [
        max_concurrency: options[:max_concurrency],
        timeout: options[:timeout],
        ordered: options[:ordered],
        on_timeout: options[:on_timeout]
      ]

      results = file_paths
      |> Task.async_stream(&transform_single_file(&1, rule_modules, options), stream_options)
      |> Enum.to_list()

      # Process results and handle errors
      {successful_files, failed_files} = categorize_results(results, file_paths)

      end_time = System.monotonic_time(:millisecond)
      duration = end_time - start_time

      Logger.info("Parallel transformations completed",
        module: :ast_migrate_rule_system,
        operation: :transform_files,
        duration_ms: duration,
        successful_count: length(successful_files),
        failed_count: length(failed_files),
        total_files: length(file_paths)
      )

      # Create Git commit if requested and transformations were successful
      if options[:git_commit] and length(successful_files) > 0 do
        commit_transformations(successful_files, rule_modules, options)
      end

      {:ok, successful_files, failed_files}
    else
      {:error, reason} ->
        Logger.error("Transformation validation failed",
          module: :ast_migrate_rule_system,
          operation: :transform_files,
          error: reason
        )
        {:error, reason}
    end
  end

  @doc """
  Apply transformation rules to a single file with comprehensive error handling.
  """
  @spec transform_single_file(file_path(), [rule_module()], keyword()) :: transformation_result()
  def transform_single_file(file_path, rule_modules, opts \\ []) do
    Logger.debug("Starting single file transformation",
      module: :ast_migrate_rule_system,
      operation: :transform_single_file,
      file: file_path,
      rules: rule_modules
    )

    start_time = System.monotonic_time(:microsecond)

    try do
      with {:ok, zipper} <- Parser.parse_file(file_path),
           {:ok, transformed_zipper} <- apply_rules_to_zipper(zipper, rule_modules),
           {:ok, transformed_code} <- Parser.to_string(transformed_zipper),
           :ok <- write_transformed_file(file_path, transformed_code, opts) do

        end_time = System.monotonic_time(:microsecond)
        duration = end_time - start_time

        Logger.debug("Single file transformation completed",
          module: :ast_migrate_rule_system,
          operation: :transform_single_file,
          file: file_path,
          duration_us: duration,
          original_size: File.stat!(file_path).size,
          transformed_size: byte_size(transformed_code)
        )

        {:ok, transformed_code}
      else
        {:error, reason} ->
          Logger.warning("Single file transformation failed",
            module: :ast_migrate_rule_system,
            operation: :transform_single_file,
            file: file_path,
            error: reason
          )
          {:error, reason}
      end
    rescue
      exception ->
        Logger.error("Exception during single file transformation",
          module: :ast_migrate_rule_system,
          operation: :transform_single_file,
          file: file_path,
          exception: inspect(exception),
          stacktrace: Exception.format_stacktrace(__STACKTRACE__)
        )
        {:error, "Exception: #{inspect(exception)}"}
    end
  end

  @doc """
  Compose multiple transformation rules into a single transformation pipeline.

  Rules are applied in the order specified, with each rule receiving the output
  of the previous rule.
  """
  @spec compose_rules([rule_module()]) :: (Sourceror.Zipper.t() -> {:ok, Sourceror.Zipper.t()} | {:error, String.t()})
  def compose_rules(rule_modules) do
    fn zipper ->
      Logger.debug("Composing transformation rules",
        module: :ast_migrate_rule_system,
        operation: :compose_rules,
        rule_count: length(rule_modules)
      )

      Enum.reduce_while(rule_modules, {:ok, zipper}, fn rule_module, {:ok, current_zipper} ->
        case apply_single_rule(current_zipper, rule_module) do
          {:ok, transformed_zipper} ->
            {:cont, {:ok, transformed_zipper}}
          {:error, reason} ->
            Logger.warning("Rule composition failed",
              module: :ast_migrate_rule_system,
              operation: :compose_rules,
              failed_rule: rule_module,
              error: reason
            )
            {:halt, {:error, "Rule #{rule_module} failed: #{reason}"}}
        end
      end)
    end
  end

  @doc """
  Validate that all specified rule modules are available and properly implemented.
  """
  @spec validate_rules([rule_module()]) :: :ok | {:error, String.t()}
  def validate_rules(rule_modules) do
    Logger.debug("Validating transformation rules",
      module: :ast_migrate_rule_system,
      operation: :validate_rules,
      rules: rule_modules
    )

    invalid_rules = Enum.filter(rule_modules, fn rule_module ->
      not Code.ensure_loaded?(rule_module) or
      not function_exported?(rule_module, :transform_file, 1)
    end)

    case invalid_rules do
      [] ->
        Logger.debug("All rules validated successfully",
          module: :ast_migrate_rule_system,
          operation: :validate_rules
        )
        :ok

      invalid ->
        error_msg = "Invalid rules: #{inspect(invalid)}"
        Logger.error("Rule validation failed",
          module: :ast_migrate_rule_system,
          operation: :validate_rules,
          invalid_rules: invalid
        )
        {:error, error_msg}
    end
  end

  @doc """
  Validate that all specified files exist and are readable.
  """
  @spec validate_files([file_path()]) :: :ok | {:error, String.t()}
  def validate_files(file_paths) do
    Logger.debug("Validating input files",
      module: :ast_migrate_rule_system,
      operation: :validate_files,
      file_count: length(file_paths)
    )

    invalid_files = Enum.filter(file_paths, fn file_path ->
      not File.exists?(file_path) or not File.regular?(file_path)
    end)

    case invalid_files do
      [] ->
        Logger.debug("All files validated successfully",
          module: :ast_migrate_rule_system,
          operation: :validate_files
        )
        :ok

      invalid ->
        error_msg = "Invalid files: #{inspect(invalid)}"
        Logger.error("File validation failed",
          module: :ast_migrate_rule_system,
          operation: :validate_files,
          invalid_files: invalid
        )
        {:error, error_msg}
    end
  end

  # Private functions

  defp default_transform_options do
    [
      max_concurrency: System.schedulers_online(),
      timeout: 30_000,
      ordered: false,
      on_timeout: :exit,
      git_commit: false,
      commit_message: nil,
      dry_run: false
    ]
  end

  defp apply_rules_to_zipper(zipper, rule_modules) do
    composed_transformation = compose_rules(rule_modules)
    composed_transformation.(zipper)
  end

  defp apply_single_rule(zipper, rule_module) do
    Logger.debug("Applying single rule to zipper",
      module: :ast_migrate_rule_system,
      operation: :apply_single_rule,
      rule: rule_module
    )

    try do
      # Convert zipper to string, apply rule, then parse back to zipper
      with {:ok, code} <- Parser.to_string(zipper),
           {:ok, transformed_code} <- rule_module.transform_file_content(code),
           {:ok, transformed_zipper} <- Parser.parse_string(transformed_code) do
        {:ok, transformed_zipper}
      else
        {:error, reason} -> {:error, reason}
      end
    rescue
      exception ->
        Logger.error("Exception applying rule",
          module: :ast_migrate_rule_system,
          operation: :apply_single_rule,
          rule: rule_module,
          exception: inspect(exception)
        )
        {:error, "Rule exception: #{inspect(exception)}"}
    end
  end

  defp write_transformed_file(file_path, transformed_code, opts) do
    if opts[:dry_run] do
      Logger.debug("Dry run - not writing file",
        module: :ast_migrate_rule_system,
        operation: :write_transformed_file,
        file: file_path
      )
      :ok
    else
      case File.write(file_path, transformed_code) do
        :ok ->
          Logger.debug("File written successfully",
            module: :ast_migrate_rule_system,
            operation: :write_transformed_file,
            file: file_path,
            size: byte_size(transformed_code)
          )
          :ok

        {:error, reason} ->
          Logger.error("Failed to write file",
            module: :ast_migrate_rule_system,
            operation: :write_transformed_file,
            file: file_path,
            error: reason
          )
          {:error, "Write failed: #{inspect(reason)}"}
      end
    end
  end

  defp categorize_results(results, file_paths) do
    {successful, failed} = results
    |> Enum.with_index()
    |> Enum.reduce({[], []}, fn {result, index}, {success_acc, fail_acc} ->
      file_path = Enum.at(file_paths, index)

      case result do
        {:ok, _} -> {[file_path | success_acc], fail_acc}
        {:exit, :timeout} -> {success_acc, [file_path | fail_acc]}
        {:error, _} -> {success_acc, [file_path | fail_acc]}
      end
    end)

    {Enum.reverse(successful), Enum.reverse(failed)}
  end

  defp commit_transformations(successful_files, rule_modules, opts) do
    commit_message = opts[:commit_message] || generate_commit_message(rule_modules, successful_files)

    Logger.info("Creating Git commit for transformations",
      module: :ast_migrate_rule_system,
      operation: :commit_transformations,
      file_count: length(successful_files),
      message: commit_message
    )

    case Git.commit_transformations(".", commit_message, successful_files) do
      {:ok, commit} ->
        Logger.info("Git commit created successfully",
          module: :ast_migrate_rule_system,
          operation: :commit_transformations,
          commit_hash: commit
        )
        {:ok, commit}

      {:error, reason} ->
        Logger.error("Failed to create Git commit",
          module: :ast_migrate_rule_system,
          operation: :commit_transformations,
          error: reason
        )
        {:error, reason}
    end
  end

  defp generate_commit_message(rule_modules, successful_files) do
    rule_names = Enum.map(rule_modules, &extract_rule_name/1)
    file_count = length(successful_files)

    "[AST] Apply #{Enum.join(rule_names, ", ")} to #{file_count} files"
  end

  defp extract_rule_name(rule_module) do
    rule_module
    |> Module.split()
    |> List.last()
    |> Macro.underscore()
  end
end
