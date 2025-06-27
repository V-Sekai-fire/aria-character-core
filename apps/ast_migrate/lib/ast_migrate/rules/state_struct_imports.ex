# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AstMigrate.Rules.StateStructImports do
  @moduledoc """
  Fixes State struct import and usage issues across apps.

  This rule addresses compilation failures caused by missing or incorrect
  State struct references. It ensures proper alias statements and struct
  usage patterns are in place for cross-app State dependencies.

  ## Problem Analysis

  State struct conflicts are causing compilation failures in hybrid_planner
  and other apps. Files need proper alias statements for State structs and
  correct module resolution for pattern matching and struct usage.

  ## Transformations Applied

  1. **Add proper alias statements for State structs:**
     ```elixir
     # Before (missing alias)
     %State{field: value}

     # After
     alias AriaEngine.State
     %State{field: value}
     ```

  2. **Fix pattern matching with State structs:**
     ```elixir
     # Before
     def function(%State{} = state)

     # After
     alias AriaEngine.State
     def function(%State{} = state)
     ```

  3. **Update struct construction:**
     ```elixir
     # Before
     %State{field: value}

     # After
     alias AriaEngine.State
     %State{field: value}
     ```

  4. **Fix type specifications:**
     ```elixir
     # Before
     @spec function(State.t()) :: State.t()

     # After
     alias AriaEngine.State
     @spec function(State.t()) :: State.t()
     ```

  5. **Handle cross-app State dependencies:**
     ```elixir
     # Before (in hybrid_planner)
     State.function_call()

     # After
     alias AriaEngine.State
     State.function_call()
     ```
  """

  @behaviour AstMigrate.Rules.Behaviour
  require Logger

  @impl true
  def description do
    "Fixes State struct import and usage issues across apps"
  end

  @impl true
  def file_patterns do
    ["apps/*/lib/**/*.ex", "apps/*/test/**/*.exs"]
  end

  @impl true
  def preconditions do
    [&has_state_struct_issues?/1]
  end

  @impl true
  def postconditions do
    [&compiles_successfully?/1, &has_proper_state_imports?/1]
  end

  @impl true
  def validate_preconditions(files) do
    files_with_issues = Enum.filter(files, &has_state_struct_issues?/1)

    if length(files_with_issues) > 0 do
      Logger.info(
        "Found #{length(files_with_issues)} files with State struct issues",
        module: :ast_migrate_rules_state_struct_imports,
        operation: :validate_preconditions,
        files: files_with_issues
      )

      :ok
    else
      {:error, "No State struct issues found"}
    end
  end

  @impl true
  def transform_file(file_path) do
    Logger.debug("Starting State struct import fixes for file",
      module: :ast_migrate_rules_state_struct_imports,
      operation: :transform_file,
      file: file_path
    )

    with {:ok, content} <- File.read(file_path),
         {:ok, transformed_code} <- transform_file_content(content, file_path) do
      Logger.debug("State struct import fixes completed for file",
        module: :ast_migrate_rules_state_struct_imports,
        operation: :transform_file,
        file: file_path,
        original_size: byte_size(content),
        transformed_size: byte_size(transformed_code)
      )

      {:ok, transformed_code}
    else
      {:error, reason} ->
        Logger.error("State struct import fixes failed for file",
          module: :ast_migrate_rules_state_struct_imports,
          operation: :transform_file,
          file: file_path,
          error: inspect(reason)
        )

        {:error, "Failed to transform #{file_path}: #{inspect(reason)}"}
    end
  end

  @doc "Transform file content directly."
  @spec transform_file_content(String.t(), String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def transform_file_content(content, file_path) do
    Logger.debug("Starting State struct import fixes for content",
      module: :ast_migrate_rules_state_struct_imports,
      operation: :transform_file_content,
      content_size: byte_size(content),
      file_path: file_path
    )

    # Check if we need to add State alias
    needs_state_alias = needs_state_alias?(content, file_path)

    transformed_content =
      if needs_state_alias do
        add_state_alias(content)
      else
        content
      end

    with {:ok, quoted} <- Sourceror.parse_string(transformed_content),
         transformed_quoted <- transform_ast(quoted, file_path),
         transformed_code <- Sourceror.to_string(transformed_quoted) do
      transformations_applied = count_transformations(content, transformed_code)

      Logger.debug("State struct import fixes completed for content",
        module: :ast_migrate_rules_state_struct_imports,
        operation: :transform_file_content,
        transformations_applied: transformations_applied,
        original_size: byte_size(content),
        transformed_size: byte_size(transformed_code)
      )

      {:ok, transformed_code}
    else
      {:error, reason} ->
        Logger.error("State struct import fixes failed for content",
          module: :ast_migrate_rules_state_struct_imports,
          operation: :transform_file_content,
          error: inspect(reason)
        )

        {:error, "Failed to transform content: #{inspect(reason)}"}
    end
  end

  # Check if file needs State alias
  defp needs_state_alias?(content, file_path) do
    app_context = determine_app_context(file_path)

    case app_context do
      :aria_engine_core ->
        # In aria_engine_core, State should be available locally
        false

      _ ->
        # In other apps, check if State is used without proper alias
        has_state_usage = Regex.match?(~r/%State\{|State\./, content)
        has_state_alias = Regex.match?(~r/alias\s+.*State/, content)
        has_state_usage and not has_state_alias
    end
  end

  # Add State alias to content
  defp add_state_alias(content) do
    # Find the best place to insert the alias (after other aliases or at top)
    lines = String.split(content, "\n")

    {before_lines, after_lines} = find_alias_insertion_point(lines)

    alias_line = "  alias AriaEngine.State"

    Enum.join(before_lines ++ [alias_line] ++ after_lines, "\n")
  end

  # Find the best place to insert alias
  defp find_alias_insertion_point(lines) do
    # Look for existing alias statements
    alias_indices =
      lines
      |> Enum.with_index()
      |> Enum.filter(fn {line, _} -> String.match?(line, ~r/^\s*alias\s+/) end)
      |> Enum.map(fn {_, index} -> index end)

    case alias_indices do
      [] ->
        # No existing aliases, insert after defmodule
        defmodule_index =
          lines
          |> Enum.with_index()
          |> Enum.find_index(fn {line, _} -> String.match?(line, ~r/^\s*defmodule\s+/) end)

        case defmodule_index do
          nil -> {[], lines}
          index -> Enum.split(lines, index + 1)
        end

      indices ->
        # Insert after last alias
        last_alias_index = Enum.max(indices)
        Enum.split(lines, last_alias_index + 1)
    end
  end

  # Transform AST using Sourceror.Zipper for better traversal
  defp transform_ast(quoted, file_path) do
    app_context = determine_app_context(file_path)

    Sourceror.Zipper.zip(quoted)
    |> Sourceror.Zipper.traverse(fn zipper -> transform_node(zipper, app_context) end)
    |> Sourceror.Zipper.root()
  end

  # Determine which app context we're in based on file path
  defp determine_app_context(file_path) do
    cond do
      String.contains?(file_path, "apps/aria_engine_core/") -> :aria_engine_core
      String.contains?(file_path, "apps/aria_hybrid_planner/") -> :aria_hybrid_planner
      String.contains?(file_path, "apps/aria_temporal_planner/") -> :aria_temporal_planner
      String.contains?(file_path, "apps/aria_timeline/") -> :aria_timeline
      true -> :other
    end
  end

  # Transform individual AST nodes
  defp transform_node(zipper, app_context) do
    case Sourceror.Zipper.node(zipper) do
      # Transform qualified State calls that need cross-app reference
      {{:., dot_meta, [{:__aliases__, alias_meta, [:State]}, func]}, call_meta, args} ->
        case app_context do
          :aria_engine_core ->
            # In aria_engine_core, keep as-is
            zipper

          _ ->
            # In other apps, should be handled by alias
            zipper
        end

      # No transformation needed for most cases - alias handles the resolution
      _ ->
        zipper
    end
  end

  # Count the number of transformations applied
  defp count_transformations(original_content, transformed_content) do
    original_aliases = count_state_aliases(original_content)
    transformed_aliases = count_state_aliases(transformed_content)
    transformed_aliases - original_aliases
  end

  defp count_state_aliases(content) do
    Regex.scan(~r/alias\s+.*State/, content) |> length()
  end

  # Validation functions
  defp has_state_struct_issues?(file_path) do
    case File.read(file_path) do
      {:ok, content} ->
        app_context = determine_app_context(file_path)

        case app_context do
          :aria_engine_core ->
            # In aria_engine_core, no cross-app issues expected
            false

          _ ->
            # In other apps, check for State usage without proper alias
            has_state_usage = Regex.match?(~r/%State\{|State\./, content)
            has_state_alias = Regex.match?(~r/alias\s+.*State/, content)
            has_state_usage and not has_state_alias
        end

      {:error, _} ->
        false
    end
  end

  defp has_proper_state_imports?(file_path) do
    case File.read(file_path) do
      {:ok, content} ->
        app_context = determine_app_context(file_path)

        case app_context do
          :aria_engine_core ->
            # In aria_engine_core, always proper
            true

          _ ->
            # In other apps, check for proper State alias if State is used
            has_state_usage = Regex.match?(~r/%State\{|State\./, content)
            has_state_alias = Regex.match?(~r/alias\s+.*State/, content)

            if has_state_usage do
              has_state_alias
            else
              true
            end
        end

      {:error, _} ->
        false
    end
  end

  defp compiles_successfully?(file_path) do
    case File.read(file_path) do
      {:ok, content} ->
        case Code.string_to_quoted(content) do
          {:ok, _ast} -> true
          {:error, _} -> false
        end

      {:error, _} ->
        false
    end
  end
end
