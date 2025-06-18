defmodule NodeLibrary.KHRInteractivity.TypeConversion do
  @moduledoc """
  KHR_interactivity Type Conversion Nodes

  Implements type conversion operations from the glTF KHR_interactivity specification:
  - khr_type_bool_to_int: Convert boolean to integer
  - khr_type_bool_to_float: Convert boolean to float
  - khr_type_int_to_bool: Convert integer to boolean
  - khr_type_int_to_float: Convert integer to float
  - khr_type_float_to_bool: Convert float to boolean
  - khr_type_float_to_int: Convert float to integer

  All conversions follow standard programming language conventions:
  - true -> 1, false -> 0
  - 0 -> false, non-zero -> true
  - Float to int uses truncation
  """

  alias StateV2
  alias Domain.{Actions, Methods, Core}

  @doc "Register instant action operations"
  @spec register_instant_actions(Core.t()) :: Core.t()
  def register_instant_actions(domain), do: register_actions(domain)

  @doc "Register task methods using exact KHR specification names"
  @spec register_task_methods(Core.t()) :: Core.t()
  def register_task_methods(domain) do
    domain
    |> Methods.add_task_methods("type/bool_to_int", [
      {"basic_conversion", &bool_to_int_task_method/2}
    ])
    |> Methods.add_task_methods("type/bool_to_float", [
      {"basic_conversion", &bool_to_float_task_method/2}
    ])
    |> Methods.add_task_methods("type/int_to_bool", [
      {"basic_conversion", &int_to_bool_task_method/2}
    ])
    |> Methods.add_task_methods("type/int_to_float", [
      {"basic_conversion", &int_to_float_task_method/2}
    ])
    |> Methods.add_task_methods("type/float_to_bool", [
      {"basic_conversion", &float_to_bool_task_method/2}
    ])
    |> Methods.add_task_methods("type/float_to_int", [
      {"basic_conversion", &float_to_int_task_method/2}
    ])
  end

  @doc "Register all type conversion actions with a domain"
  @spec register_actions(Domain.Core.t()) :: Domain.Core.t()
  def register_actions(domain) do
    domain
    |> Actions.add_action(:khr_type_bool_to_int, &bool_to_int/2, %{
      domain: "khr_interactivity",
      category: "type_conversion",
      khr_node_type: "type/bool_to_int",
      description: "Convert boolean to integer (true=1, false=0)"
    })
    |> Actions.add_action(:khr_type_bool_to_float, &bool_to_float/2, %{
      domain: "khr_interactivity",
      category: "type_conversion",
      khr_node_type: "type/bool_to_float",
      description: "Convert boolean to float (true=1.0, false=0.0)"
    })
    |> Actions.add_action(:khr_type_int_to_bool, &int_to_bool/2, %{
      domain: "khr_interactivity",
      category: "type_conversion",
      khr_node_type: "type/int_to_bool",
      description: "Convert integer to boolean (0=false, non-zero=true)"
    })
    |> Actions.add_action(:khr_type_int_to_float, &int_to_float/2, %{
      domain: "khr_interactivity",
      category: "type_conversion",
      khr_node_type: "type/int_to_float",
      description: "Convert integer to float"
    })
    |> Actions.add_action(:khr_type_float_to_bool, &float_to_bool/2, %{
      domain: "khr_interactivity",
      category: "type_conversion",
      khr_node_type: "type/float_to_bool",
      description: "Convert float to boolean (0.0=false, non-zero=true)"
    })
    |> Actions.add_action(:khr_type_float_to_int, &float_to_int/2, %{
      domain: "khr_interactivity",
      category: "type_conversion",
      khr_node_type: "type/float_to_int",
      description: "Convert float to integer (truncation)"
    })
  end

  @doc "Convert boolean to integer"
  def bool_to_int(state, [node_index, value]) when is_boolean(value) do
    result = if value, do: 1, else: 0
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  def bool_to_int(state, [node_index, _value]) do
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", 0)
  end

  @doc "Convert boolean to float"
  def bool_to_float(state, [node_index, value]) when is_boolean(value) do
    result = if value, do: 1.0, else: 0.0
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  def bool_to_float(state, [node_index, _value]) do
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", 0.0)
  end

  @doc "Convert integer to boolean"
  def int_to_bool(state, [node_index, value]) when is_integer(value) do
    result = value != 0
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  def int_to_bool(state, [node_index, _value]) do
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", false)
  end

  @doc "Convert integer to float"
  def int_to_float(state, [node_index, value]) when is_integer(value) do
    result = value * 1.0
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  def int_to_float(state, [node_index, _value]) do
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", 0.0)
  end

  @doc "Convert float to boolean"
  def float_to_bool(state, [node_index, value]) when is_number(value) do
    result = value != 0.0 and not is_nan(value)
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  def float_to_bool(state, [node_index, _value]) do
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", false)
  end

  @doc "Convert float to integer (truncation)"
  def float_to_int(state, [node_index, value]) when is_number(value) do
    result = cond do
      is_nan(value) -> 0
      value == :infinity -> 2_147_483_647  # max int32
      value == :neg_infinity -> -2_147_483_648  # min int32
      true -> trunc(value)
    end
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  def float_to_int(state, [node_index, _value]) do
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", 0)
  end

  # Task method functions - decompose KHR spec strings to atom-based actions

  @doc "Task method for type/bool_to_int - decomposes to atom-based action"
  def bool_to_int_task_method(_state, [node_id, value]) do
    [[:khr_type_bool_to_int, node_id, value]]
  end

  @doc "Task method for type/bool_to_float - decomposes to atom-based action"
  def bool_to_float_task_method(_state, [node_id, value]) do
    [[:khr_type_bool_to_float, node_id, value]]
  end

  @doc "Task method for type/int_to_bool - decomposes to atom-based action"
  def int_to_bool_task_method(_state, [node_id, value]) do
    [[:khr_type_int_to_bool, node_id, value]]
  end

  @doc "Task method for type/int_to_float - decomposes to atom-based action"
  def int_to_float_task_method(_state, [node_id, value]) do
    [[:khr_type_int_to_float, node_id, value]]
  end

  @doc "Task method for type/float_to_bool - decomposes to atom-based action"
  def float_to_bool_task_method(_state, [node_id, value]) do
    [[:khr_type_float_to_bool, node_id, value]]
  end

  @doc "Task method for type/float_to_int - decomposes to atom-based action"
  def float_to_int_task_method(_state, [node_id, value]) do
    [[:khr_type_float_to_int, node_id, value]]
  end

  # Helper function to check for NaN
  defp is_nan(value) when is_float(value) do
    value != value
  end
  
  defp is_nan(:nan), do: true
  defp is_nan(_), do: false
end
