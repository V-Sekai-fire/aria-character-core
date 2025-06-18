defmodule AriaEngine.ASTTranslator.PatternMatcher do
  @moduledoc """
  Pattern matching for Elixir AST nodes to identify KHR-translatable operations.

  Recognizes all supported AST patterns and categorizes them for translation into
  glTF KHR_interactivity nodes. Handles math, control flow, variables, events,
  animation, and type conversion patterns.

  ## Pattern Categories

  - **Math patterns**: Binary operations, function calls, comparisons
  - **Variable patterns**: Assignment, reference, existence checks
  - **Control flow patterns**: Conditionals, sequences, switches
  - **Event patterns**: Send/receive operations, lifecycle events
  - **Animation patterns**: Start/stop/pause/resume operations
  - **Type conversion patterns**: Explicit type conversions

  ## Usage

      iex> PatternMatcher.recognize_pattern({:+, [], [1, 2]})
      {:binary_math, :+, [1, 2]}

      iex> PatternMatcher.recognize_pattern({:=, [], [{:x, [], nil}, 5]})
      {:variable_assignment, :x, 5}
  """

  alias AriaEngine.ASTTranslator.OperationRegistry

  @type ast_node :: tuple() | atom() | number() | binary() | boolean()
  
  @type pattern_result ::
    {:binary_math, atom(), [ast_node()]} |
    {:unary_math, atom(), ast_node()} |
    {:function_call, atom(), [ast_node()]} |
    {:variable_assignment, atom(), ast_node()} |
    {:variable_reference, atom()} |
    {:if_then, ast_node(), ast_node()} |
    {:if_then_else, ast_node(), ast_node(), ast_node()} |
    {:case_switch, ast_node(), [tuple()]} |
    {:sequence_block, [ast_node()]} |
    {:event_send, ast_node(), ast_node()} |
    {:event_receive, ast_node()} |
    {:animation_control, atom(), ast_node()} |
    {:type_conversion, atom(), ast_node()} |
    {:literal, any()} |
    {:unsupported, String.t()}

  @doc """
  Recognize an AST pattern and categorize it for translation.

  ## Parameters
  - `ast_node`: AST node to analyze

  ## Returns
  - Pattern tuple describing the operation type and operands
  - `{:unsupported, reason}` if pattern cannot be translated

  ## Examples

      iex> PatternMatcher.recognize_pattern({:+, [], [1, 2]})
      {:binary_math, :+, [1, 2]}

      iex> PatternMatcher.recognize_pattern({{:., [], [nil, :abs]}, [], [5]})
      {:function_call, :abs, [5]}

      iex> PatternMatcher.recognize_pattern({:=, [], [{:x, [], nil}, 10]})
      {:variable_assignment, :x, 10}
  """
  @spec recognize_pattern(ast_node()) :: pattern_result()
  def recognize_pattern(ast_node) do
    case ast_node do
      # Literal values
      literal when is_number(literal) or is_boolean(literal) or is_binary(literal) ->
        {:literal, literal}

      # Atoms (typically nil or variable names in certain contexts)
      atom when is_atom(atom) ->
        {:literal, atom}

      # Variable reference
      {var_name, _meta, nil} when is_atom(var_name) ->
        {:variable_reference, var_name}

      # Binary math operations
      {op, _meta, [left, right]} when op in [:+, :-, :*, :/, :rem] ->
        {:binary_math, op, [left, right]}

      # Comparison operations
      {op, _meta, [left, right]} when op in [:==, :!=, :<, :>, :<=, :>=] ->
        {:binary_math, op, [left, right]}

      # Boolean operations
      {op, _meta, [left, right]} when op in [:and, :or] ->
        {:binary_math, op, [left, right]}

      # Unary boolean operation
      {:not, _meta, [operand]} ->
        {:unary_math, :not, operand}

      # Variable assignment
      {:=, _meta, [{var_name, _var_meta, nil}, value_expr]} ->
        {:variable_assignment, var_name, value_expr}

      # Function calls - standard Elixir pattern
      {{:., _dot_meta, [nil, func_name]}, _call_meta, args} ->
        if OperationRegistry.supported_operation?({func_name, length(args)}) do
          {:function_call, func_name, args}
        else
          {:unsupported, "Unsupported function: #{func_name}/#{length(args)}"}
        end

      # Function calls - module qualified
      {{:., _dot_meta, [module, func_name]}, _call_meta, args} when is_atom(module) ->
        qualified_func = {module, func_name, length(args)}
        if OperationRegistry.supported_operation?(qualified_func) do
          {:function_call, qualified_func, args}
        else
          {:unsupported, "Unsupported qualified function: #{inspect(qualified_func)}"}
        end

      # Function calls - direct call pattern (rare)
      {func_name, _meta, args} when is_atom(func_name) and is_list(args) ->
        if OperationRegistry.supported_operation?({func_name, length(args)}) do
          {:function_call, func_name, args}
        else
          check_special_patterns(func_name, args)
        end

      # If-then conditional
      {:if, _meta, [condition, [do: then_branch]]} ->
        {:if_then, condition, then_branch}

      # If-then-else conditional
      {:if, _meta, [condition, [do: then_branch, else: else_branch]]} ->
        {:if_then_else, condition, then_branch, else_branch}

      # Case statement (switch)
      {:case, _meta, [value_expr, [do: clauses]]} ->
        {:case_switch, value_expr, clauses}

      # Block sequence
      {:__block__, _meta, statements} ->
        {:sequence_block, statements}

      # Special KHR operations (custom functions)
      {special_func, _meta, args} ->
        recognize_special_operations(special_func, args)

      # Unsupported patterns
      other ->
        {:unsupported, "Unrecognized AST pattern: #{inspect(other)}"}
    end
  end

  @doc """
  Check if an AST pattern is supported for translation.

  ## Parameters
  - `ast_node`: AST node to check

  ## Returns
  - `true` if pattern can be translated
  - `false` if pattern is unsupported
  """
  @spec supported_pattern?(ast_node()) :: boolean()
  def supported_pattern?(ast_node) do
    case recognize_pattern(ast_node) do
      {:unsupported, _reason} -> false
      _supported_pattern -> true
    end
  end

  @doc """
  Extract all variable references from an AST node.

  ## Parameters
  - `ast_node`: AST node to analyze

  ## Returns
  - List of variable names referenced in the AST
  """
  @spec extract_variable_references(ast_node()) :: [atom()]
  def extract_variable_references(ast_node) do
    {_ast, variables} = Macro.prewalk(ast_node, [], fn node, acc ->
      case node do
        {var_name, _meta, nil} when is_atom(var_name) ->
          {node, [var_name | acc]}
        _other ->
          {node, acc}
      end
    end)
    
    variables |> Enum.uniq()
  end

  @doc """
  Get the complexity score of an AST pattern (for optimization).

  ## Parameters
  - `ast_node`: AST node to score

  ## Returns
  - Non-negative integer representing complexity
  """
  @spec complexity_score(ast_node()) :: non_neg_integer()
  def complexity_score(ast_node) do
    case recognize_pattern(ast_node) do
      {:literal, _} -> 0
      {:variable_reference, _} -> 1
      {:binary_math, _, operands} -> 
        1 + Enum.sum(Enum.map(operands, &complexity_score/1))
      {:unary_math, _, operand} -> 
        1 + complexity_score(operand)
      {:function_call, _, args} -> 
        2 + Enum.sum(Enum.map(args, &complexity_score/1))
      {:variable_assignment, _, value} -> 
        2 + complexity_score(value)
      {:if_then_else, condition, then_branch, else_branch} ->
        3 + complexity_score(condition) + complexity_score(then_branch) + complexity_score(else_branch)
      {:sequence_block, statements} ->
        2 + Enum.sum(Enum.map(statements, &complexity_score/1))
      {:case_switch, value, clauses} ->
        3 + complexity_score(value) + length(clauses) * 2
      {:event_send, _, data} -> 
        2 + complexity_score(data)
      {:animation_control, _, _} -> 
        2
      {:type_conversion, _, value} -> 
        1 + complexity_score(value)
      {:unsupported, _} -> 
        999  # Very high complexity for unsupported patterns
    end
  end

  @doc """
  Validate that an AST pattern meets KHR translation requirements.

  ## Parameters
  - `ast_node`: AST node to validate

  ## Returns
  - `:ok` if pattern is valid
  - `{:error, [reasons]}` if pattern has issues
  """
  @spec validate_pattern(ast_node()) :: :ok | {:error, [String.t()]}
  def validate_pattern(ast_node) do
    errors = []
    
    # Check for unsupported patterns
    errors = case recognize_pattern(ast_node) do
      {:unsupported, reason} -> [reason | errors]
      _supported -> errors
    end
    
    # Check for deeply nested structures
    if complexity_score(ast_node) > 50 do
      errors = ["Pattern too complex for efficient translation" | errors]
    end
    
    # Check for problematic variable references
    var_refs = extract_variable_references(ast_node)
    if length(var_refs) > 20 do
      errors = ["Too many variable references (#{length(var_refs)})" | errors]
    end
    
    case errors do
      [] -> :ok
      errors -> {:error, Enum.reverse(errors)}
    end
  end

  # Private helper functions

  defp check_special_patterns(func_name, args) do
    case {func_name, length(args)} do
      # Variable operations
      {:get_var, 1} -> {:function_call, :get_var, args}
      {:set_var, 2} -> {:function_call, :set_var, args}
      {:has_var?, 1} -> {:function_call, :has_var?, args}
      {:delete_var, 1} -> {:function_call, :delete_var, args}
      
      # Event operations
      {:send_event, 2} -> {:event_send, Enum.at(args, 0), Enum.at(args, 1)}
      {:receive_event, 1} -> {:event_receive, Enum.at(args, 0)}
      {:on_start, 0} -> {:function_call, :on_start, args}
      {:on_tick, 1} -> {:function_call, :on_tick, args}
      
      # Animation operations
      {:start_animation, 1} -> {:animation_control, :start, Enum.at(args, 0)}
      {:stop_animation, 1} -> {:animation_control, :stop, Enum.at(args, 0)}
      {:pause_animation, 1} -> {:animation_control, :pause, Enum.at(args, 0)}
      {:resume_animation, 1} -> {:animation_control, :resume, Enum.at(args, 0)}
      {:is_playing?, 1} -> {:animation_control, :is_playing, Enum.at(args, 0)}
      
      # Type conversions
      {:to_int, 1} -> {:type_conversion, :int, Enum.at(args, 0)}
      {:to_float, 1} -> {:type_conversion, :float, Enum.at(args, 0)}
      {:to_bool, 1} -> {:type_conversion, :bool, Enum.at(args, 0)}
      {:to_string, 1} -> {:type_conversion, :string, Enum.at(args, 0)}
      
      _other -> {:unsupported, "Unknown function: #{func_name}/#{length(args)}"}
    end
  end

  defp recognize_special_operations(func_name, args) do
    # Handle additional special operation patterns
    case func_name do
      # Special control flow
      :sequence when is_list(args) -> {:sequence_block, args}
      :branch when length(args) == 3 -> {:if_then_else, Enum.at(args, 0), Enum.at(args, 1), Enum.at(args, 2)}
      
      # Special variable operations with different syntax
      :var_get when length(args) == 1 -> {:function_call, :get_var, args}
      :var_set when length(args) == 2 -> {:function_call, :set_var, args}
      
      # Any other unrecognized function
      _other -> {:unsupported, "Unrecognized special operation: #{func_name}"}
    end
  end

  @doc """
  Get human-readable description of a pattern.

  ## Parameters
  - `pattern`: Pattern result from recognize_pattern/1

  ## Returns
  - String description of the pattern
  """
  @spec describe_pattern(pattern_result()) :: String.t()
  def describe_pattern(pattern) do
    case pattern do
      {:literal, value} -> "Literal value: #{inspect(value)}"
      {:variable_reference, var} -> "Variable reference: #{var}"
      {:binary_math, op, _} -> "Binary math operation: #{op}"
      {:unary_math, op, _} -> "Unary math operation: #{op}"
      {:function_call, func, args} -> "Function call: #{func}/#{length(args)}"
      {:variable_assignment, var, _} -> "Variable assignment: #{var}"
      {:if_then, _, _} -> "If-then conditional"
      {:if_then_else, _, _, _} -> "If-then-else conditional"
      {:case_switch, _, clauses} -> "Case switch with #{length(clauses)} clauses"
      {:sequence_block, statements} -> "Sequence block with #{length(statements)} statements"
      {:event_send, _, _} -> "Event send operation"
      {:event_receive, _} -> "Event receive operation"
      {:animation_control, action, _} -> "Animation #{action} operation"
      {:type_conversion, target_type, _} -> "Type conversion to #{target_type}"
      {:unsupported, reason} -> "Unsupported pattern: #{reason}"
    end
  end

  @doc """
  Check if a pattern requires special handling during translation.

  ## Parameters
  - `pattern`: Pattern result from recognize_pattern/1

  ## Returns
  - `true` if pattern needs special handling
  - `false` if pattern can use standard translation
  """
  @spec requires_special_handling?(pattern_result()) :: boolean()
  def requires_special_handling?(pattern) do
    case pattern do
      {:case_switch, _, _} -> true
      {:sequence_block, _} -> true
      {:if_then_else, _, _, _} -> true
      {:event_send, _, _} -> true
      {:animation_control, _, _} -> true
      _standard_pattern -> false
    end
  end
end
