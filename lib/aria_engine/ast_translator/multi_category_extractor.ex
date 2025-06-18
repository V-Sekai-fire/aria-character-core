defmodule AriaEngine.ASTTranslator.MultiCategoryExtractor do
  @moduledoc """
  Multi-category operation extraction from Elixir AST nodes.

  Extracts operations from all supported KHR_interactivity categories including:
  - Math operations (arithmetic, comparison, trigonometry, vectors, matrices)
  - Control flow (sequence, branch, switch, loops)
  - Variable management (get, set, exists, delete, pointers)
  - Event system (send, receive, lifecycle, debug)
  - Animation control (start, stop, pause, resume, status)
  - Type conversion (bool ↔ int ↔ float)

  Processes AST nodes recursively and builds a complete operation sequence with
  proper node ID assignment and dependency tracking.

  ## Usage

      node_manager = NodeManager.new([:x, :y])
      {operations, final_manager} = MultiCategoryExtractor.extract_operations(ast_body, node_manager)
  """

  alias AriaEngine.ASTTranslator.{NodeManager, PatternMatcher, OperationRegistry, DataFlow}

  @type extraction_result :: {[NodeManager.operation_info()], NodeManager.t()}

  @doc """
  Extract all operations from an AST body.

  Processes the function body AST and extracts all translatable operations,
  assigning node IDs and tracking dependencies across all categories.

  ## Parameters
  - `ast_body`: Function body AST to process
  - `node_manager`: NodeManager with function parameters configured

  ## Returns
  - `{operations_list, final_node_manager}` tuple

  ## Example

      function_body = quote do
        temp = x + y
        result = temp * 2
        abs(result)
      end
      
      node_manager = NodeManager.new([:x, :y])
      {operations, final_manager} = MultiCategoryExtractor.extract_operations(function_body, node_manager)
      
      # operations = [
      #   %{node_id: 1, op: :+, inputs: [{:function_param, :x}, {:function_param, :y}], ...},
      #   %{node_id: 2, op: :*, inputs: [{:node_reference, 1}, {:literal, 2}], ...},
      #   %{node_id: 3, op: :abs, inputs: [{:node_reference, 2}], ...}
      # ]
  """
  @spec extract_operations(tuple(), NodeManager.t()) :: extraction_result()
  def extract_operations(ast_body, node_manager) do
    case ast_body do
      # Handle sequence blocks directly (before pattern matching)
      {:__block__, _, statements} ->
        extract_sequence_operations(statements, node_manager)
      
      # Handle other patterns through pattern matching
      _ ->
        case PatternMatcher.recognize_pattern(ast_body) do
          # Single expression (no variable assignments)
          {:binary_math, op, operands} ->
            extract_math_operation(op, operands, node_manager, nil)

          {:unary_math, op, operand} ->
            extract_math_operation(op, [operand], node_manager, nil)

          {:function_call, func_name, args} ->
            extract_function_call(func_name, args, node_manager, nil)

          # Variable assignment
          {:variable_assignment, var_name, value_expr} ->
            extract_assignment_operation(var_name, value_expr, node_manager)

          # Control flow patterns
          {:if_then_else, condition, then_branch, else_branch} ->
            extract_conditional_operation(condition, then_branch, else_branch, node_manager)

          {:sequence_block, statements} ->
            extract_sequence_operations(statements, node_manager)

          {:case_switch, value_expr, clauses} ->
            extract_switch_operation(value_expr, clauses, node_manager)

          # Event patterns
          {:event_send, event_name, data} ->
            extract_event_operation(:send, [event_name, data], node_manager, nil)

          {:event_receive, event_name} ->
            extract_event_operation(:receive, [event_name], node_manager, nil)

          # Animation patterns
          {:animation_control, action, target} ->
            extract_animation_operation(action, [target], node_manager, nil)

          # Type conversion patterns
          {:type_conversion, target_type, value} ->
            extract_type_conversion_operation(target_type, [value], node_manager, nil)

          # Literal or variable reference (final expression)
          {:literal, _value} ->
            # No operation needed for literals
            {[], node_manager}

          {:variable_reference, _var_name} ->
            # No operation needed for variable references (they're resolved by DataFlow)
            {[], node_manager}

          # Unsupported patterns
          {:unsupported, reason} ->
            raise ArgumentError, "Unsupported AST pattern: #{reason}"
        end
    end
  end

  @doc """
  Extract a math operation (binary or unary).

  ## Parameters
  - `operation`: Math operation atom (:+, :-, :*, etc.)
  - `operands`: List of operand AST nodes
  - `node_manager`: Current NodeManager state
  - `result_var`: Optional variable name for the result

  ## Returns
  - `{operations_list, updated_manager}` tuple
  """
  @spec extract_math_operation(atom(), [tuple() | any()], NodeManager.t(), atom() | nil) :: 
    extraction_result()
  def extract_math_operation(operation, operands, node_manager, result_var) do
    # Process operands first (they may need their own operations)
    {operand_operations, manager_after_operands} = 
      extract_nested_operations(operands, node_manager)

    # Assign node ID for this operation
    {node_id, manager_with_node} = 
      NodeManager.assign_node_id(manager_after_operands, result_var)

    # Resolve operand references
    {resolved_operands, final_manager} = 
      DataFlow.resolve_operands(operands, manager_with_node, manager_with_node.parameter_names)

    # Create operation info
    operation_info = %{
      node_id: node_id,
      op: operation,
      inputs: resolved_operands,
      result_type: infer_result_type(operation, resolved_operands),
      variable_name: result_var && Atom.to_string(result_var)
    }

    # Add operation to tracking
    final_manager_with_op = NodeManager.add_operation(final_manager, operation_info)

    # Combine all operations
    all_operations = operand_operations ++ [operation_info]
    {all_operations, final_manager_with_op}
  end

  @doc """
  Extract a function call operation.

  ## Parameters
  - `func_name`: Function name atom or qualified name
  - `args`: List of argument AST nodes
  - `node_manager`: Current NodeManager state
  - `result_var`: Optional variable name for the result

  ## Returns
  - `{operations_list, updated_manager}` tuple
  """
  @spec extract_function_call(atom() | tuple(), [tuple() | any()], NodeManager.t(), atom() | nil) :: 
    extraction_result()
  def extract_function_call(func_name, args, node_manager, result_var) do
    # Determine operation type based on function name
    operation_key = case func_name do
      atom when is_atom(atom) -> {atom, length(args)}
      qualified_name -> qualified_name
    end

    # Verify operation is supported
    case OperationRegistry.get_operation_info(operation_key) do
      {:error, :not_found} ->
        raise ArgumentError, "Unsupported function: #{inspect(func_name)}"

      {:ok, op_info} ->
        # Process arguments first
        {arg_operations, manager_after_args} = 
          extract_nested_operations(args, node_manager)

        # Assign node ID
        {node_id, manager_with_node} = 
          NodeManager.assign_node_id(manager_after_args, result_var)

        # Resolve argument references
        {resolved_args, final_manager} = 
          DataFlow.resolve_operands(args, manager_with_node, manager_with_node.parameter_names)

        # Create operation info
        operation_info = %{
          node_id: node_id,
          op: op_info.khr_action,
          inputs: resolved_args,
          result_type: op_info.output_type,
          variable_name: result_var && Atom.to_string(result_var)
        }

        # Add to tracking
        final_manager_with_op = NodeManager.add_operation(final_manager, operation_info)

        # Combine operations
        all_operations = arg_operations ++ [operation_info]
        {all_operations, final_manager_with_op}
    end
  end

  @doc """
  Extract a variable assignment operation.

  ## Parameters
  - `var_name`: Variable name atom
  - `value_expr`: Value expression AST
  - `node_manager`: Current NodeManager state

  ## Returns
  - `{operations_list, updated_manager}` tuple
  """
  @spec extract_assignment_operation(atom(), tuple() | any(), NodeManager.t()) :: 
    extraction_result()
  def extract_assignment_operation(var_name, value_expr, node_manager) do
    # Extract operations for the value expression, assigning result to variable
    case PatternMatcher.recognize_pattern(value_expr) do
      {:binary_math, op, operands} ->
        extract_math_operation(op, operands, node_manager, var_name)

      {:unary_math, op, operand} ->
        extract_math_operation(op, [operand], node_manager, var_name)

      {:function_call, func_name, args} ->
        extract_function_call(func_name, args, node_manager, var_name)

      {:literal, value} ->
        # For literal assignments, create a simple assignment operation
        {node_id, manager_with_node} = NodeManager.assign_node_id(node_manager, var_name)
        
        operation_info = %{
          node_id: node_id,
          op: :literal_assignment,
          inputs: [{:literal, value}],
          result_type: infer_literal_type(value),
          variable_name: Atom.to_string(var_name)
        }

        final_manager = NodeManager.add_operation(manager_with_node, operation_info)
        {[operation_info], final_manager}

      {:variable_reference, source_var} ->
        # Variable-to-variable assignment
        {node_id, manager_with_node} = NodeManager.assign_node_id(node_manager, var_name)
        
        # Resolve source variable
        {resolved_source, final_manager} = 
          DataFlow.resolve_operand(value_expr, manager_with_node, manager_with_node.parameter_names)

        operation_info = %{
          node_id: node_id,
          op: :variable_copy,
          inputs: [resolved_source],
          result_type: :any,
          variable_name: Atom.to_string(var_name)
        }

        final_manager_with_op = NodeManager.add_operation(final_manager, operation_info)
        {[operation_info], final_manager_with_op}

      other ->
        # Recursively extract operations from complex expressions
        {nested_ops, manager_after_nested} = extract_operations(value_expr, node_manager)
        
        # The result of the nested operations is assigned to the variable
        if not Enum.empty?(nested_ops) do
          # Update the last operation to assign to the variable
          last_op = List.last(nested_ops)
          updated_last_op = %{last_op | variable_name: Atom.to_string(var_name)}
          
          # Update variable mapping
          final_manager = %{manager_after_nested | 
            variable_map: Map.put(manager_after_nested.variable_map, 
                                 Atom.to_string(var_name), 
                                 last_op.node_id)
          }
          
          updated_ops = List.replace_at(nested_ops, -1, updated_last_op)
          {updated_ops, final_manager}
        else
          # No operations generated, this shouldn't happen for valid expressions
          raise ArgumentError, "Cannot extract operations from assignment value: #{inspect(value_expr)}"
        end
    end
  end

  @doc """
  Extract operations from a sequence block.

  ## Parameters
  - `statements`: List of statement AST nodes
  - `node_manager`: Current NodeManager state

  ## Returns
  - `{operations_list, updated_manager}` tuple
  """
  @spec extract_sequence_operations([tuple() | any()], NodeManager.t()) :: 
    extraction_result()
  def extract_sequence_operations(statements, node_manager) do
    # Process each statement in sequence, accumulating operations
    {all_operations, final_manager} = 
      Enum.reduce(statements, {[], node_manager}, fn statement, {ops_acc, manager_acc} ->
        {stmt_ops, updated_manager} = extract_operations(statement, manager_acc)
        {ops_acc ++ stmt_ops, updated_manager}
      end)

    {all_operations, final_manager}
  end

  @doc """
  Extract a conditional operation (if-then-else).

  ## Parameters
  - `condition`: Condition expression AST
  - `then_branch`: Then branch AST
  - `else_branch`: Else branch AST
  - `node_manager`: Current NodeManager state

  ## Returns
  - `{operations_list, updated_manager}` tuple
  """
  @spec extract_conditional_operation(tuple() | any(), tuple() | any(), tuple() | any(), NodeManager.t()) :: 
    extraction_result()
  def extract_conditional_operation(condition, then_branch, else_branch, node_manager) do
    # Extract condition operations first
    {condition_ops, manager_after_condition} = extract_operations(condition, node_manager)

    # Extract then branch operations
    {then_ops, manager_after_then} = extract_operations(then_branch, manager_after_condition)

    # Extract else branch operations
    {else_ops, manager_after_else} = extract_operations(else_branch, manager_after_then)

    # Create branch operation
    {node_id, manager_with_node} = NodeManager.assign_node_id(manager_after_else)

    # Resolve condition reference
    {resolved_condition, final_manager} = 
      DataFlow.resolve_operand(condition, manager_with_node, manager_with_node.parameter_names)

    # For now, simplified branch operation - in a full implementation,
    # we'd need to handle the execution paths more sophisticated
    operation_info = %{
      node_id: node_id,
      op: :khr_flow_branch,
      inputs: [resolved_condition, {:literal, then_ops}, {:literal, else_ops}],
      result_type: :any,
      variable_name: nil
    }

    final_manager_with_op = NodeManager.add_operation(final_manager, operation_info)

    # Combine all operations
    all_operations = condition_ops ++ then_ops ++ else_ops ++ [operation_info]
    {all_operations, final_manager_with_op}
  end

  @doc """
  Extract a switch operation (case statement).

  ## Parameters
  - `value_expr`: Switch value expression AST
  - `clauses`: List of case clauses
  - `node_manager`: Current NodeManager state

  ## Returns
  - `{operations_list, updated_manager}` tuple
  """
  @spec extract_switch_operation(tuple() | any(), [tuple()], NodeManager.t()) :: 
    extraction_result()
  def extract_switch_operation(value_expr, clauses, node_manager) do
    # Extract value expression operations
    {value_ops, manager_after_value} = extract_operations(value_expr, node_manager)

    # Extract operations from all clauses
    {clause_operations, manager_after_clauses} = 
      Enum.reduce(clauses, {[], manager_after_value}, fn clause, {ops_acc, manager_acc} ->
        {clause_ops, updated_manager} = extract_clause_operations(clause, manager_acc)
        {ops_acc ++ clause_ops, updated_manager}
      end)

    # Create switch operation
    {node_id, manager_with_node} = NodeManager.assign_node_id(manager_after_clauses)

    # Resolve value reference
    {resolved_value, final_manager} = 
      DataFlow.resolve_operand(value_expr, manager_with_node, manager_with_node.parameter_names)

    operation_info = %{
      node_id: node_id,
      op: :khr_flow_switch,
      inputs: [resolved_value, {:literal, clauses}],
      result_type: :any,
      variable_name: nil
    }

    final_manager_with_op = NodeManager.add_operation(final_manager, operation_info)

    # Combine all operations
    all_operations = value_ops ++ clause_operations ++ [operation_info]
    {all_operations, final_manager_with_op}
  end

  @doc """
  Extract an event operation.

  ## Parameters
  - `event_type`: Event operation type (:send, :receive, etc.)
  - `args`: Event operation arguments
  - `node_manager`: Current NodeManager state
  - `result_var`: Optional variable name for result

  ## Returns
  - `{operations_list, updated_manager}` tuple
  """
  @spec extract_event_operation(atom(), [tuple() | any()], NodeManager.t(), atom() | nil) :: 
    extraction_result()
  def extract_event_operation(event_type, args, node_manager, result_var) do
    # Determine KHR event operation
    khr_op = case event_type do
      :send -> :khr_event_send
      :receive -> :khr_event_receive
      :on_start -> :khr_event_on_start
      :on_tick -> :khr_event_on_tick
      other -> raise ArgumentError, "Unknown event type: #{other}"
    end

    # Process arguments
    {arg_operations, manager_after_args} = extract_nested_operations(args, node_manager)

    # Assign node ID
    {node_id, manager_with_node} = NodeManager.assign_node_id(manager_after_args, result_var)

    # Resolve arguments
    {resolved_args, final_manager} = 
      DataFlow.resolve_operands(args, manager_with_node, manager_with_node.parameter_names)

    operation_info = %{
      node_id: node_id,
      op: khr_op,
      inputs: resolved_args,
      result_type: :boolean,
      variable_name: result_var && Atom.to_string(result_var)
    }

    final_manager_with_op = NodeManager.add_operation(final_manager, operation_info)

    all_operations = arg_operations ++ [operation_info]
    {all_operations, final_manager_with_op}
  end

  @doc """
  Extract an animation operation.

  ## Parameters
  - `action`: Animation action (:start, :stop, :pause, :resume, :is_playing)
  - `args`: Animation operation arguments
  - `node_manager`: Current NodeManager state
  - `result_var`: Optional variable name for result

  ## Returns
  - `{operations_list, updated_manager}` tuple
  """
  @spec extract_animation_operation(atom(), [tuple() | any()], NodeManager.t(), atom() | nil) :: 
    extraction_result()
  def extract_animation_operation(action, args, node_manager, result_var) do
    # Determine KHR animation operation
    khr_op = case action do
      :start -> :khr_animation_start
      :stop -> :khr_animation_stop
      :pause -> :khr_animation_pause
      :resume -> :khr_animation_resume
      :is_playing -> :khr_animation_is_playing
      other -> raise ArgumentError, "Unknown animation action: #{other}"
    end

    # Process arguments
    {arg_operations, manager_after_args} = extract_nested_operations(args, node_manager)

    # Assign node ID
    {node_id, manager_with_node} = NodeManager.assign_node_id(manager_after_args, result_var)

    # Resolve arguments
    {resolved_args, final_manager} = 
      DataFlow.resolve_operands(args, manager_with_node, manager_with_node.parameter_names)

    operation_info = %{
      node_id: node_id,
      op: khr_op,
      inputs: resolved_args,
      result_type: :boolean,
      variable_name: result_var && Atom.to_string(result_var)
    }

    final_manager_with_op = NodeManager.add_operation(final_manager, operation_info)

    all_operations = arg_operations ++ [operation_info]
    {all_operations, final_manager_with_op}
  end

  @doc """
  Extract a type conversion operation.

  ## Parameters
  - `target_type`: Target type (:int, :float, :bool, :string)
  - `args`: Conversion arguments
  - `node_manager`: Current NodeManager state
  - `result_var`: Optional variable name for result

  ## Returns
  - `{operations_list, updated_manager}` tuple
  """
  @spec extract_type_conversion_operation(atom(), [tuple() | any()], NodeManager.t(), atom() | nil) :: 
    extraction_result()
  def extract_type_conversion_operation(target_type, args, node_manager, result_var) do
    # Determine KHR conversion operation
    khr_op = case target_type do
      :int -> :khr_type_to_int
      :float -> :khr_type_to_float
      :bool -> :khr_type_to_bool
      :string -> :khr_type_to_string
      other -> raise ArgumentError, "Unknown type conversion target: #{other}"
    end

    # Process arguments
    {arg_operations, manager_after_args} = extract_nested_operations(args, node_manager)

    # Assign node ID
    {node_id, manager_with_node} = NodeManager.assign_node_id(manager_after_args, result_var)

    # Resolve arguments
    {resolved_args, final_manager} = 
      DataFlow.resolve_operands(args, manager_with_node, manager_with_node.parameter_names)

    result_type = case target_type do
      :int -> :integer
      :float -> :float
      :bool -> :boolean
      :string -> :string
    end

    operation_info = %{
      node_id: node_id,
      op: khr_op,
      inputs: resolved_args,
      result_type: result_type,
      variable_name: result_var && Atom.to_string(result_var)
    }

    final_manager_with_op = NodeManager.add_operation(final_manager, operation_info)

    all_operations = arg_operations ++ [operation_info]
    {all_operations, final_manager_with_op}
  end

  # Private helper functions

  defp extract_nested_operations(operands, node_manager) do
    Enum.reduce(operands, {[], node_manager}, fn operand, {ops_acc, manager_acc} ->
      case PatternMatcher.recognize_pattern(operand) do
        # Simple patterns don't need operations
        {:literal, _} -> {ops_acc, manager_acc}
        {:variable_reference, _} -> {ops_acc, manager_acc}
        
        # Complex patterns need their own operations
        _complex_pattern ->
          {nested_ops, updated_manager} = extract_operations(operand, manager_acc)
          {ops_acc ++ nested_ops, updated_manager}
      end
    end)
  end

  defp extract_clause_operations(clause, node_manager) do
    # Simplified clause extraction - in a full implementation,
    # we'd need to handle pattern matching and guards
    case clause do
      {pattern, body} ->
        extract_operations(body, node_manager)
      {pattern, guard, body} ->
        {guard_ops, manager_after_guard} = extract_operations(guard, node_manager)
        {body_ops, manager_after_body} = extract_operations(body, manager_after_guard)
        {guard_ops ++ body_ops, manager_after_body}
      _ ->
        {[], node_manager}
    end
  end

  defp infer_result_type(operation, _operands) do
    case operation do
      op when op in [:+, :-, :*, :/, :rem] -> :number
      op when op in [:==, :!=, :<, :>, :<=, :>=] -> :boolean
      op when op in [:and, :or, :not] -> :boolean
      :abs -> :number
      :min -> :number
      :max -> :number
      _ -> :any
    end
  end

  defp infer_literal_type(value) do
    cond do
      is_integer(value) -> :integer
      is_float(value) -> :float
      is_boolean(value) -> :boolean
      is_binary(value) -> :string
      true -> :any
    end
  end
end
