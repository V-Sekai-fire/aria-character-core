# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AstMigrate.Rules.StateV2ToState do
  @moduledoc """
  Transforms StateV2 usage to State using Elixir AST pattern matching.

  This rule handles the following transformations:
  - %StateV2{} struct literals → %State{}
  - StateV2.function() calls → State.function()
  - alias AriaEngine.StateV2 → alias AriaEngine.State
  - alias AriaEngine.StateV2, as: S → alias AriaEngine.State, as: S

  ## Examples

  **Input:**
  ```elixir
  defmodule MyModule do
    alias AriaEngine.StateV2

    def process_state(data) do
      state = %StateV2{entities: data}
      StateV2.update(state, :status, :active)
    end
  end
  ```

  **Output:**
  ```elixir
  defmodule MyModule do
    alias AriaEngine.State

    def process_state(data) do
      state = %State{entities: data}
      State.update(state, :status, :active)
    end
  end
  ```
  """

  @behaviour AstMigrate.Rules.Behaviour

  require Logger

  @impl true
  def description do
    "Transforms StateV2 usage to State using AST pattern matching"
  end

  @impl true
  def file_patterns do
    ["lib/**/*.ex", "test/**/*.exs"]
  end

  @impl true
  def preconditions do
    [&has_state_v2_usage?/1]
  end

  @impl true
  def postconditions do
    [&valid_state_usage?/1, &compiles_successfully?/1]
  end

  @impl true
  def validate_preconditions(_files) do
    # For now, always allow transformation
    :ok
  end

  @impl true
  def transform_file(file_path) do
    Logger.debug("Starting AST transformation for file",
      module: :ast_migrate_rules_state_v2_to_state,
      operation: :transform_file,
      file: file_path
    )

    with {:ok, content} <- File.read(file_path),
         {:ok, transformed_code} <- transform_file_content(content) do

      Logger.debug("AST transformation completed for file",
        module: :ast_migrate_rules_state_v2_to_state,
        operation: :transform_file,
        file: file_path,
        original_size: byte_size(content),
        transformed_size: byte_size(transformed_code)
      )

      {:ok, transformed_code}
    else
      {:error, reason} ->
        Logger.error("AST transformation failed for file",
          module: :ast_migrate_rules_state_v2_to_state,
          operation: :transform_file,
          file: file_path,
          error: inspect(reason)
        )
        {:error, "Failed to transform #{file_path}: #{inspect(reason)}"}
    end
  end

  @doc """
  Transform file content directly (used by advanced rule system).
  """
  @spec transform_file_content(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def transform_file_content(content) do
    Logger.debug("Starting AST transformation for content",
      module: :ast_migrate_rules_state_v2_to_state,
      operation: :transform_file_content,
      content_size: byte_size(content)
    )

    with {:ok, ast} <- Code.string_to_quoted(content),
         transformed_ast <- transform_ast(ast),
         transformed_code <- Macro.to_string(transformed_ast) do

      transformations_applied = count_transformations(content, transformed_code)

      Logger.debug("AST transformation completed for content",
        module: :ast_migrate_rules_state_v2_to_state,
        operation: :transform_file_content,
        transformations_applied: transformations_applied,
        original_size: byte_size(content),
        transformed_size: byte_size(transformed_code)
      )

      {:ok, transformed_code}
    else
      {:error, reason} ->
        Logger.error("AST transformation failed for content",
          module: :ast_migrate_rules_state_v2_to_state,
          operation: :transform_file_content,
          error: inspect(reason)
        )
        {:error, "Failed to transform content: #{inspect(reason)}"}
    end
  end

  # AST transformation functions

  # Transform StateV2 struct usage: %StateV2{} -> %State{}
  defp transform_ast({:%, meta, [{:__aliases__, alias_meta, [:StateV2]}, fields]}) do
    {:%, meta, [{:__aliases__, alias_meta, [:State]}, fields]}
  end

  # Transform fully qualified StateV2 struct usage: %AriaEngine.StateV2{} -> %AriaEngine.State{}
  defp transform_ast({:%, meta, [{:__aliases__, alias_meta, [:AriaEngine, :StateV2]}, fields]}) do
    {:%, meta, [{:__aliases__, alias_meta, [:AriaEngine, :State]}, fields]}
  end

  # Transform StateV2 module calls: StateV2.function() -> State.function()
  defp transform_ast({{:., dot_meta, [{:__aliases__, alias_meta, [:StateV2]}, function]}, call_meta, args}) do
    {{:., dot_meta, [{:__aliases__, alias_meta, [:State]}, function]}, call_meta, args}
  end

  # Transform fully qualified StateV2 module calls: AriaEngine.StateV2.function() -> AriaEngine.State.function()
  defp transform_ast({{:., dot_meta, [{:__aliases__, alias_meta, [:AriaEngine, :StateV2]}, function]}, call_meta, args}) do
    {{:., dot_meta, [{:__aliases__, alias_meta, [:AriaEngine, :State]}, function]}, call_meta, args}
  end

  # Transform StateV2 type references: AriaEngine.StateV2.t() -> AriaEngine.State.t()
  defp transform_ast({:__aliases__, meta, [:AriaEngine, :StateV2]}) do
    {:__aliases__, meta, [:AriaEngine, :State]}
  end

  # Transform alias statements: alias AriaEngine.StateV2 -> alias AriaEngine.State
  defp transform_ast({:alias, meta, [{:__aliases__, alias_meta, [:AriaEngine, :StateV2]}]}) do
    {:alias, meta, [{:__aliases__, alias_meta, [:AriaEngine, :State]}]}
  end

  # Transform alias with :as option: alias AriaEngine.StateV2, as: S -> alias AriaEngine.State, as: S
  defp transform_ast({:alias, meta, [{:__aliases__, alias_meta, [:AriaEngine, :StateV2]}, [as: alias_name]]}) do
    {:alias, meta, [{:__aliases__, alias_meta, [:AriaEngine, :State]}, [as: alias_name]]}
  end

  # Recursively transform nested AST nodes
  defp transform_ast(ast) when is_tuple(ast) do
    ast
    |> Tuple.to_list()
    |> Enum.map(&transform_ast/1)
    |> List.to_tuple()
  end

  defp transform_ast(ast) when is_list(ast) do
    Enum.map(ast, &transform_ast/1)
  end

  defp transform_ast(ast), do: ast

  # Helper functions

  defp count_transformations(original_content, transformed_content) do
    original_state_v2_count = count_state_v2_occurrences(original_content)
    transformed_state_v2_count = count_state_v2_occurrences(transformed_content)
    original_state_v2_count - transformed_state_v2_count
  end

  defp count_state_v2_occurrences(content) do
    # Count various StateV2 patterns
    alias_count = Regex.scan(~r/alias\s+AriaEngine\.StateV2/, content) |> length()
    struct_count = Regex.scan(~r/%StateV2\{/, content) |> length()
    call_count = Regex.scan(~r/StateV2\./, content) |> length()

    alias_count + struct_count + call_count
  end

  # Validation functions

  defp has_state_v2_usage?(file_path) do
    case File.read(file_path) do
      {:ok, content} -> String.contains?(content, "StateV2")
      {:error, _} -> false
    end
  end

  defp valid_state_usage?(file_path) do
    case File.read(file_path) do
      {:ok, content} ->
        # Check that the file doesn't contain StateV2 references anymore
        not String.contains?(content, "StateV2")
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
      {:error, _} -> false
    end
  end
end
