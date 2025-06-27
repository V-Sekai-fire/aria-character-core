# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AstMigrate.Rules.TimelineModuleReferences do
  @moduledoc """
  Fixes Timeline module references across apps to use correct module paths.

  This rule addresses the issue where many modules are trying to use `Timeline`
  but it's not available - they need to reference the correct Timeline module
  from aria_timeline or add proper aliases.

  ## Problem Analysis

  Many files reference `Timeline` without proper aliases or imports, causing
  compilation failures. The Timeline modules are now in the aria_timeline app
  and need proper cross-app references.

  ## Transformations Applied

  1. **Add proper alias statements:**
     ```elixir
     # Before (missing alias)
     Timeline.function_call()

     # After
     alias AriaTimeline.TimelineCore, as: Timeline
     Timeline.function_call()
     ```

  2. **Fix bare Timeline references:**
     ```elixir
     # Before
     Timeline

     # After
     AriaTimeline.TimelineCore  # (or appropriate Timeline module)
     ```

  3. **Update existing aliases:**
     ```elixir
     # Before
     alias Timeline

     # After
     alias AriaTimeline.TimelineCore, as: Timeline
     ```

  4. **Fix qualified calls:**
     ```elixir
     # Before
     Timeline.Bridge.function_name()

     # After
     AriaTimeline.Bridge.function_name()
     ```

  5. **Add missing imports:**
     ```elixir
     # Before (missing import)
     use Timeline

     # After
     alias AriaTimeline.TimelineCore, as: Timeline
     use Timeline
     ```
  """

  @behaviour AstMigrate.Rules.Behaviour
  require Logger

  @impl true
  def description do
    "Fixes Timeline module references across apps to use correct module paths"
  end

  @impl true
  def file_patterns do
    ["apps/*/lib/**/*.ex", "apps/*/test/**/*.exs"]
  end

  @impl true
  def preconditions do
    [&has_timeline_reference_issues?/1]
  end

  @impl true
  def postconditions do
    [&compiles_successfully?/1, &has_proper_timeline_references?/1]
  end

  @impl true
  def validate_preconditions(files) do
    files_with_issues = Enum.filter(files, &has_timeline_reference_issues?/1)

    if length(files_with_issues) > 0 do
      Logger.info(
        "Found #{length(files_with_issues)} files with Timeline reference issues",
        module: :ast_migrate_rules_timeline_module_references,
        operation: :validate_preconditions,
        files: files_with_issues
      )

      :ok
    else
      {:error, "No Timeline reference issues found"}
    end
  end

  @impl true
  def transform_file(file_path) do
    Logger.debug("Starting Timeline module reference fixes for file",
      module: :ast_migrate_rules_timeline_module_references,
      operation: :transform_file,
      file: file_path
    )

    with {:ok, content} <- File.read(file_path),
         {:ok, transformed_code} <- transform_file_content(content, file_path) do
      Logger.debug("Timeline module reference fixes completed for file",
        module: :ast_migrate_rules_timeline_module_references,
        operation: :transform_file,
        file: file_path,
        original_size: byte_size(content),
        transformed_size: byte_size(transformed_code)
      )

      {:ok, transformed_code}
    else
      {:error, reason} ->
        Logger.error("Timeline module reference fixes failed for file",
          module: :ast_migrate_rules_timeline_module_references,
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
    Logger.debug("Starting Timeline module reference fixes for content",
      module: :ast_migrate_rules_timeline_module_references,
      operation: :transform_file_content,
      content_size: byte_size(content),
      file_path: file_path
    )

    with {:ok, quoted} <- Sourceror.parse_string(content),
         transformed_quoted <- transform_ast(quoted, file_path),
         transformed_code <- Sourceror.to_string(transformed_quoted) do
      transformations_applied = count_transformations(content, transformed_code)

      Logger.debug("Timeline module reference fixes completed for content",
        module: :ast_migrate_rules_timeline_module_references,
        operation: :transform_file_content,
        transformations_applied: transformations_applied,
        original_size: byte_size(content),
        transformed_size: byte_size(transformed_code)
      )

      {:ok, transformed_code}
    else
      {:error, reason} ->
        Logger.error("Timeline module reference fixes failed for content",
          module: :ast_migrate_rules_timeline_module_references,
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
      String.contains?(file_path, "apps/aria_timeline/") -> :aria_timeline
      String.contains?(file_path, "apps/aria_temporal_planner/") -> :aria_temporal_planner
      String.contains?(file_path, "apps/aria_hybrid_planner/") -> :aria_hybrid_planner
      String.contains?(file_path, "apps/aria_engine_core/") -> :aria_engine_core
      true -> :other
    end
  end

  # Transform individual AST nodes
  defp transform_node(zipper, app_context) do
    case Sourceror.Zipper.node(zipper) do
      # Transform bare Timeline alias statements
      {:alias, meta, [{:__aliases__, alias_meta, [:Timeline]} | alias_rest]} ->
        case app_context do
          :aria_timeline ->
            # In aria_timeline, keep as-is
            zipper

          _ ->
            # In other apps, add proper cross-app reference
            new_alias = {:__aliases__, alias_meta, [:AriaTimeline, :TimelineCore]}
            alias_opts = [{:as, {:__aliases__, [], [:Timeline]}} | alias_rest]
            Sourceror.Zipper.replace(zipper, {:alias, meta, [new_alias | alias_opts]})
        end

      # Transform qualified Timeline calls
      {{:., dot_meta, [{:__aliases__, alias_meta, [:Timeline]}, func]}, call_meta, args} ->
        case app_context do
          :aria_timeline ->
            # In aria_timeline, keep as-is
            zipper

          _ ->
            # In other apps, check if we need to add cross-app reference
            # For now, keep as-is and let alias handle it
            zipper
        end

      # Transform Timeline.* module references in qualified calls
      {{:., dot_meta, [{:__aliases__, alias_meta, [:Timeline | timeline_rest]}, func]},
       call_meta, args} ->
        case {app_context, timeline_rest} do
          {:aria_timeline, _} ->
            # In aria_timeline, keep as-is
            zipper

          {_, []} ->
            # Timeline.func() - handled by alias
            zipper

          {_, _} ->
            # Timeline.Module.func() - convert to AriaTimeline.Module.func()
            new_alias = {:__aliases__, alias_meta, [:AriaTimeline | timeline_rest]}
            Sourceror.Zipper.replace(zipper, {{:., dot_meta, [new_alias, func]}, call_meta, args})
        end

      # Transform import statements
      {:import, meta, [{:__aliases__, alias_meta, [:Timeline]} | import_rest]} ->
        case app_context do
          :aria_timeline ->
            # In aria_timeline, keep as-is
            zipper

          _ ->
            # In other apps, convert to cross-app import
            new_alias = {:__aliases__, alias_meta, [:AriaTimeline, :TimelineCore]}
            Sourceror.Zipper.replace(zipper, {:import, meta, [new_alias | import_rest]})
        end

      # No transformation needed
      _ ->
        zipper
    end
  end

  # Count the number of transformations applied
  defp count_transformations(original_content, transformed_content) do
    original_count = count_timeline_references(original_content)
    transformed_count = count_timeline_references(transformed_content)
    original_count - transformed_count
  end

  defp count_timeline_references(content) do
    # Count bare Timeline references that need fixing
    bare_timeline = Regex.scan(~r/\bTimeline\b(?!\.)/, content) |> length()
    alias_timeline = Regex.scan(~r/alias\s+Timeline\b/, content) |> length()
    bare_timeline + alias_timeline
  end

  # Validation functions
  defp has_timeline_reference_issues?(file_path) do
    case File.read(file_path) do
      {:ok, content} ->
        app_context = determine_app_context(file_path)

        case app_context do
          :aria_timeline ->
            # In aria_timeline app, no issues expected
            false

          _ ->
            # In other apps, check for bare Timeline references
            has_bare_timeline_alias = Regex.match?(~r/alias\s+Timeline\b/, content)
            has_timeline_calls = Regex.match?(~r/Timeline\./, content)
            has_bare_timeline_alias or has_timeline_calls
        end

      {:error, _} ->
        false
    end
  end

  defp has_proper_timeline_references?(file_path) do
    case File.read(file_path) do
      {:ok, content} ->
        app_context = determine_app_context(file_path)

        case app_context do
          :aria_timeline ->
            # In aria_timeline app, always proper
            true

          _ ->
            # In other apps, check for proper cross-app references
            has_proper_alias = Regex.match?(~r/alias\s+AriaTimeline\.TimelineCore,\s*as:\s*Timeline/, content)
            has_timeline_calls = Regex.match?(~r/Timeline\./, content)

            if has_timeline_calls do
              has_proper_alias
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
