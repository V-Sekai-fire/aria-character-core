defmodule AriaEngine.ASTTranslator.DataFlow do
  @moduledoc """
  Data flow resolution and dependency tracking for AST translation.

  Manages how data flows between KHR nodes by resolving operands, tracking
  dependencies, and building execution sequences that respect node dependencies.

  ## Data Flow Types

  - **Function parameters**: Direct values passed to the translated function
  - **Node references**: Results from previous node executions
  - **Literals**: Constant values that don't require computation
  - **Variable references**: Named variables mapped to specific node IDs

  ## Node Communication

  All KHR nodes store results in StateV2 facts using the pattern:
  `StateV2.set_fact(state, node_id_string, "value", result)`

  Results are retrieved using:
  `StateV2.get_fact(state, node_id_string, "value")`

  ## Usage

      # Resolve operands for a binary operation
      operands = [left_operand, right_operand]
      {resolved_operands, manager} = DataFlow.resolve_operands(operands, node_manager, params)
      
      # Build execution sequence from operations
      execution_sequence = DataFlow.build_execution_sequence(operations, final_manager)
  """

  alias AriaEngine.ASTTranslator.{NodeManager, PatternMatcher, OperationRegistry}

  @type operand_reference ::
    {:function_param, atom()} |
    {:node_reference, pos_integer()} |
    {:literal, any()} |
    {:needs_node, tuple()}

  @type resolved_operand ::
    {:param_value, atom()} |
    {:node_result, pos_integer()} |
    {:literal_value, any()}

  @type execution_step :: {atom(), [any()]}

  @doc """
  Resolve a single operand in the context of available data sources.

  ## Parameters
  - `operand`: AST node representing the operand
  - `node_manager`: Current NodeManager state
  - `function_params`: List of function parameter names

  ## Returns
  - `{operand_reference, updated_manager}` tuple

  ## Examples

      # Function parameter
      {operand_ref, manager} = DataFlow.resolve_operand({:x, [], nil}, manager, [:x, :y])
      # operand_ref = {:function_param, :x}

      # Literal value
      {operand_ref, manager} = DataFlow.resolve_operand(42, manager, [])
      # operand_ref = {:literal, 42}

      # Variable reference
      {operand_ref, manager} = DataFlow.resolve_operand({:temp, [], nil}, manager, [])
      # operand_ref = {:node_reference, 1} (if temp was assigned to node 1)
  """
  @spec resolve_operand(tuple() | any(), NodeManager.t(), [atom()]) :: 
    {operand_reference(), NodeManager.t()}
  def resolve_operand(operand, node_manager, function_params) do
    case PatternMatcher.recognize_pattern(operand) do
      # Literal values
      {:literal, value} ->
        {{:literal, value}, node_manager}

      # Variable reference
      {:variable_reference, var_name} ->
        cond do
          # Check if it's a function parameter
          var_name in function_params ->
            {{:function_param, var_name}, node_manager}

          # Check if it's a previously assigned variable
          NodeManager.get_variable_node_id(node_manager, var_name) != :error ->
            {:ok, node_id} = NodeManager.get_variable_node_id(node_manager, var_name)
            {{:node_reference, node_id}, node_manager}

          # Unknown variable
          true ->
            raise ArgumentError, "Unknown variable reference: #{var_name}"
        end

      # Complex expression that needs its own node
      _complex_pattern ->
        {{:needs_node, operand}, node_manager}
    end
  end

  @doc """
  Resolve multiple operands for an operation.

  ## Parameters
  - `operands`: List of AST nodes representing operands
  - `node_manager`: Current NodeManager state  
  - `function_params`: List of function parameter names

  ## Returns
  - `{[operand_reference], updated_manager}` tuple
  """
  @spec resolve_operands([tuple() | any()], NodeManager.t(), [atom()]) :: 
    {[operand_reference()], NodeManager.t()}
  def resolve_operands(operands, node_manager, function_params) do
    Enum.map_reduce(operands, node_manager, fn operand, manager_acc ->
      resolve_operand(operand, manager_acc, function_params)
    end)
  end

  @doc """
  Build an execution sequence from a list of operations.

  Takes the operations extracted by MultiCategoryExtractor and converts them
  into a sequence of executable steps that can be run in order.

  ## Parameters
  - `operations`: List of operation info structs
  - `node_manager`: Final NodeManager state after extraction

  ## Returns
  - List of execution steps in dependency order

  ## Example

      operations = [
        %{node_id: 1, op: :khr_math_add, inputs: [{:function_param, :x}, {:function_param, :y}]},
        %{node_id: 2, op: :khr_math_mul, inputs: [{:node_reference, 1}, {:literal, 2}]}
      ]
      
      sequence = DataFlow.build_execution_sequence(operations, manager)
      # [
      #   {:khr_math_add, [1, {:param_value, :x}, {:param_value, :y}]},
      #   {:khr_math_mul, [2, {:node_result, 1}, {:literal_value, 2}]}
      # ]
  """
  @spec build_execution_sequence([NodeManager.operation_info()], NodeManager.t()) :: 
    [execution_step()]
  def build_execution_sequence(operations, node_manager) do
    # Sort operations by node_id to ensure dependency order
    sorted_operations = Enum.sort_by(operations, & &1.node_id)
    
    Enum.map(sorted_operations, fn operation ->
      # Convert KHR operation to action name
      khr_action = get_khr_action_for_operation(operation.op)
      
      # Resolve inputs to execution arguments
      resolved_inputs = resolve_operation_inputs(operation.inputs, node_manager)
      
      # Build execution step: action + [node_id | resolved_inputs]
      {khr_action, [operation.node_id | resolved_inputs]}
    end)
  end

  @doc """
  Validate that an execution sequence has proper dependencies.

  ## Parameters
  - `execution_sequence`: List of execution steps
  - `function_params`: List of function parameter names

  ## Returns
  - `:ok` if dependencies are valid
  - `{:error, [issues]}` if there are dependency problems
  """
  @spec validate_execution_dependencies([execution_step()], [atom()]) :: 
    :ok | {:error, [String.t()]}
  def validate_execution_dependencies(execution_sequence, function_params) do
    # Track which nodes have been executed
    {_final_executed, errors} = Enum.reduce(execution_sequence, {MapSet.new(), []}, 
      fn {_action, [node_id | args]}, {executed_nodes, errors_acc} ->
        # Check if all node references in args are satisfied
        step_errors = validate_step_dependencies(args, executed_nodes, function_params)
        
        # Add this node to executed set
        updated_executed = MapSet.put(executed_nodes, node_id)
        
        {updated_executed, errors_acc ++ step_errors}
      end)
    
    case errors do
      [] -> :ok
      errors -> {:error, errors}
    end
  end

  @doc """
  Get the final result node ID from an execution sequence.

  ## Parameters
  - `execution_sequence`: List of execution steps

  ## Returns
  - Node ID of the final result, or nil if sequence is empty
  """
  @spec get_final_result_node_id([execution_step()]) :: pos_integer() | nil
  def get_final_result_node_id([]), do: nil
  def get_final_result_node_id(execution_sequence) do
    {_action, [node_id | _args]} = List.last(execution_sequence)
    node_id
  end

  @doc """
  Optimize an execution sequence by removing redundant operations.

  ## Parameters
  - `execution_sequence`: List of execution steps

  ## Returns
  - Optimized execution sequence
  """
  @spec optimize_execution_sequence([execution_step()]) :: [execution_step()]
  def optimize_execution_sequence(execution_sequence) do
    # For now, return as-is. Future optimizations could include:
    # - Dead code elimination
    # - Constant folding
    # - Common subexpression elimination
    execution_sequence
  end

  @doc """
  Generate parameter binding code for an execution sequence.

  ## Parameters
  - `function_params`: List of function parameter names
  - `param_values_var`: Variable name for parameter values list

  ## Returns
  - Code that binds parameters to a map
  """
  @spec generate_parameter_binding([atom()], atom()) :: tuple()
  def generate_parameter_binding(function_params, param_values_var \\ :param_values) do
    quote do
      param_map = unquote(function_params)
                 |> Enum.zip(unquote(param_values_var))
                 |> Map.new()
    end
  end

  @doc """
  Generate code to resolve execution arguments at runtime.

  ## Returns
  - Function code that resolves argument references
  """
  @spec generate_argument_resolver() :: tuple()
  def generate_argument_resolver do
    quote do
      defp resolve_execution_args(args, state, param_map) do
        Enum.map(args, fn
          {:param_value, param_name} -> 
            Map.get(param_map, param_name)
          
          {:node_result, node_id} ->
            StateV2.get_fact(state, Integer.to_string(node_id), "value")
          
          {:literal_value, value} ->
            value
          
          direct_value ->
            direct_value
        end)
      end
    end
  end

  @doc """
  Generate code to execute a KHR action.

  ## Returns
  - Function code that executes KHR actions
  """
  @spec generate_action_executor() :: tuple()
  def generate_action_executor do
    quote do
      defp execute_khr_action(state, action_name, args) do
        # Map KHR action names to actual module functions
        case action_name do
          # Math operations
          :khr_math_add -> apply(AriaEngine.NodeLibrary.KHRInteractivity.MathInteger, :integer_add, [state, args])
          :khr_math_sub -> apply(AriaEngine.NodeLibrary.KHRInteractivity.MathInteger, :integer_sub, [state, args])
          :khr_math_mul -> apply(AriaEngine.NodeLibrary.KHRInteractivity.MathInteger, :integer_mul, [state, args])
          :khr_math_div -> apply(AriaEngine.NodeLibrary.KHRInteractivity.MathInteger, :integer_div, [state, args])
          :khr_math_rem -> apply(AriaEngine.NodeLibrary.KHRInteractivity.MathInteger, :integer_rem, [state, args])
          :khr_math_abs -> apply(AriaEngine.NodeLibrary.KHRInteractivity.MathInteger, :integer_abs, [state, args])
          :khr_math_min -> apply(AriaEngine.NodeLibrary.KHRInteractivity.MathInteger, :integer_min, [state, args])
          :khr_math_max -> apply(AriaEngine.NodeLibrary.KHRInteractivity.MathInteger, :integer_max, [state, args])
          
          # Comparison operations  
          :khr_math_equal -> apply(AriaEngine.NodeLibrary.KHRInteractivity.MathInteger, :integer_equal, [state, args])
          :khr_math_not_equal -> apply(AriaEngine.NodeLibrary.KHRInteractivity.MathInteger, :integer_not_equal, [state, args])
          :khr_math_less_than -> apply(AriaEngine.NodeLibrary.KHRInteractivity.MathInteger, :integer_less_than, [state, args])
          :khr_math_greater_than -> apply(AriaEngine.NodeLibrary.KHRInteractivity.MathInteger, :integer_greater_than, [state, args])
          
          # Control flow operations
          :khr_flow_branch -> apply(AriaEngine.NodeLibrary.KHRInteractivity.ControlFlow, :branch, [state, args])
          :khr_flow_sequence -> apply(AriaEngine.NodeLibrary.KHRInteractivity.ControlFlow, :sequence, [state, args])
          
          # Variable operations
          :khr_variable_get -> apply(AriaEngine.NodeLibrary.KHRInteractivity.Variables, :get, [state, args])
          :khr_variable_set -> apply(AriaEngine.NodeLibrary.KHRInteractivity.Variables, :set, [state, args])
          
          # Default case for unmapped actions
          unknown_action ->
            raise ArgumentError, "Unknown KHR action: #{unknown_action}"
        end
      end
    end
  end

  # Private helper functions

  defp get_khr_action_for_operation(operation_atom) do
    # Convert operation atoms to KHR action names
    case operation_atom do
      :+ -> :khr_math_add
      :- -> :khr_math_sub  
      :* -> :khr_math_mul
      :/ -> :khr_math_div
      :rem -> :khr_math_rem
      :abs -> :khr_math_abs
      :min -> :khr_math_min
      :max -> :khr_math_max
      :== -> :khr_math_equal
      :!= -> :khr_math_not_equal
      :< -> :khr_math_less_than
      :> -> :khr_math_greater_than
      :<= -> :khr_math_less_equal
      :>= -> :khr_math_greater_equal
      
      # Control flow
      :if_then_else -> :khr_flow_branch
      :sequence -> :khr_flow_sequence
      
      # Variables
      :get_var -> :khr_variable_get
      :set_var -> :khr_variable_set
      
      # Animation
      :start_animation -> :khr_animation_start
      :stop_animation -> :khr_animation_stop
      
      # Events
      :send_event -> :khr_event_send
      :receive_event -> :khr_event_receive
      
      # Type conversion
      :to_int -> :khr_type_to_int
      :to_float -> :khr_type_to_float
      :to_bool -> :khr_type_to_bool
      
      # Direct KHR operations (already mapped)
      khr_op when is_atom(khr_op) and khr_op != nil ->
        khr_op
      
      unknown ->
        raise ArgumentError, "Unknown operation for KHR mapping: #{inspect(unknown)}"
    end
  end

  defp resolve_operation_inputs(inputs, _node_manager) do
    Enum.map(inputs, fn input_ref ->
      case input_ref do
        {:function_param, param_name} -> {:param_value, param_name}
        {:node_reference, node_id} -> {:node_result, node_id}
        {:literal, value} -> {:literal_value, value}
        direct_value -> direct_value  # Pass through other values as-is
      end
    end)
  end

  defp validate_step_dependencies(args, executed_nodes, function_params) do
    Enum.flat_map(args, fn arg ->
      case arg do
        {:param_value, param_name} ->
          if param_name in function_params do
            []
          else
            ["Unknown function parameter: #{param_name}"]
          end
        
        {:node_result, node_id} ->
          if node_id in executed_nodes do
            []
          else
            ["Reference to unexecuted node: #{node_id}"]
          end
        
        {:literal_value, _value} ->
          []
        
        _other ->
          []
      end
    end)
  end

  @doc """
  Create a dependency graph from an execution sequence.

  ## Parameters
  - `execution_sequence`: List of execution steps

  ## Returns
  - Map representing the dependency graph
  """
  @spec create_dependency_graph([execution_step()]) :: %{pos_integer() => [pos_integer()]}
  def create_dependency_graph(execution_sequence) do
    Enum.reduce(execution_sequence, %{}, fn {_action, [node_id | args]}, graph ->
      dependencies = extract_node_dependencies(args)
      Map.put(graph, node_id, dependencies)
    end)
  end

  defp extract_node_dependencies(args) do
    Enum.flat_map(args, fn arg ->
      case arg do
        {:node_result, dep_node_id} -> [dep_node_id]
        _other -> []
      end
    end)
  end

  @doc """
  Check if an execution sequence is topologically sorted.

  ## Parameters
  - `execution_sequence`: List of execution steps

  ## Returns
  - `true` if properly sorted, `false` otherwise
  """
  @spec topologically_sorted?([execution_step()]) :: boolean()
  def topologically_sorted?(execution_sequence) do
    {_executed, is_sorted} = Enum.reduce_while(execution_sequence, {MapSet.new(), true}, 
      fn {_action, [node_id | args]}, {executed_nodes, _} ->
        dependencies = extract_node_dependencies(args)
        
        if Enum.all?(dependencies, &(&1 in executed_nodes)) do
          {:cont, {MapSet.put(executed_nodes, node_id), true}}
        else
          {:halt, {executed_nodes, false}}
        end
      end)
    
    is_sorted
  end
end
