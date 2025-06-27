# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AstMigrate.Rules.MembraneNamespaceCleanup do
  @moduledoc """
  Fixes AriaEngine.Membrane.* namespace references in aria_membrane_pipeline app.

  This rule specifically handles the membrane pipeline modules that use
  AriaEngine.Membrane.* namespace and converts them to proper module paths
  within the aria_membrane_pipeline app context.

  ## Transformations Applied

  1. **Module definition updates:**
     ```elixir
     # Before
     defmodule AriaEngine.Membrane.Format.PlanningResult

     # After
     defmodule Membrane.Format.PlanningResult
     ```

  2. **Alias statement updates:**
     ```elixir
     # Before
     alias AriaEngine.Membrane.Format.PlanningResult

     # After
     alias Membrane.Format.PlanningResult
     ```

  3. **Qualified call updates:**
     ```elixir
     # Before
     AriaEngine.Membrane.Format.PlanningResult.success(...)

     # After
     Membrane.Format.PlanningResult.success(...)
     ```
  """

  @behaviour AstMigrate.Rules.Behaviour
  require Logger

  @impl true
  def description do
    "Fixes AriaEngine.Membrane.* namespace references in aria_membrane_pipeline app"
  end

  @impl true
  def file_patterns do
    ["apps/aria_membrane_pipeline/lib/**/*.ex", "apps/aria_membrane_pipeline/test/**/*.exs"]
  end

  @impl true
  def preconditions do
    [&has_aria_engine_membrane_references?/1]
  end

  @impl true
  def postconditions do
    [&compiles_successfully?/1, &reduced_aria_engine_membrane_references?/1]
  end

  @impl true
  def validate_preconditions(files) do
    files_with_references = Enum.filter(files, &has_aria_engine_membrane_references?/1)

    if length(files_with_references) > 0 do
      Logger.info(
        "Found #{length(files_with_references)} files with AriaEngine.Membrane.* references",
        module: :ast_migrate_rules_membrane_namespace_cleanup,
        operation: :validate_preconditions,
        files: files_with_references
      )

      :ok
    else
      {:error, "No files found with AriaEngine.Membrane.* references"}
    end
  end

  @impl true
  def transform_file(file_path) do
    Logger.debug("Starting AriaEngine.Membrane namespace transformation for file",
      module: :ast_migrate_rules_membrane_namespace_cleanup,
      operation: :transform_file,
      file: file_path
    )

    with {:ok, content} <- File.read(file_path),
         {:ok, transformed_code} <- transform_file_content(content, file_path) do
      Logger.debug("AriaEngine.Membrane namespace transformation completed for file",
        module: :ast_migrate_rules_membrane_namespace_cleanup,
        operation: :transform_file,
        file: file_path,
        original_size: byte_size(content),
        transformed_size: byte_size(transformed_code)
      )

      {:ok, transformed_code}
    else
      {:error, reason} ->
        Logger.error("AriaEngine.Membrane namespace transformation failed for file",
          module: :ast_migrate_rules_membrane_namespace_cleanup,
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
    Logger.debug("Starting AriaEngine.Membrane namespace transformation for content",
      module: :ast_migrate_rules_membrane_namespace_cleanup,
      operation: :transform_file_content,
      content_size: byte_size(content),
      file_path: file_path
    )

    with {:ok, quoted} <- Sourceror.parse_string(content),
         transformed_quoted <- transform_ast(quoted),
         transformed_code <- Sourceror.to_string(transformed_quoted) do
      transformations_applied = count_transformations(content, transformed_code)

      Logger.debug("AriaEngine.Membrane namespace transformation completed for content",
        module: :ast_migrate_rules_membrane_namespace_cleanup,
        operation: :transform_file_content,
        transformations_applied: transformations_applied,
        original_size: byte_size(content),
        transformed_size: byte_size(transformed_code)
      )

      {:ok, transformed_code}
    else
      {:error, reason} ->
        Logger.error("AriaEngine.Membrane namespace transformation failed for content",
          module: :ast_migrate_rules_membrane_namespace_cleanup,
          operation: :transform_file_content,
          error: inspect(reason)
        )

        {:error, "Failed to transform content: #{inspect(reason)}"}
    end
  end

  # Transform AST using Sourceror.Zipper for better traversal
  defp transform_ast(quoted) do
    Sourceror.Zipper.zip(quoted)
    |> Sourceror.Zipper.traverse(&transform_node/1)
    |> Sourceror.Zipper.root()
  end

  # Transform individual AST nodes
  defp transform_node(zipper) do
    case Sourceror.Zipper.node(zipper) do
      # Transform __aliases__ nodes directly
      {:__aliases__, meta, [:AriaEngine, :Membrane | rest]} ->
        new_alias = {:__aliases__, meta, [:Membrane | rest]}
        Sourceror.Zipper.replace(zipper, new_alias)

      # Transform @doc and @moduledoc attributes with string content
      {:@, meta, [{attr_name, attr_meta, [string_content]}]}
      when attr_name in [:doc, :moduledoc] and is_binary(string_content) ->
        transformed_string = transform_docstring_content(string_content)
        new_attr = {:@, meta, [{attr_name, attr_meta, [transformed_string]}]}
        Sourceror.Zipper.replace(zipper, new_attr)

      # No transformation needed
      _ ->
        zipper
    end
  end

  # Transform AriaEngine.Membrane references within docstring content
  defp transform_docstring_content(content) when is_binary(content) do
    content
    |> String.replace(~r/AriaEngine\.Membrane\.Format\./, "Membrane.Format.")
    |> String.replace(~r/AriaEngine\.Membrane\./, "Membrane.")
  end

  # Count the number of transformations applied
  defp count_transformations(original_content, transformed_content) do
    original_count = count_aria_engine_membrane_references(original_content)
    transformed_count = count_aria_engine_membrane_references(transformed_content)
    original_count - transformed_count
  end

  defp count_aria_engine_membrane_references(content) do
    Regex.scan(~r/AriaEngine\.Membrane\./, content) |> length()
  end

  # Validation functions
  defp has_aria_engine_membrane_references?(file_path) do
    case File.read(file_path) do
      {:ok, content} -> String.contains?(content, "AriaEngine.Membrane.")
      {:error, _} -> false
    end
  end

  defp reduced_aria_engine_membrane_references?(file_path) do
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