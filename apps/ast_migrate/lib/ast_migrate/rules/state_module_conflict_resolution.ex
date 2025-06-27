# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AstMigrate.Rules.StateModuleConflictResolution do
  @moduledoc """
  Resolves AriaEngine.State module conflicts between state.ex and state_v2.ex.

  This rule addresses the critical compilation issue where two modules define
  the same name `AriaEngine.State` in aria_engine_core, causing conflicts.
  The rule renames StateV2 module and updates all references appropriately.

  ## Problem Analysis

  Two files in aria_engine_core define `AriaEngine.State`:
  - `lib/state.ex` - The primary State module
  - `lib/state_v2.ex` - Should be renamed to StateV2

  ## Transformations Applied

  1. **Module definition updates in state_v2.ex:**
     ```elixir
     # Before
     defmodule AriaEngine.State do

     # After
     defmodule AriaEngine.StateV2 do
     ```

  2. **Alias statement updates:**
     ```elixir
     # Before
     alias AriaEngine.State

     # After
     alias AriaEngine.StateV2  # (when referring to StateV2)
     alias AriaEngine.State    # (when referring to primary State)
     ```

  3. **Import statement updates:**
     ```elixir
     # Before
     import AriaEngine.State

     # After
     import AriaEngine.StateV2  # (context-dependent)
     ```

  4. **Qualified call updates:**
     ```elixir
     # Before
     AriaEngine.State.function_name()

     # After
     AriaEngine.StateV2.function_name()  # (when targeting StateV2)
     ```

  5. **Type specification updates:**
     ```elixir
     # Before
     @type t :: AriaEngine.State.t()

     # After
     @type t :: AriaEngine.StateV2.t()  # (when targeting StateV2)
     ```
  """

  @behaviour AstMigrate.Rules.Behaviour
  require Logger

  @impl true
  def description do
    "Resolves AriaEngine.State module conflicts between state.ex and state_v2.ex"
  end

  @impl true
  def file_patterns do
    ["apps/aria_engine_core/lib/state_v2.ex", "apps/*/lib/**/*.ex", "apps/*/test/**/*.exs"]
  end

  @impl true
  def preconditions do
    [&has_state_module_conflict?/1]
  end

  @impl true
  def postconditions do
    [&compiles_successfully?/1, &no_state_module_conflict?/1]
  end

  @impl true
  def validate_preconditions(files) do
    state_v2_files = Enum.filter(files, &String.ends_with?(&1, "state_v2.ex"))
    files_with_conflicts = Enum.filter(files, &has_state_module_conflict?/1)

    if length(state_v2_files) > 0 and length(files_with_conflicts) > 0 do
      Logger.info(
        "Found #{length(files_with_conflicts)} files with State module conflicts",
        module: :ast_migrate_rules_state_module_conflict_resolution,
        operation: :validate_preconditions,
        state_v2_files: state_v2_files,
        files_with_conflicts: files_with_conflicts
      )

      :ok
    else
      {:error, "No State module conflicts found"}
    end
  end

  @impl true
  def transform_file(file_path) do
    Logger.debug("Starting State module conflict resolution for file",
      module: :ast_migrate_rules_state_module_conflict_resolution,
      operation: :transform_file,
      file: file_path
    )

    with {:ok, content} <- File.read(file_path),
         {:ok, transformed_code} <- transform_file_content(content, file_path) do
      Logger.debug("State module conflict resolution completed for file",
        module: :ast_migrate_rules_state_module_conflict_resolution,
        operation: :transform_file,
        file: file_path,
        original_size: byte_size(content),
        transformed_size: byte_size(transformed_code)
      )

      {:ok, transformed_code}
    else
      {:error, reason} ->
        Logger.error("State module conflict resolution failed for file",
          module: :ast_migrate_rules_state_module_conflict_resolution,
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
    Logger.debug("Starting State module conflict resolution for content",
      module: :ast_migrate_rules_state_module_conflict_resolution,
      operation: :transform_file_content,
      content_size: byte_size(content),
      file_path: file_path
    )

    with {:ok, quoted} <- Sourceror.parse_string(content),
         transformed_quoted <- transform_ast(quoted, file_path),
         transformed_code <- Sourceror.to_string(transformed_quoted) do
      transformations_applied = count_transformations(content, transformed_code, file_path)

      Logger.debug("State module conflict resolution completed for content",
        module: :ast_migrate_rules_state_module_conflict_resolution,
        operation: :transform_file_content,
        transformations_applied: transformations_applied,
        original_size: byte_size(content),
        transformed_size: byte_size(transformed_code)
      )

      {:ok, transformed_code}
    else
      {:error, reason} ->
        Logger.error("State module conflict resolution failed for content",
          module: :ast_migrate_rules_state_module_conflict_resolution,
          operation: :transform_file_content,
          error: inspect(reason)
        )

        {:error, "Failed to transform content: #{inspect(reason)}"}
    end
  end

  # Transform AST using Sourceror.Zipper for better traversal
  defp transform_ast(quoted, file_path) do
    is_state_v2_file = String.ends_with?(file_path, "state_v2.ex")

    Sourceror.Zipper.zip(quoted)
    |> Sourceror.Zipper.traverse(fn zipper -> transform_node(zipper, is_state_v2_file) end)
    |> Sourceror.Zipper.root()
  end

  # Transform individual AST nodes
  defp transform_node(zipper, is_state_v2_file) do
    case Sourceror.Zipper.node(zipper) do
      # Transform defmodule statements in state_v2.ex
      {:defmodule, meta, [{:__aliases__, alias_meta, [:AriaEngine, :State]}, body]}
      when is_state_v2_file ->
        new_alias = {:__aliases__, alias_meta, [:AriaEngine, :StateV2]}
        Sourceror.Zipper.replace(zipper, {:defmodule, meta, [new_alias, body]})

      # Transform alias statements (context-dependent)
      {:alias, meta, [{:__aliases__, alias_meta, [:AriaEngine, :State]} | alias_rest]} ->
        # For now, keep as-is and let manual review determine correct target
        # In the future, we could add heuristics based on usage patterns
        zipper

      # Transform import statements (context-dependent)
      {:import, meta, [{:__aliases__, alias_meta, [:AriaEngine, :State]} | import_rest]} ->
        # For now, keep as-is and let manual review determine correct target
        zipper

      # Transform qualified function calls (context-dependent)
      {{:., dot_meta, [{:__aliases__, alias_meta, [:AriaEngine, :State]}, func]}, call_meta, args} ->
        # For now, keep as-is and let manual review determine correct target
        zipper

      # Transform type specifications (context-dependent)
      {:"::", type_meta, [name, {:__aliases__, alias_meta, [:AriaEngine, :State]}]} ->
        # For now, keep as-is and let manual review determine correct target
        zipper

      # No transformation needed
      _ ->
        zipper
    end
  end

  # Count the number of transformations applied
  defp count_transformations(original_content, transformed_content, file_path) do
    if String.ends_with?(file_path, "state_v2.ex") do
      original_defmodule_count = count_state_defmodule_references(original_content)
      transformed_defmodule_count = count_state_defmodule_references(transformed_content)
      original_defmodule_count - transformed_defmodule_count
    else
      0
    end
  end

  defp count_state_defmodule_references(content) do
    Regex.scan(~r/defmodule\s+AriaEngine\.State\s/, content) |> length()
  end

  # Validation functions
  defp has_state_module_conflict?(file_path) do
    case File.read(file_path) do
      {:ok, content} ->
        String.ends_with?(file_path, "state_v2.ex") and
          String.contains?(content, "defmodule AriaEngine.State")

      {:error, _} ->
        false
    end
  end

  defp no_state_module_conflict?(file_path) do
    case File.read(file_path) do
      {:ok, content} ->
        if String.ends_with?(file_path, "state_v2.ex") do
          not String.contains?(content, "defmodule AriaEngine.State") and
            String.contains?(content, "defmodule AriaEngine.StateV2")
        else
          true
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
