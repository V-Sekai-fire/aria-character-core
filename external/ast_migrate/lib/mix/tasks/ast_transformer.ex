# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule Mix.Tasks.Migrate.AstTransformer do
  @moduledoc """
  AST-based code transformation engine for migration tasks.

  Provides robust code transformations using Elixir's AST instead of regex patterns.
  This ensures syntactic correctness and handles complex expressions properly.
  """

  require Logger

  @doc """
  Parse Elixir source code into AST.

  Returns `{:ok, ast}` on success or `{:error, reason}` on parse failure.
  """
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
  Apply transformation rules to AST.

  Takes an AST and a list of transformation rules, applying each rule
  and returning the transformed AST.
  """
  def transform_ast(ast, transformation_rules) do
    Enum.reduce(transformation_rules, ast, fn rule, acc_ast ->
      apply_transformation_rule(acc_ast, rule)
    end)
  end

  @doc """
  Apply a single transformation rule to AST.

  A transformation rule is a function that takes AST and returns transformed AST.
  """
  def apply_transformation_rule(ast, rule_fn) when is_function(rule_fn, 1) do
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

  This specifically handles the timeline interval deprecation by wrapping DateTime
  structs with DateTime.to_iso8601() calls.
  """
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
  def wrap_with_datetime_to_iso8601(ast_node) do
    {{:., [], [{:__aliases__, [], [:DateTime]}, :to_iso8601]}, [], [ast_node]}
  end

  @doc """
  Transform source code using AST transformations.

  This is the main entry point for transforming source code:
  1. Parse code to AST
  2. Apply transformation rules
  3. Convert back to source code

  Returns `{:changed, new_code}`, `:unchanged`, or `{:error, reason}`.
  """
  def transform_code(source_code, transformation_rules) do
    with {:ok, ast} <- parse_code(source_code),
         transformed_ast = transform_ast(ast, transformation_rules),
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
  Create transformation rules for timeline interval deprecation fixes.

  Returns a list of transformation rules that:
  1. Replace Interval.new/2 with Interval.new_fixed_schedule/2
  2. Replace Interval.new/3 with Interval.new_fixed_schedule/3
  3. Wrap DateTime arguments with DateTime.to_iso8601/1
  4. Convert DateTime.from_naive! patterns to ISO 8601 strings
  """
  def timeline_interval_rules do
    [
      # Transform DateTime.from_naive! calls to ISO 8601 strings
      datetime_from_naive_to_iso8601_rule(),

      # Transform AriaEngine.Timeline.Interval.new calls
      function_call_rule(
        [:AriaEngine, :Timeline, :Interval],
        :new,
        :new_fixed_schedule,
        datetime_to_iso8601_wrapper()
      ),

      # Transform aliased Interval.new calls
      function_call_rule(
        [:Interval],
        :new,
        :new_fixed_schedule,
        datetime_to_iso8601_wrapper()
      )
    ]
  end

  @doc """
  Create a transformation rule for converting DateTime.from_naive! calls to ISO 8601 strings.

  This specifically handles the pattern:
  DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")

  And converts it to:
  "2025-01-01T10:00:00Z"
  """
  def datetime_from_naive_to_iso8601_rule do
    fn ast_node ->
      case ast_node do
        {{:., _, [{:__aliases__, _, [:DateTime]}, :from_naive!]}, _,
         [
           {:sigil_N, _, [{_, _, [date_string]}, []]},
           # Match: DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC")
           timezone_string
         ]} ->
          # Convert to ISO 8601 string literal
          iso_string = convert_naive_to_iso8601(date_string, timezone_string)
          iso_string

        _ ->
          ast_node
      end
    end
  end

  @doc """
  Check if source code contains patterns that need timeline interval transformation.
  """
  def needs_timeline_interval_transformation?(source_code) do
    String.contains?(source_code, "Interval.new(") or
      String.contains?(source_code, "DateTime.from_naive!")
  end

  @doc """
  Convert naive datetime string and timezone to ISO 8601 format.
  """
  def convert_naive_to_iso8601(date_string, "\"Etc/UTC\"") do
    # Simple conversion for UTC timezone
    # Input: "2023-01-01 00:00:00"
    # Output: "2023-01-01T00:00:00Z"
    iso_string =
      date_string
      |> String.replace(" ", "T")
      |> Kernel.<>("Z")

    # Return as string literal AST node
    iso_string
  end

  def convert_naive_to_iso8601(date_string, _other_timezone) do
    # For non-UTC timezones, we'll use a simplified approach
    # This could be enhanced to handle more timezone formats
    iso_string =
      date_string
      |> String.replace(" ", "T")
      |> Kernel.<>("Z")

    # Return as string literal AST node
    iso_string
  end

  @doc """
  Create transformation rules for plan format migration.

  Returns a list of transformation rules that:
  1. Replace `assert is_list(plan)` with `assert %{nodes: _, root_id: _} = plan`
  2. Replace `assert length(plan) > 0` with `assert map_size(plan.nodes) > 0`
  3. Replace other list-based plan assertions with tree-based equivalents
  """
  def plan_format_migration_rules do
    [
      # Transform `assert is_list(plan)` to `assert %{nodes: _, root_id: _} = plan`
      plan_is_list_assertion_rule(),

      # Transform `assert length(plan) > 0` to `assert map_size(plan.nodes) > 0`
      plan_length_assertion_rule(),

      # Transform `assert length(plan) == N` to `assert map_size(plan.nodes) == N`
      plan_length_equality_assertion_rule()
    ]
  end

  @doc """
  Create a transformation rule for `is_list(plan)` assertions.
  """
  def plan_is_list_assertion_rule do
    fn ast_node ->
      case ast_node do
        # Match: assert is_list(plan)
        {:assert, meta, [{:is_list, call_meta, [plan_var]}]} ->
          # Replace with: assert %{nodes: _, root_id: _} = plan
          pattern =
            {:%, [],
             [
               {:%{}, [],
                [
                  {:nodes, {:_, [], nil}},
                  {:root_id, {:_, [], nil}}
                ]}
             ]}

          {:assert, meta, [{:=, call_meta, [pattern, plan_var]}]}

        _ ->
          ast_node
      end
    end
  end

  @doc """
  Create a transformation rule for `length(plan) > 0` patterns.
  """
  def plan_length_assertion_rule do
    fn ast_node ->
      case ast_node do
        {:assert, meta,
         [
           {:>, op_meta,
            [
              {:length, length_meta, [plan_var]},
              0
            ]}
           # Match: assert length(plan) > 0
         ]} ->
          # Replace with: assert map_size(plan.nodes) > 0
          new_call =
            {{:., [], [{:__aliases__, [], [:Map]}, :size]}, length_meta,
             [
               {{:., [], [plan_var, :nodes]}, [], []}
             ]}

          {:assert, meta, [{:>, op_meta, [new_call, 0]}]}

        _ ->
          ast_node
      end
    end
  end

  @doc """
  Create a transformation rule for `length(plan) == N` patterns.
  """
  def plan_length_equality_assertion_rule do
    fn ast_node ->
      case ast_node do
        {:assert, meta,
         [
           {:==, op_meta,
            [
              {:length, length_meta, [plan_var]},
              n
            ]}
           # Match: assert length(plan) == N
         ]} ->
          # Replace with: assert map_size(plan.nodes) == N
          new_call =
            {{:., [], [{:__aliases__, [], [:Map]}, :size]}, length_meta,
             [
               {{:., [], [plan_var, :nodes]}, [], []}
             ]}

          {:assert, meta, [{:==, op_meta, [new_call, n]}]}

        _ ->
          ast_node
      end
    end
  end

  @doc """
  Check if source code contains patterns that need plan format transformation.
  """
  def needs_plan_format_transformation?(source_code) do
    String.contains?(source_code, "is_list(plan)") or
      String.contains?(source_code, "length(plan)")
  end
end
