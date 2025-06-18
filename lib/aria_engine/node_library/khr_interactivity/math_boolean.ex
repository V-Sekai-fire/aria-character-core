defmodule AriaEngine.NodeLibrary.KHRInteractivity.MathBoolean do
  @moduledoc """
  KHR_interactivity Math Boolean Operations

  Implements boolean logical operations from the glTF KHR_interactivity specification:
  - math/boolean/and: Logical AND operation
  - math/boolean/or: Logical OR operation
  - math/boolean/not: Logical NOT operation
  - math/boolean/xor: Logical XOR (exclusive OR) operation
  - math/boolean/nand: Logical NAND (NOT AND) operation
  - math/boolean/nor: Logical NOR (NOT OR) operation
  - math/boolean/equal: Boolean equality comparison
  - math/boolean/not_equal: Boolean inequality comparison

  All operations follow standard boolean logic rules and handle type coercion
  for non-boolean inputs according to programming language conventions.
  """

  alias AriaEngine.StateV2
  alias AriaEngine.Domain.{Actions, Methods, Core}

  @doc "Register instant action operations"
  @spec register_instant_actions(Core.t()) :: Core.t()
  def register_instant_actions(domain), do: register_actions(domain)

  @doc "Register task methods using exact KHR specification names"
  @spec register_task_methods(Core.t()) :: Core.t()
  def register_task_methods(domain) do
    domain
    |> Methods.add_task_methods("math/boolean/and", [
      {"basic_operation", &boolean_and_task_method/2}
    ])
    |> Methods.add_task_methods("math/boolean/or", [
      {"basic_operation", &boolean_or_task_method/2}
    ])
    |> Methods.add_task_methods("math/boolean/not", [
      {"basic_operation", &boolean_not_task_method/2}
    ])
    |> Methods.add_task_methods("math/boolean/xor", [
      {"basic_operation", &boolean_xor_task_method/2}
    ])
    |> Methods.add_task_methods("math/boolean/nand", [
      {"basic_operation", &boolean_nand_task_method/2}
    ])
    |> Methods.add_task_methods("math/boolean/nor", [
      {"basic_operation", &boolean_nor_task_method/2}
    ])
    |> Methods.add_task_methods("math/boolean/equal", [
      {"basic_operation", &boolean_equal_task_method/2}
    ])
    |> Methods.add_task_methods("math/boolean/not_equal", [
      {"basic_operation", &boolean_not_equal_task_method/2}
    ])
  end

  @doc "Register all boolean math actions with a domain"
  @spec register_actions(Core.t()) :: Core.t()
  def register_actions(domain) do
    domain
    |> Actions.add_action(:khr_math_boolean_and, &boolean_and/2, %{
      domain: "khr_interactivity",
      category: "math_boolean",
      khr_node_type: "math/boolean/and",
      description: "Logical AND operation on two boolean values"
    })
    |> Actions.add_action(:khr_math_boolean_or, &boolean_or/2, %{
      domain: "khr_interactivity",
      category: "math_boolean",
      khr_node_type: "math/boolean/or",
      description: "Logical OR operation on two boolean values"
    })
    |> Actions.add_action(:khr_math_boolean_not, &boolean_not/2, %{
      domain: "khr_interactivity",
      category: "math_boolean",
      khr_node_type: "math/boolean/not",
      description: "Logical NOT operation on a boolean value"
    })
    |> Actions.add_action(:khr_math_boolean_xor, &boolean_xor/2, %{
      domain: "khr_interactivity",
      category: "math_boolean",
      khr_node_type: "math/boolean/xor",
      description: "Logical XOR (exclusive OR) operation on two boolean values"
    })
    |> Actions.add_action(:khr_math_boolean_nand, &boolean_nand/2, %{
      domain: "khr_interactivity",
      category: "math_boolean",
      khr_node_type: "math/boolean/nand",
      description: "Logical NAND (NOT AND) operation on two boolean values"
    })
    |> Actions.add_action(:khr_math_boolean_nor, &boolean_nor/2, %{
      domain: "khr_interactivity",
      category: "math_boolean",
      khr_node_type: "math/boolean/nor",
      description: "Logical NOR (NOT OR) operation on two boolean values"
    })
    |> Actions.add_action(:khr_math_boolean_equal, &boolean_equal/2, %{
      domain: "khr_interactivity",
      category: "math_boolean",
      khr_node_type: "math/boolean/equal",
      description: "Boolean equality comparison"
    })
    |> Actions.add_action(:khr_math_boolean_not_equal, &boolean_not_equal/2, %{
      domain: "khr_interactivity",
      category: "math_boolean",
      khr_node_type: "math/boolean/not_equal",
      description: "Boolean inequality comparison"
    })
  end

  @doc "Logical AND operation"
  def boolean_and(state, [node_index, a, b]) do
    bool_a = to_boolean(a)
    bool_b = to_boolean(b)
    
    result = bool_a and bool_b
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  @doc "Logical OR operation"
  def boolean_or(state, [node_index, a, b]) do
    bool_a = to_boolean(a)
    bool_b = to_boolean(b)
    
    result = bool_a or bool_b
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  @doc "Logical NOT operation"
  def boolean_not(state, [node_index, value]) do
    bool_value = to_boolean(value)
    
    result = not bool_value
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  @doc "Logical XOR (exclusive OR) operation"
  def boolean_xor(state, [node_index, a, b]) do
    bool_a = to_boolean(a)
    bool_b = to_boolean(b)
    
    # XOR: true when exactly one input is true
    result = (bool_a and not bool_b) or (not bool_a and bool_b)
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  @doc "Logical NAND (NOT AND) operation"
  def boolean_nand(state, [node_index, a, b]) do
    bool_a = to_boolean(a)
    bool_b = to_boolean(b)
    
    # NAND: NOT (A AND B)
    result = not (bool_a and bool_b)
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  @doc "Logical NOR (NOT OR) operation"
  def boolean_nor(state, [node_index, a, b]) do
    bool_a = to_boolean(a)
    bool_b = to_boolean(b)
    
    # NOR: NOT (A OR B)
    result = not (bool_a or bool_b)
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  @doc "Boolean equality comparison"
  def boolean_equal(state, [node_index, a, b]) do
    bool_a = to_boolean(a)
    bool_b = to_boolean(b)
    
    result = bool_a == bool_b
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  @doc "Boolean inequality comparison"
  def boolean_not_equal(state, [node_index, a, b]) do
    bool_a = to_boolean(a)
    bool_b = to_boolean(b)
    
    result = bool_a != bool_b
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  # Helper function to convert values to boolean following programming conventions
  defp to_boolean(value) do
    case value do
      # Boolean values
      true -> true
      false -> false
      
      # Numeric values (0 = false, non-zero = true)
      0 -> false
      n when is_number(n) and n == 0.0 -> false
      n when is_number(n) -> n != 0
      
      # String values (empty = false, non-empty = true)
      "" -> false
      s when is_binary(s) -> String.length(s) > 0
      
      # Collections (empty = false, non-empty = true)
      [] -> false
      %{} -> false
      list when is_list(list) -> length(list) > 0
      map when is_map(map) -> map_size(map) > 0
      
      # Atoms (nil = false, others = true)
      nil -> false
      atom when is_atom(atom) -> true
      
      # Special float values
      :nan -> false
      :infinity -> true
      :neg_infinity -> true
      
      # Everything else defaults to true
      _ -> true
    end
  end

  # Task method functions - decompose KHR spec strings to atom-based actions

  @doc "Task method for math/boolean/and - decomposes to atom-based action"
  def boolean_and_task_method(_state, [node_id, a, b]) do
    [[:khr_math_boolean_and, node_id, a, b]]
  end

  @doc "Task method for math/boolean/or - decomposes to atom-based action"
  def boolean_or_task_method(_state, [node_id, a, b]) do
    [[:khr_math_boolean_or, node_id, a, b]]
  end

  @doc "Task method for math/boolean/not - decomposes to atom-based action"
  def boolean_not_task_method(_state, [node_id, value]) do
    [[:khr_math_boolean_not, node_id, value]]
  end

  @doc "Task method for math/boolean/xor - decomposes to atom-based action"
  def boolean_xor_task_method(_state, [node_id, a, b]) do
    [[:khr_math_boolean_xor, node_id, a, b]]
  end

  @doc "Task method for math/boolean/nand - decomposes to atom-based action"
  def boolean_nand_task_method(_state, [node_id, a, b]) do
    [[:khr_math_boolean_nand, node_id, a, b]]
  end

  @doc "Task method for math/boolean/nor - decomposes to atom-based action"
  def boolean_nor_task_method(_state, [node_id, a, b]) do
    [[:khr_math_boolean_nor, node_id, a, b]]
  end

  @doc "Task method for math/boolean/equal - decomposes to atom-based action"
  def boolean_equal_task_method(_state, [node_id, a, b]) do
    [[:khr_math_boolean_equal, node_id, a, b]]
  end

  @doc "Task method for math/boolean/not_equal - decomposes to atom-based action"
  def boolean_not_equal_task_method(_state, [node_id, a, b]) do
    [[:khr_math_boolean_not_equal, node_id, a, b]]
  end
end
