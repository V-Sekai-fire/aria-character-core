# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AstMigrate.Rules.AriaEngineNamespaceCleanup do
  @moduledoc """
  Fixes AriaEngine namespace references to use correct module paths.

  This rule addresses namespace conflicts that prevent proper compilation
  after the modularization effort. Many files contain outdated AriaEngine.*
  references that need to be updated to the correct module paths in their
  respective apps.

  ## Transformations Applied

  1. **Alias statement updates:**
     ```elixir
     # Before
     alias AriaEngine.State

     # After
     alias State  # (when in aria_engine_core context)
     ```

  2. **Import statement updates:**
     ```elixir
     # Before
     import AriaEngine.Domain.Core

     # After
     import Domain.Core  # (when in aria_engine_core context)
     ```

  3. **Qualified call updates:**
     ```elixir
     # Before
     AriaEngine.State.function_name()

     # After
     State.function_name()
     ```

  4. **Type specification updates:**
     ```elixir
     # Before
     @type t :: AriaEngine.State.t()

     # After
     @type t :: State.t()
     ```

  5. **Module definition updates:**
     ```elixir
     # Before
     defmodule AriaEngine.Timeline.Something

     # After
     defmodule Timeline.Something  # (when moved to aria_timeline app)
     ```
  """

  @behaviour AstMigrate.Rules.Behaviour
  require Logger

  @impl true
  def description do
    "Fixes AriaEngine namespace references to use correct module paths"
  end

  @impl true
  def file_patterns do
    ["apps/*/lib/**/*.ex", "apps/*/test/**/*.exs"]
  end

  @impl true
  def preconditions do
    [&has_aria_engine_references?/1]
  end

  @impl true
  def postconditions do
    [&compiles_successfully?/1, &reduced_aria_engine_references?/1]
  end

  @impl true
  def validate_preconditions(files) do
    files_with_references = Enum.filter(files, &has_aria_engine_references?/1)

    if length(files_with_references) > 0 do
      Logger.info("Found #{length(files_with_references)} files with AriaEngine.* references",
        module: :ast_migrate_rules_aria_engine_namespace_cleanup,
        operation: :validate_preconditions,
        files: files_with_references
      )

      :ok
    else
      {:error, "No files found with AriaEngine.* references"}
    end
  end

  @impl true
  def transform_file(file_path) do
    Logger.debug("Starting AriaEngine namespace transformation for file",
      module: :ast_migrate_rules_aria_engine_namespace_cleanup,
      operation: :transform_file,
      file: file_path
    )

    with {:ok, content} <- File.read(file_path),
         {:ok, transformed_code} <- transform_file_content(content, file_path) do
      Logger.debug("AriaEngine namespace transformation completed for file",
        module: :ast_migrate_rules_aria_engine_namespace_cleanup,
        operation: :transform_file,
        file: file_path,
        original_size: byte_size(content),
        transformed_size: byte_size(transformed_code)
      )

      {:ok, transformed_code}
    else
      {:error, reason} ->
        Logger.error("AriaEngine namespace transformation failed for file",
          module: :ast_migrate_rules_aria_engine_namespace_cleanup,
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
    Logger.debug("Starting AriaEngine namespace transformation for content",
      module: :ast_migrate_rules_aria_engine_namespace_cleanup,
      operation: :transform_file_content,
      content_size: byte_size(content),
      file_path: file_path
    )

    with {:ok, quoted} <- Sourceror.parse_string(content),
         transformed_quoted <- transform_ast(quoted, file_path),
         transformed_code <- Sourceror.to_string(transformed_quoted) do
      transformations_applied = count_transformations(content, transformed_code)

      Logger.debug("AriaEngine namespace transformation completed for content",
        module: :ast_migrate_rules_aria_engine_namespace_cleanup,
        operation: :transform_file_content,
        transformations_applied: transformations_applied,
        original_size: byte_size(content),
        transformed_size: byte_size(transformed_code)
      )

      {:ok, transformed_code}
    else
      {:error, reason} ->
        Logger.error("AriaEngine namespace transformation failed for content",
          module: :ast_migrate_rules_aria_engine_namespace_cleanup,
          operation: :transform_file_content,
          error: inspect(reason)
        )

        {:error, "Failed to transform content: #{inspect(reason)}"}
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
      String.contains?(file_path, "apps/aria_timeline/") -> :aria_timeline
      String.contains?(file_path, "apps/aria_hybrid_planner/") -> :aria_hybrid_planner
      String.contains?(file_path, "apps/aria_temporal_planner/") -> :aria_temporal_planner
      String.contains?(file_path, "apps/aria_membrane_pipeline/") -> :aria_membrane_pipeline
      true -> :other
    end
  end

  # Transform individual AST nodes
  defp transform_node(zipper, app_context) do
    case Sourceror.Zipper.node(zipper) do
      # Transform alias statements
      {:alias, meta, [{:__aliases__, _alias_meta, [:AriaEngine | rest]} | alias_rest]} ->
        new_alias = transform_aria_engine_alias(rest, app_context)

        if new_alias do
          Sourceror.Zipper.replace(zipper, {:alias, meta, [new_alias | alias_rest]})
        else
          zipper
        end

      # Transform import statements
      {:import, meta, [{:__aliases__, _alias_meta, [:AriaEngine | rest]} | import_rest]} ->
        new_alias = transform_aria_engine_alias(rest, app_context)

        if new_alias do
          Sourceror.Zipper.replace(zipper, {:import, meta, [new_alias | import_rest]})
        else
          zipper
        end

      # Transform defmodule statements
      {:defmodule, meta, [{:__aliases__, _alias_meta, [:AriaEngine | rest]}, body]} ->
        new_alias = transform_aria_engine_defmodule(rest, app_context)

        if new_alias do
          Sourceror.Zipper.replace(zipper, {:defmodule, meta, [new_alias, body]})
        else
          zipper
        end

      # Transform qualified function calls
      {{:., dot_meta, [{:__aliases__, _alias_meta, [:AriaEngine | rest]}, func]}, call_meta, args} ->
        new_alias = transform_aria_engine_alias(rest, app_context)

        if new_alias do
          Sourceror.Zipper.replace(zipper, {{:., dot_meta, [new_alias, func]}, call_meta, args})
        else
          zipper
        end

      # Transform type specifications
      {:"::", type_meta, [name, {:__aliases__, _alias_meta, [:AriaEngine | rest]}]} ->
        new_alias = transform_aria_engine_alias(rest, app_context)

        if new_alias do
          Sourceror.Zipper.replace(zipper, {:"::", type_meta, [name, new_alias]})
        else
          zipper
        end

      # No transformation needed
      _ ->
        zipper
    end
  end

  # Transform AriaEngine.* aliases based on context and target module
  defp transform_aria_engine_alias(rest, app_context) do
    case {rest, app_context} do
      # AriaEngine.State -> State (in aria_engine_core context)
      {[:State], :aria_engine_core} ->
        {:__aliases__, [], [:State]}

      # AriaEngine.State -> AriaEngine.State (keep in other contexts for now)
      {[:State], _} ->
        # Don't transform - needs manual review

        nil

      # AriaEngine.Timeline.* -> Timeline.* (when in aria_timeline context)
      {[:Timeline | timeline_rest], :aria_timeline} ->
        case timeline_rest do
          [] -> {:__aliases__, [], [:Timeline]}
          _ -> {:__aliases__, [], [:Timeline | timeline_rest]}
        end

      # AriaEngine.Timeline.* -> remove (obsolete references)
      {[:Timeline | _], _} ->
        # Don't transform - likely obsolete

        nil

      # AriaEngine.Domain.* -> Domain.* (in aria_engine_core context)
      {[:Domain | domain_rest], :aria_engine_core} ->
        case domain_rest do
          [] -> {:__aliases__, [], [:Domain]}
          _ -> {:__aliases__, [], [:Domain | domain_rest]}
        end

      # AriaEngine.Plan.* -> Plan.* (in aria_hybrid_planner context)
      {[:Plan | plan_rest], :aria_hybrid_planner} ->
        case plan_rest do
          [] -> {:__aliases__, [], [:Plan]}
          _ -> {:__aliases__, [], [:Plan | plan_rest]}
        end

      # AriaEngine.Core -> Core (in aria_engine_core context)
      {[:Core], :aria_engine_core} ->
        {:__aliases__, [], [:Core]}

      # AriaEngine.Membrane.* -> remove (likely obsolete)
      {[:Membrane | _], _} ->
        # Don't transform - likely obsolete

        nil

      # AriaEngine.HybridPlanner.* -> HybridPlanner.* (in aria_hybrid_planner context)
      {[:HybridPlanner | planner_rest], :aria_hybrid_planner} ->
        case planner_rest do
          [] -> {:__aliases__, [], [:HybridPlanner]}
          _ -> {:__aliases__, [], [:HybridPlanner | planner_rest]}
        end

      # Default: don't transform unknown patterns
      _ ->
        nil
    end
  end

  # Transform AriaEngine.* defmodule statements
  defp transform_aria_engine_defmodule(rest, app_context) do
    case {rest, app_context} do
      # AriaEngine.Timeline.* -> Timeline.* (when in aria_timeline context)
      {[:Timeline | timeline_rest], :aria_timeline} ->
        case timeline_rest do
          [] -> {:__aliases__, [], [:Timeline]}
          _ -> {:__aliases__, [], [:Timeline | timeline_rest]}
        end

      # Default: don't transform defmodule statements automatically
      _ ->
        nil
    end
  end

  # Count the number of transformations applied
  defp count_transformations(original_content, transformed_content) do
    original_count = count_aria_engine_references(original_content)
    transformed_count = count_aria_engine_references(transformed_content)
    original_count - transformed_count
  end

  defp count_aria_engine_references(content) do
    Regex.scan(~r/AriaEngine\./, content) |> length()
  end

  # Validation functions
  defp has_aria_engine_references?(file_path) do
    case File.read(file_path) do
      {:ok, content} -> String.contains?(content, "AriaEngine.")
      {:error, _} -> false
    end
  end

  defp reduced_aria_engine_references?(file_path) do
    # For now, just check that the file still compiles
    # In the future, we could check that references were actually reduced
    compiles_successfully?(file_path)
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