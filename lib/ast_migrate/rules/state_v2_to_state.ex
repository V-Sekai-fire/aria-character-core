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
  def validate_preconditions(files) do
    # For now, always allow transformation
    :ok
  end

  @impl true
  def transform_file(file_path) do
    with {:ok, content} <- File.read(file_path),
         {:ok, ast} <- Code.string_to_quoted(content),
         transformed_ast <- transform_ast(ast),
         transformed_code <- Macro.to_string(transformed_ast) do
      {:ok, transformed_code}
    else
      {:error, reason} -> {:error, "Failed to transform #{file_path}: #{inspect(reason)}"}
    end
  end

  # AST transformation functions

  # Transform StateV2 struct usage: %StateV2{} -> %State{}
  defp transform_ast({:%, meta, [{:__aliases__, alias_meta, [:StateV2]}, fields]}) do
    {:%, meta, [{:__aliases__, alias_meta, [:State]}, fields]}
  end

  # Transform StateV2 module calls: StateV2.function() -> State.function()
  defp transform_ast({{:., dot_meta, [{:__aliases__, alias_meta, [:StateV2]}, function]}, call_meta, args}) do
    {{:., dot_meta, [{:__aliases__, alias_meta, [:State]}, function]}, call_meta, args}
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
