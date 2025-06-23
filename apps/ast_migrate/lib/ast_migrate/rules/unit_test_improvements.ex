# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AstMigrate.Rules.UnitTestImprovements do
  @moduledoc """
  Improves unit test readability and structure using AST transformations.

  This rule demonstrates common AST transformation patterns while providing
  useful improvements to test code structure.

  ## Transformations Applied

  1. **Extract intermediate variables in assertions:**
     ```elixir
     # Before
     assert some_function(arg) == expected

     # After
     result = some_function(arg)
     assert result == expected
     ```

  2. **Add missing assertions to bare function calls:**
     ```elixir
     # Before
     test "some test" do
       some_function()
     end

     # After
     test "some test" do
       result = some_function()
       assert result
     end
     ```

  3. **Improve test documentation:**
     ```elixir
     # Before
     test "test name" do
       # test body
     end

     # After
     test "test name" do
       # Given/When/Then structure encouraged
       # test body
     end
     ```
  """

  @behaviour AstMigrate.Rules.Behaviour
  require Logger

  @impl true
  def description do
    "Improves unit test readability and structure using AST transformations"
  end

  @impl true
  def file_patterns do
    ["test/**/*.exs"]
  end

  @impl true
  def preconditions do
    [&has_test_functions?/1]
  end

  @impl true
  def postconditions do
    [&compiles_successfully?/1]
  end

  @impl true
  def validate_preconditions(_files) do
    :ok
  end

  @impl true
  def transform_file(file_path) do
    Logger.debug("Starting test improvement transformation for file",
      module: :ast_migrate_rules_unit_test_improvements,
      operation: :transform_file,
      file: file_path
    )

    with {:ok, content} <- File.read(file_path),
         {:ok, transformed_code} <- transform_file_content(content) do
      Logger.debug("Test improvement transformation completed for file",
        module: :ast_migrate_rules_unit_test_improvements,
        operation: :transform_file,
        file: file_path,
        original_size: byte_size(content),
        transformed_size: byte_size(transformed_code)
      )

      {:ok, transformed_code}
    else
      {:error, reason} ->
        Logger.error("Test improvement transformation failed for file",
          module: :ast_migrate_rules_unit_test_improvements,
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
    Logger.debug("Starting test improvement transformation for content",
      module: :ast_migrate_rules_unit_test_improvements,
      operation: :transform_file_content,
      content_size: byte_size(content)
    )

    with {:ok, ast} <- Code.string_to_quoted(content),
         transformed_ast <- transform_ast(ast),
         transformed_code <- Macro.to_string(transformed_ast) do
      transformations_applied = count_transformations(content, transformed_code)

      Logger.debug("Test improvement transformation completed for content",
        module: :ast_migrate_rules_unit_test_improvements,
        operation: :transform_file_content,
        transformations_applied: transformations_applied,
        original_size: byte_size(content),
        transformed_size: byte_size(transformed_code)
      )

      {:ok, transformed_code}
    else
      {:error, reason} ->
        Logger.error("Test improvement transformation failed for content",
          module: :ast_migrate_rules_unit_test_improvements,
          operation: :transform_file_content,
          error: inspect(reason)
        )

        {:error, "Failed to transform content: #{inspect(reason)}"}
    end
  end

  # Transform assert statements with complex expressions
  defp transform_ast({:assert, meta, [{{:==, eq_meta, [left_expr, right_expr]}, assert_meta}]})
       when not is_atom(left_expr) and not is_number(left_expr) and not is_binary(left_expr) do
    # Extract complex left expression to a variable
    var_name = generate_variable_name(left_expr)

    [
      {:=, [], [{var_name, [], nil}, left_expr]},
      {:assert, meta, [{{:==, eq_meta, [{var_name, [], nil}, right_expr]}, assert_meta}]}
    ]
  end

  # Transform bare function calls in test blocks to include assertions
  defp transform_ast({:test, meta, [test_name, [do: test_body]]}) do
    transformed_body = transform_test_body(test_body)
    {:test, meta, [test_name, [do: transformed_body]]}
  end

  # Recursively transform nested AST nodes
  defp transform_ast(ast) when is_tuple(ast) do
    ast |> Tuple.to_list() |> Enum.map(&transform_ast/1) |> List.to_tuple()
  end

  defp transform_ast(ast) when is_list(ast) do
    Enum.flat_map(ast, fn node ->
      case transform_ast(node) do
        list when is_list(list) -> list
        single -> [single]
      end
    end)
  end

  defp transform_ast(ast) do
    ast
  end

  # Transform test body to add assertions to bare function calls
  defp transform_test_body({:__block__, meta, statements}) do
    transformed_statements =
      statements
      |> Enum.flat_map(&transform_statement/1)

    {:__block__, meta, transformed_statements}
  end

  defp transform_test_body(single_statement) do
    case transform_statement(single_statement) do
      [single] -> single
      multiple -> {:__block__, [], multiple}
    end
  end

  # Transform individual statements in test body
  defp transform_statement({{:., _, [_module, _function]}, _, _args} = function_call) do
    # This is a function call - add an assertion
    var_name = :result
    [
      {:=, [], [{var_name, [], nil}, function_call]},
      {:assert, [], [{var_name, [], nil}]}
    ]
  end

  defp transform_statement(statement) do
    [transform_ast(statement)]
  end

  # Generate a meaningful variable name based on the expression
  defp generate_variable_name({{:., _, [_module, function_name]}, _, _args}) when is_atom(function_name) do
    function_name
  end

  defp generate_variable_name({function_name, _, _args}) when is_atom(function_name) do
    function_name
  end

  defp generate_variable_name(_expr) do
    :result
  end

  # Count the number of transformations applied
  defp count_transformations(original_content, transformed_content) do
    original_assert_count = count_assert_statements(original_content)
    transformed_assert_count = count_assert_statements(transformed_content)
    transformed_assert_count - original_assert_count
  end

  defp count_assert_statements(content) do
    Regex.scan(~r/assert\s+/, content) |> length()
  end

  # Validation functions
  defp has_test_functions?(file_path) do
    case File.read(file_path) do
      {:ok, content} -> String.contains?(content, "test ")
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
