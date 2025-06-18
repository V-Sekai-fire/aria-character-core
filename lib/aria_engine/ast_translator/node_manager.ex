defmodule AriaEngine.ASTTranslator.NodeManager do
  @moduledoc """
  Manages sequential node ID assignment and variable-to-node mapping for AST translation.

  The NodeManager ensures each KHR operation gets a unique node ID and tracks which 
  variables are associated with which node results, enabling proper data flow 
  coordination between operations.

  ## Node ID Strategy

  - Sequential assignment: 1, 2, 3, ...
  - Variable mapping: variable name → node ID
  - Dependency tracking: operation → required input node IDs

  ## Example

      manager = NodeManager.new()
      {node_1, manager} = NodeManager.assign_node_id(manager, "temp")
      {node_2, manager} = NodeManager.assign_node_id(manager, "result")
      
      # manager.variable_map = %{"temp" => 1, "result" => 2}
      # manager.next_node_id = 3
  """

  @type t :: %__MODULE__{
    next_node_id: pos_integer(),
    variable_map: %{String.t() => pos_integer()},
    operation_nodes: [operation_info()],
    parameter_names: [atom()]
  }

  @type operation_info :: %{
    node_id: pos_integer(),
    op: atom(),
    inputs: [input_reference()],
    result_type: atom(),
    variable_name: String.t() | nil
  }

  @type input_reference :: 
    {:function_param, atom()} |
    {:node_reference, pos_integer()} |
    {:literal, any()} |
    {:expression, tuple()}

  defstruct [
    :next_node_id,
    :variable_map,
    :operation_nodes,
    :parameter_names
  ]

  @doc """
  Create a new NodeManager with initial state.
  """
  @spec new(parameter_names :: [atom()]) :: t()
  def new(parameter_names \\ []) do
    %__MODULE__{
      next_node_id: 1,
      variable_map: %{},
      operation_nodes: [],
      parameter_names: parameter_names
    }
  end

  @doc """
  Assign the next sequential node ID, optionally associating it with a variable name.

  ## Parameters
  - `manager`: Current NodeManager state
  - `variable_name`: Optional variable name to associate with this node

  ## Returns
  - `{node_id, updated_manager}` tuple

  ## Example

      {node_id, manager} = NodeManager.assign_node_id(manager, "temp_result")
      # node_id = 1, manager.variable_map["temp_result"] = 1
  """
  @spec assign_node_id(t(), String.t() | nil) :: {pos_integer(), t()}
  def assign_node_id(manager, variable_name \\ nil) do
    node_id = manager.next_node_id
    
    updated_variable_map = case variable_name do
      nil -> manager.variable_map
      name when is_binary(name) -> Map.put(manager.variable_map, name, node_id)
      name when is_atom(name) -> Map.put(manager.variable_map, Atom.to_string(name), node_id)
    end
    
    updated_manager = %{manager | 
      next_node_id: node_id + 1,
      variable_map: updated_variable_map
    }
    
    {node_id, updated_manager}
  end

  @doc """
  Get the node ID associated with a variable name.

  ## Parameters
  - `manager`: Current NodeManager state
  - `variable_name`: Variable name to look up

  ## Returns
  - `{:ok, node_id}` if variable exists
  - `:error` if variable not found

  ## Example

      case NodeManager.get_variable_node_id(manager, "temp_result") do
        {:ok, node_id} -> # Use node_id
        :error -> # Variable not found
      end
  """
  @spec get_variable_node_id(t(), String.t() | atom()) :: {:ok, pos_integer()} | :error
  def get_variable_node_id(manager, variable_name) do
    var_name_str = case variable_name do
      name when is_binary(name) -> name
      name when is_atom(name) -> Atom.to_string(name)
    end
    
    case Map.get(manager.variable_map, var_name_str) do
      nil -> :error
      node_id -> {:ok, node_id}
    end
  end

  @doc """
  Check if a name refers to a function parameter.

  ## Parameters
  - `manager`: Current NodeManager state
  - `name`: Name to check

  ## Returns
  - `true` if name is a function parameter
  - `false` otherwise
  """
  @spec is_function_parameter?(t(), atom() | String.t()) :: boolean()
  def is_function_parameter?(manager, name) do
    param_name = case name do
      name when is_binary(name) -> String.to_atom(name)
      name when is_atom(name) -> name
    end
    
    param_name in manager.parameter_names
  end

  @doc """
  Add an operation to the manager's tracking list.

  ## Parameters
  - `manager`: Current NodeManager state
  - `operation_info`: Operation information to track

  ## Returns
  - Updated NodeManager with operation added
  """
  @spec add_operation(t(), operation_info()) :: t()
  def add_operation(manager, operation_info) do
    %{manager | operation_nodes: [operation_info | manager.operation_nodes]}
  end

  @doc """
  Get all tracked operations in execution order (oldest first).
  """
  @spec get_operations_in_order(t()) :: [operation_info()]
  def get_operations_in_order(manager) do
    Enum.reverse(manager.operation_nodes)
  end

  @doc """
  Get the last assigned node ID (for determining final result node).
  """
  @spec get_last_node_id(t()) :: pos_integer() | nil
  def get_last_node_id(manager) do
    if manager.next_node_id > 1 do
      manager.next_node_id - 1
    else
      nil
    end
  end

  @doc """
  Create a new manager with updated parameter names.
  """
  @spec with_parameters(t(), [atom()]) :: t()
  def with_parameters(manager, parameter_names) do
    %{manager | parameter_names: parameter_names}
  end

  @doc """
  Get all variable mappings as a list of {variable_name, node_id} tuples.
  """
  @spec get_variable_mappings(t()) :: [{String.t(), pos_integer()}]
  def get_variable_mappings(manager) do
    Map.to_list(manager.variable_map)
  end

  @doc """
  Check if any operations have been tracked.
  """
  @spec has_operations?(t()) :: boolean()
  def has_operations?(manager) do
    not Enum.empty?(manager.operation_nodes)
  end

  @doc """
  Get operation information by node ID.
  """
  @spec get_operation_by_node_id(t(), pos_integer()) :: operation_info() | nil
  def get_operation_by_node_id(manager, node_id) do
    Enum.find(manager.operation_nodes, fn op -> op.node_id == node_id end)
  end

  @doc """
  Validate that all variable references in operations can be resolved.
  """
  @spec validate_dependencies(t()) :: :ok | {:error, [String.t()]}
  def validate_dependencies(manager) do
    errors = manager.operation_nodes
    |> Enum.flat_map(&validate_operation_dependencies(&1, manager))
    |> Enum.uniq()
    
    case errors do
      [] -> :ok
      errors -> {:error, errors}
    end
  end

  @doc """
  Get statistics about the current node management state.
  """
  @spec get_stats(t()) :: %{
    total_nodes: non_neg_integer(),
    variables_tracked: non_neg_integer(),
    operations_count: non_neg_integer(),
    parameter_count: non_neg_integer()
  }
  def get_stats(manager) do
    %{
      total_nodes: manager.next_node_id - 1,
      variables_tracked: map_size(manager.variable_map),
      operations_count: length(manager.operation_nodes),
      parameter_count: length(manager.parameter_names)
    }
  end

  # Private helper functions

  defp validate_operation_dependencies(operation, manager) do
    operation.inputs
    |> Enum.flat_map(&validate_input_reference(&1, manager))
  end

  defp validate_input_reference(input_ref, manager) do
    case input_ref do
      {:function_param, param_name} ->
        if is_function_parameter?(manager, param_name) do
          []
        else
          ["Unknown function parameter: #{param_name}"]
        end
      
      {:node_reference, node_id} ->
        if get_operation_by_node_id(manager, node_id) do
          []
        else
          ["Reference to non-existent node: #{node_id}"]
        end
      
      {:literal, _value} ->
        []
      
      {:expression, _ast} ->
        ["Unresolved expression found in input reference"]
    end
  end
end
