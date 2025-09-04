defmodule AriaInteractivity.NodeParser do
  @moduledoc """
  glTF Node Parser for Interactivity Extension

  Parses glTF interactivity nodes from the specification and converts them
  to planning domain elements that can be used with aria-hybrid-planner.

  Based on glTF Specification.adoc and ADR R25W167INT
  """

  alias AriaInteractivity.Domain
  alias AriaInteractivity.Temporal

  # ============================================================================
  # GLTF NODE TYPE MAPPINGS
  # ============================================================================

  # Map glTF node operations to domain functions
  @gltf_to_domain_mapping %{
    # Math Operations
    "math/add" => :math_add,
    "math/subtract" => :math_subtract,
    "math/multiply" => :math_multiply,
    "math/divide" => :math_divide,
    "math/abs" => :math_abs,
    "math/sin" => :math_sin,
    "math/cos" => :math_cos,
    "math/sqrt" => :math_sqrt,
    "math/pow" => :math_pow,
    "math/min" => :math_min,
    "math/max" => :math_max,

    # Flow Control
    "flow/sequence" => :flow_sequence,
    "flow/branch" => :flow_branch,
    "flow/while" => :flow_while,
    "flow/for" => :flow_for,

    # State Operations
    "variable/get" => :get_variable,
    "variable/set" => :set_variable,

    # Animation Control
    "animation/start" => :play_animation,
    "animation/stop" => :stop_animation,

    # Event Handling
    "event/send" => :trigger_event,
    "event/receive" => :receive_event
  }

  # ============================================================================
  # NODE PARSING
  # ============================================================================

  @doc """
  Parse a glTF interactivity node and convert to planning domain call
  """
  @spec parse_node(map(), AriaState.t()) :: {:ok, term()} | {:error, atom()}
  def parse_node(node, state) do
    operation = node["operation"]
    values = node["values"] || %{}
    configuration = node["configuration"] || %{}

    case Map.get(@gltf_to_domain_mapping, operation) do
      nil ->
        {:error, :unsupported_operation}

      domain_function ->
        # Convert glTF node values to domain function arguments
        args = convert_node_values(values, configuration, operation)

        # Call the appropriate domain function
        apply(Domain, domain_function, [state, args])
    end
  end

  @doc """
  Parse multiple glTF nodes and return combined planning result
  """
  @spec parse_nodes([map()], AriaState.t()) :: {:ok, [AriaEngine.todo_item()]} | {:error, atom()}
  def parse_nodes(nodes, state) do
    results = Enum.map(nodes, fn node ->
      case parse_node(node, state) do
        {:ok, result} -> result
        {:error, reason} -> {:error, reason}
      end
    end)

    # Check for errors
    errors = Enum.filter(results, fn
      {:error, _} -> true
      _ -> false
    end)

    if errors != [] do
      {:error, :node_parsing_failed}
    else
      # Combine all results
      combined_todo_items = Enum.flat_map(results, fn
        {:ok, items} when is_list(items) -> items
        {:ok, item} -> [item]
        _ -> []
      end)

      {:ok, combined_todo_items}
    end
  end

  # ============================================================================
  # GLTF BEHAVIOR GRAPH TO PLANNING PROBLEM CONVERSION
  # ============================================================================

  @doc """
  Convert glTF behavior graph to planning problem
  """
  @spec graph_to_planning_problem(map()) :: {:ok, map()} | {:error, atom()}
  def graph_to_planning_problem(graph) do
    nodes = graph["nodes"] || []
    variables = graph["variables"] || []
    events = graph["events"] || []

    # Parse initial state from variables
    initial_state = build_initial_state(variables)

    # Parse goal from graph structure
    goal = extract_goal_from_graph(graph)

    # Parse operators from nodes
    operators = extract_operators_from_nodes(nodes)

    {:ok, %{
      initial_state: initial_state,
      goal: goal,
      operators: operators,
      domain: :aria_interactivity
    }}
  end

  @doc """
  Convert glTF node connections to task dependencies
  """
  @spec extract_dependencies([map()]) :: [map()]
  def extract_dependencies(nodes) do
    Enum.flat_map(nodes, fn node ->
      flows = node["flows"] || %{}

      Enum.map(flows, fn {socket_id, connection} ->
        %{
          from_node: node["id"],
          from_socket: socket_id,
          to_node: connection["node"],
          to_socket: connection["socket"] || "in",
          dependency_type: :flow_dependency
        }
      end)
    end)
  end

  # ============================================================================
  # VALUE CONVERSION HELPERS
  # ============================================================================

  # Convert glTF node values to domain function arguments
  defp convert_node_values(values, configuration, operation) do
    case operation do
      # Math operations: extract a and b values
      "math/" <> _ ->
        a = get_value(values["a"])
        b = get_value(values["b"])
        [a, b]

      # Flow control: extract condition and branches
      "flow/branch" ->
        condition = get_value(values["condition"])
        true_branch = get_value(values["true"])
        false_branch = get_value(values["false"])
        [condition, true_branch, false_branch]

      # Variable operations: extract variable name and value
      "variable/" <> _ ->
        variable = configuration["variable"]
        value = get_value(values["value"])
        {String.to_atom(variable), value}

      # Animation operations: extract animation parameters
      "animation/" <> _ ->
        animation = get_value(values["animation"])
        start_time = get_value(values["startTime"]) || 0
        end_time = get_value(values["endTime"])
        speed = get_value(values["speed"]) || 1.0
        [animation, start_time, end_time, speed]

      # Event operations: extract event parameters
      "event/" <> _ ->
        event = configuration["event"]
        data = get_value(values["data"])
        {String.to_atom(event), data}

      # Default: return all values as list
      _ ->
        Enum.map(values, fn {_key, value} -> get_value(value) end)
    end
  end

  # Extract value from glTF value structure
  defp get_value(value_struct) do
    case value_struct do
      %{"value" => [value]} -> value
      %{"value" => value} when is_list(value) -> value
      %{"value" => value} -> value
      %{"node" => node_id, "socket" => socket_id} ->
        # Reference to another node's output
        {:node_ref, node_id, socket_id}
      %{"node" => node_id} ->
        # Reference to another node's default output
        {:node_ref, node_id, "value"}
      nil -> nil
      _ -> value_struct
    end
  end

  # ============================================================================
  # PLANNING PROBLEM BUILDING
  # ============================================================================

  # Build initial state from glTF variables
  defp build_initial_state(variables) do
    Enum.reduce(variables, %{}, fn variable, state ->
      name = variable["name"]
      value = variable["value"] || [0]
      Map.put(state, String.to_atom(name), value)
    end)
  end

  # Extract goal from graph structure
  defp extract_goal_from_graph(graph) do
    # For now, return a simple goal - this would be more complex
    # in a full implementation based on graph analysis
    %{
      type: :composite_goal,
      goals: [
        {:variable_set, "completion_flag", true}
      ]
    }
  end

  # Extract operators from nodes
  defp extract_operators_from_nodes(nodes) do
    Enum.map(nodes, fn node ->
      operation = node["operation"]
      id = node["id"]

      %{
        name: String.to_atom("node_#{id}"),
        operation: operation,
        parameters: extract_node_parameters(node),
        preconditions: [],
        effects: extract_node_effects(node)
      }
    end)
  end

  # Extract parameters from node
  defp extract_node_parameters(node) do
    values = node["values"] || %{}
    Enum.map(values, fn {key, _value} ->
      String.to_atom(key)
    end)
  end

  # Extract effects from node
  defp extract_node_effects(node) do
    operation = node["operation"]

    case operation do
      "math/" <> _ -> [{:set_fact, "math_result", :computed}]
      "variable/set" -> [{:set_variable, :variable_name, :value}]
      "animation/start" -> [{:set_fact, "animation_playing", true}]
      "event/send" -> [{:trigger_event, :event_name}]
      _ -> []
    end
  end
end
