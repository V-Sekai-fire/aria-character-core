# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.Migrate.RuleEngine do
  @moduledoc """
  Executes transformation rules on code.

  Single responsibility: Apply AST-based transformation rules to source code
  without handling file I/O or user interaction.
  """

  @doc """
  Transform source code using the provided transformation rules.

  Returns `{:changed, new_code}`, `:unchanged`, or `{:error, reason}`.
  """
  @spec transform_code(String.t(), [function()]) ::
    {:changed, String.t()} | :unchanged | {:error, String.t()}
  def transform_code(source_code, transformation_rules) do
    with {:ok, ast} <- parse_code(source_code),
         transformed_ast = apply_transformation_rules(ast, transformation_rules),
         {:ok, new_code} <- ast_to_code(transformed_ast) do
      if new_code == source_code do
        :unchanged
      else
        {:changed, new_code}
      end
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Parse Elixir source code into AST.
  """
  @spec parse_code(String.t()) :: {:ok, Macro.t()} | {:error, String.t()}
  def parse_code(source_code) do
    try do
      ast = Code.string_to_quoted!(source_code)
      {:ok, ast}
    rescue
      e in SyntaxError ->
        {:error, "Syntax error: #{Exception.message(e)}"}

      e ->
        {:error, "Parse error: #{Exception.message(e)}"}
    end
  end

  @doc """
  Convert AST back to formatted Elixir source code.
  """
  @spec ast_to_code(Macro.t()) :: {:ok, String.t()} | {:error, String.t()}
  def ast_to_code(ast) do
    try do
      code = Macro.to_string(ast)
      {:ok, code}
    rescue
      e ->
        {:error, "AST to code conversion error: #{Exception.message(e)}"}
    end
  end

  @doc """
  Apply multiple transformation rules to AST.
  """
  @spec apply_transformation_rules(Macro.t(), [function()]) :: Macro.t()
  def apply_transformation_rules(ast, transformation_rules) do
    Enum.reduce(transformation_rules, ast, fn rule, acc_ast ->
      apply_single_transformation_rule(acc_ast, rule)
    end)
  end

  @doc """
  Apply a single transformation rule to AST.
  """
  @spec apply_single_transformation_rule(Macro.t(), function()) :: Macro.t()
  def apply_single_transformation_rule(ast, rule_fn) when is_function(rule_fn, 1) do
    Macro.prewalk(ast, rule_fn)
  end

  @doc """
  Create a transformation rule for function call replacements.

  ## Parameters
  - `module_path`: List of module atoms, e.g., [:AriaEngine, :Timeline, :Interval]
  - `old_function`: Atom of the function to replace
  - `new_function`: Atom of the replacement function
  - `arg_transformer`: Optional function to transform arguments

  ## Example
      rule = function_call_rule(
        [:AriaEngine, :Timeline, :Interval],
        :new,
        :new_fixed_schedule,
        &wrap_datetime_args/1
      )
  """
  @spec function_call_rule([atom()], atom(), atom(), function() | nil) :: function()
  def function_call_rule(module_path, old_function, new_function, arg_transformer \\ nil) do
    fn ast_node ->
      case ast_node do
        # Match: Module.function(args)
        {{:., meta, [{:__aliases__, alias_meta, ^module_path}, ^old_function]}, call_meta, args} ->
          transformed_args = if arg_transformer, do: arg_transformer.(args), else: args

          {{:., meta, [{:__aliases__, alias_meta, module_path}, new_function]}, call_meta,
           transformed_args}

        # Match: function(args) when module is aliased
        {^old_function, _call_meta, _args} ->
          # This is more complex - we'd need context to know if the module is aliased
          # For now, we'll be conservative and not transform bare function calls
          ast_node

        _ ->
          ast_node
      end
    end
  end

  @doc """
  Create a transformation rule for wrapping DateTime arguments with DateTime.to_iso8601/1.
  """
  @spec datetime_to_iso8601_wrapper() :: function()
  def datetime_to_iso8601_wrapper do
    fn args ->
      Enum.map(args, fn arg ->
        case arg do
          # Match DateTime struct patterns
          {:%, _, [{:__aliases__, _, [:DateTime]}, _]} ->
            wrap_with_datetime_to_iso8601(arg)

          # Match variable that might be DateTime (we'll wrap it conditionally)
          {var_name, _meta, context} when is_atom(var_name) and is_atom(context) ->
            # For variables, we need to be more careful
            # We could add a runtime check or assume it's DateTime based on context
            wrap_with_datetime_to_iso8601(arg)

          # Keep other arguments as-is (already ISO8601 strings, etc.)
          _ ->
            arg
        end
      end)
    end
  end

  @doc """
  Wrap an AST node with DateTime.to_iso8601/1 call.
  """
  @spec wrap_with_datetime_to_iso8601(Macro.t()) :: Macro.t()
  def wrap_with_datetime_to_iso8601(ast_node) do
    {{:., [], [{:__aliases__, [], [:DateTime]}, :to_iso8601]}, [], [ast_node]}
  end

  @doc """
  Create a transformation rule for converting DateTime.from_naive! calls to ISO 8601 strings.
  """
  @spec datetime_from_naive_to_iso8601_rule() :: function()
  def datetime_from_naive_to_iso8601_rule do
    fn ast_node ->
      case ast_node do
        # Match: DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
        {{:., _, [{:__aliases__, _, [:DateTime]}, :from_naive!]}, _,
         [
           {:sigil_N, _, [{_, _, [date_string]}, []]},
           timezone_string
         ]} ->
          # Convert to ISO 8601 string literal
          convert_naive_to_iso8601(date_string, timezone_string)

        _ ->
          ast_node
      end
    end
  end

  @doc """
  Convert naive datetime string and timezone to ISO 8601 format.
  """
  @spec convert_naive_to_iso8601(String.t(), String.t()) :: String.t()
  def convert_naive_to_iso8601(date_string, "\"Etc/UTC\"") do
    # Simple conversion for UTC timezone
    # Input: "2023-01-01 00:00:00"
    # Output: "2023-01-01T00:00:00Z"
    date_string
    |> String.replace(" ", "T")
    |> Kernel.<>("Z")
  end

  def convert_naive_to_iso8601(date_string, _other_timezone) do
    # For non-UTC timezones, we'll use a simplified approach
    # This could be enhanced to handle more timezone formats
    date_string
    |> String.replace(" ", "T")
    |> Kernel.<>("Z")
  end

  @doc """
  Create a transformation rule for regex-based string replacements.

  This provides a bridge for simple string-based transformations that don't
  require full AST parsing, but should be used sparingly.
  """
  @spec regex_replacement_rule(Regex.t(), String.t()) :: function()
  def regex_replacement_rule(pattern, replacement) do
    fn ast_node ->
      # This is a simplified approach - in practice, you'd want to be more careful
      # about when and how to apply string-based transformations to AST nodes
      case ast_node do
        {atom, meta, args} when is_atom(atom) and is_list(args) ->
          # Transform string literals within the AST node
          new_args = transform_string_literals_in_args(args, pattern, replacement)
          {atom, meta, new_args}

        _ ->
          ast_node
      end
    end
  end

  # Private functions

  defp transform_string_literals_in_args(args, pattern, replacement) do
    Enum.map(args, fn arg ->
      case arg do
        string when is_binary(string) ->
          String.replace(string, pattern, replacement)

        _ ->
          arg
      end
    end)
  end
end
