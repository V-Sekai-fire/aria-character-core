# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AstMigrate.Rules.TimelineNamespaceFixes do
  @moduledoc """
  Fixes timeline namespace references from AriaEngine.Timeline to Timeline.

  This rule addresses namespace conflicts that prevent proper test execution
  after the modularization effort in ADR-151. Timeline test files contain
  outdated AriaEngine.Timeline references that need to be updated to the
  correct Timeline namespace in the aria_temporal_planner app.

  ## Transformations Applied

  1. **Module name updates:**
     ```elixir
     # Before
     defmodule AriaEngine.Timeline.IntervalISO8601Test do

     # After
     defmodule Timeline.IntervalISO8601Test do
     ```

  2. **Alias statement updates:**
     ```elixir
     # Before
     alias AriaEngine.Timeline.Bridge

     # After
     alias Timeline.Bridge
     ```

  3. **Import statement updates:**
     ```elixir
     # Before
     import AriaEngine.Timeline

     # After
     import Timeline
     ```

  4. **Doctest reference updates:**
     ```elixir
     # Before
     doctest AriaEngine.Timeline.Bridge

     # After
     doctest Timeline.Bridge
     ```

  5. **Qualified call updates:**
     ```elixir
     # Before
     AriaEngine.Timeline.function_name()

     # After
     Timeline.function_name()
     ```
  """

  @behaviour AstMigrate.Rules.Behaviour
  require Logger

  @impl true
  def description do
    "Fixes timeline namespace references from AriaEngine.Timeline to Timeline"
  end

  @impl true
  def file_patterns do
    ["apps/aria_temporal_planner/test/**/*.exs"]
  end

  @impl true
  def preconditions do
    [&has_aria_engine_timeline_references?/1]
  end

  @impl true
  def postconditions do
    [&compiles_successfully?/1, &no_aria_engine_timeline_references?/1]
  end

  @impl true
  def validate_preconditions(files) do
    files_with_references = Enum.filter(files, &has_aria_engine_timeline_references?/1)

    if length(files_with_references) > 0 do
      Logger.info("Found #{length(files_with_references)} files with AriaEngine.Timeline references",
        module: :ast_migrate_rules_timeline_namespace_fixes,
        operation: :validate_preconditions,
        files: files_with_references
      )
      :ok
    else
      {:error, "No files found with AriaEngine.Timeline references"}
    end
  end

  @impl true
  def transform_file(file_path) do
    Logger.debug("Starting timeline namespace transformation for file",
      module: :ast_migrate_rules_timeline_namespace_fixes,
      operation: :transform_file,
      file: file_path
    )

    with {:ok, content} <- File.read(file_path),
         {:ok, transformed_code} <- transform_file_content(content) do
      Logger.debug("Timeline namespace transformation completed for file",
        module: :ast_migrate_rules_timeline_namespace_fixes,
        operation: :transform_file,
        file: file_path,
        original_size: byte_size(content),
        transformed_size: byte_size(transformed_code)
      )

      {:ok, transformed_code}
    else
      {:error, reason} ->
        Logger.error("Timeline namespace transformation failed for file",
          module: :ast_migrate_rules_timeline_namespace_fixes,
          operation: :transform_file,
          file: file_path,
          error: inspect(reason)
        )

        {:error, "Failed to transform #{file_path}: #{inspect(reason)}"}
    end
  end

  @doc "Transform file content directly."
  @spec transform_file_content(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def transform_file_content(content) do
    Logger.debug("Starting timeline namespace transformation for content",
      module: :ast_migrate_rules_timeline_namespace_fixes,
      operation: :transform_file_content,
      content_size: byte_size(content)
    )

    with {:ok, quoted} <- Sourceror.parse_string(content),
         transformed_quoted <- transform_ast(quoted),
         transformed_code <- Sourceror.to_string(transformed_quoted) do
      transformations_applied = count_transformations(content, transformed_code)

      Logger.debug("Timeline namespace transformation completed for content",
        module: :ast_migrate_rules_timeline_namespace_fixes,
        operation: :transform_file_content,
        transformations_applied: transformations_applied,
        original_size: byte_size(content),
        transformed_size: byte_size(transformed_code)
      )

      {:ok, transformed_code}
    else
      {:error, reason} ->
        Logger.error("Timeline namespace transformation failed for content",
          module: :ast_migrate_rules_timeline_namespace_fixes,
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
      # Transform defmodule statements
      {:defmodule, meta, [{:__aliases__, alias_meta, [:AriaEngine, :Timeline | rest]}, body]} ->
        new_alias = case rest do
          [] -> {:__aliases__, alias_meta, [:Timeline]}
          _ -> {:__aliases__, alias_meta, [:Timeline | rest]}
        end
        Sourceror.Zipper.replace(zipper, {:defmodule, meta, [new_alias, body]})

      # Transform alias statements
      {:alias, meta, [{:__aliases__, alias_meta, [:AriaEngine, :Timeline | rest]} | alias_rest]} ->
        new_alias = case rest do
          [] -> {:__aliases__, alias_meta, [:Timeline]}
          _ -> {:__aliases__, alias_meta, [:Timeline | rest]}
        end
        Sourceror.Zipper.replace(zipper, {:alias, meta, [new_alias | alias_rest]})

      # Transform import statements
      {:import, meta, [{:__aliases__, alias_meta, [:AriaEngine, :Timeline | rest]} | import_rest]} ->
        new_alias = case rest do
          [] -> {:__aliases__, alias_meta, [:Timeline]}
          _ -> {:__aliases__, alias_meta, [:Timeline | rest]}
        end
        Sourceror.Zipper.replace(zipper, {:import, meta, [new_alias | import_rest]})

      # Transform doctest statements
      {:doctest, meta, [{:__aliases__, alias_meta, [:AriaEngine, :Timeline | rest]} | doctest_rest]} ->
        new_alias = case rest do
          [] -> {:__aliases__, alias_meta, [:Timeline]}
          _ -> {:__aliases__, alias_meta, [:Timeline | rest]}
        end
        Sourceror.Zipper.replace(zipper, {:doctest, meta, [new_alias | doctest_rest]})

      # Transform qualified function calls
      {{:., dot_meta, [{:__aliases__, alias_meta, [:AriaEngine, :Timeline | rest]}, func]}, call_meta, args} ->
        new_alias = case rest do
          [] -> {:__aliases__, alias_meta, [:Timeline]}
          _ -> {:__aliases__, alias_meta, [:Timeline | rest]}
        end
        Sourceror.Zipper.replace(zipper, {{:., dot_meta, [new_alias, func]}, call_meta, args})

      # No transformation needed
      _ ->
        zipper
    end
  end

  # Count the number of transformations applied
  defp count_transformations(original_content, transformed_content) do
    original_count = count_aria_engine_timeline_references(original_content)
    transformed_count = count_aria_engine_timeline_references(transformed_content)
    original_count - transformed_count
  end

  defp count_aria_engine_timeline_references(content) do
    Regex.scan(~r/AriaEngine\.Timeline/, content) |> length()
  end

  # Validation functions
  defp has_aria_engine_timeline_references?(file_path) do
    case File.read(file_path) do
      {:ok, content} -> String.contains?(content, "AriaEngine.Timeline")
      {:error, _} -> false
    end
  end

  defp no_aria_engine_timeline_references?(file_path) do
    case File.read(file_path) do
      {:ok, content} -> not String.contains?(content, "AriaEngine.Timeline")
      {:error, _} -> false
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
