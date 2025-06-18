defmodule NodeLibrary.KHRInteractivity.MathBitwise do
  @moduledoc """
  KHR_interactivity Math Bitwise Operations

  Implements bitwise operations from the glTF KHR_interactivity specification:
  - math/bitwise/and: Bitwise AND operation
  - math/bitwise/or: Bitwise OR operation
  - math/bitwise/xor: Bitwise XOR (exclusive OR) operation
  - math/bitwise/not: Bitwise NOT (complement) operation
  - math/bitwise/left_shift: Left bit shift operation
  - math/bitwise/right_shift: Right bit shift operation
  - math/bitwise/test_bit: Test if specific bit is set
  - math/bitwise/set_bit: Set specific bit to 1
  - math/bitwise/clear_bit: Clear specific bit to 0
  - math/bitwise/toggle_bit: Toggle specific bit

  All operations work on 32-bit signed integers and follow standard bitwise logic.
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
    |> Methods.add_task_methods("math/bitwise/and", [
      {"basic_operation", &bitwise_and_task_method/2}
    ])
    |> Methods.add_task_methods("math/bitwise/or", [
      {"basic_operation", &bitwise_or_task_method/2}
    ])
    |> Methods.add_task_methods("math/bitwise/xor", [
      {"basic_operation", &bitwise_xor_task_method/2}
    ])
    |> Methods.add_task_methods("math/bitwise/not", [
      {"basic_operation", &bitwise_not_task_method/2}
    ])
    |> Methods.add_task_methods("math/bitwise/left_shift", [
      {"basic_operation", &bitwise_left_shift_task_method/2}
    ])
    |> Methods.add_task_methods("math/bitwise/right_shift", [
      {"basic_operation", &bitwise_right_shift_task_method/2}
    ])
    |> Methods.add_task_methods("math/bitwise/test_bit", [
      {"basic_operation", &bitwise_test_bit_task_method/2}
    ])
    |> Methods.add_task_methods("math/bitwise/set_bit", [
      {"basic_operation", &bitwise_set_bit_task_method/2}
    ])
    |> Methods.add_task_methods("math/bitwise/clear_bit", [
      {"basic_operation", &bitwise_clear_bit_task_method/2}
    ])
    |> Methods.add_task_methods("math/bitwise/toggle_bit", [
      {"basic_operation", &bitwise_toggle_bit_task_method/2}
    ])
  end

  @doc "Register all bitwise math actions with a domain"
  @spec register_actions(Core.t()) :: Core.t()
  def register_actions(domain) do
    domain
    |> Actions.add_action(:khr_math_bitwise_and, &bitwise_and/2, %{
      domain: "khr_interactivity",
      category: "math_bitwise",
      khr_node_type: "math/bitwise/and",
      description: "Bitwise AND operation on two 32-bit integers"
    })
    |> Actions.add_action(:khr_math_bitwise_or, &bitwise_or/2, %{
      domain: "khr_interactivity",
      category: "math_bitwise",
      khr_node_type: "math/bitwise/or",
      description: "Bitwise OR operation on two 32-bit integers"
    })
    |> Actions.add_action(:khr_math_bitwise_xor, &bitwise_xor/2, %{
      domain: "khr_interactivity",
      category: "math_bitwise",
      khr_node_type: "math/bitwise/xor",
      description: "Bitwise XOR operation on two 32-bit integers"
    })
    |> Actions.add_action(:khr_math_bitwise_not, &bitwise_not/2, %{
      domain: "khr_interactivity",
      category: "math_bitwise",
      khr_node_type: "math/bitwise/not",
      description: "Bitwise NOT (complement) operation on 32-bit integer"
    })
    |> Actions.add_action(:khr_math_bitwise_left_shift, &bitwise_left_shift/2, %{
      domain: "khr_interactivity",
      category: "math_bitwise",
      khr_node_type: "math/bitwise/left_shift",
      description: "Left bit shift operation"
    })
    |> Actions.add_action(:khr_math_bitwise_right_shift, &bitwise_right_shift/2, %{
      domain: "khr_interactivity",
      category: "math_bitwise",
      khr_node_type: "math/bitwise/right_shift",
      description: "Right bit shift operation"
    })
    |> Actions.add_action(:khr_math_bitwise_test_bit, &bitwise_test_bit/2, %{
      domain: "khr_interactivity",
      category: "math_bitwise",
      khr_node_type: "math/bitwise/test_bit",
      description: "Test if specific bit is set"
    })
    |> Actions.add_action(:khr_math_bitwise_set_bit, &bitwise_set_bit/2, %{
      domain: "khr_interactivity",
      category: "math_bitwise",
      khr_node_type: "math/bitwise/set_bit",
      description: "Set specific bit to 1"
    })
    |> Actions.add_action(:khr_math_bitwise_clear_bit, &bitwise_clear_bit/2, %{
      domain: "khr_interactivity",
      category: "math_bitwise",
      khr_node_type: "math/bitwise/clear_bit",
      description: "Clear specific bit to 0"
    })
    |> Actions.add_action(:khr_math_bitwise_toggle_bit, &bitwise_toggle_bit/2, %{
      domain: "khr_interactivity",
      category: "math_bitwise",
      khr_node_type: "math/bitwise/toggle_bit",
      description: "Toggle specific bit"
    })
  end

  # 32-bit signed integer limits
  @max_int32 2_147_483_647
  @min_int32 -2_147_483_648

  @doc "Bitwise AND operation"
  def bitwise_and(state, [node_index, a, b]) when is_integer(a) and is_integer(b) do
    a32 = clamp_to_int32(a)
    b32 = clamp_to_int32(b)
    
    result = Bitwise.band(a32, b32)
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  def bitwise_and(state, [node_index, _a, _b]) do
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", 0)
  end

  @doc "Bitwise OR operation"
  def bitwise_or(state, [node_index, a, b]) when is_integer(a) and is_integer(b) do
    a32 = clamp_to_int32(a)
    b32 = clamp_to_int32(b)
    
    result = Bitwise.bor(a32, b32)
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  def bitwise_or(state, [node_index, _a, _b]) do
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", 0)
  end

  @doc "Bitwise XOR operation"
  def bitwise_xor(state, [node_index, a, b]) when is_integer(a) and is_integer(b) do
    a32 = clamp_to_int32(a)
    b32 = clamp_to_int32(b)
    
    result = Bitwise.bxor(a32, b32)
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  def bitwise_xor(state, [node_index, _a, _b]) do
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", 0)
  end

  @doc "Bitwise NOT (complement) operation"
  def bitwise_not(state, [node_index, value]) when is_integer(value) do
    value32 = clamp_to_int32(value)
    
    # Apply bitwise NOT and clamp to 32-bit signed range
    result = clamp_to_int32(Bitwise.bnot(value32))
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  def bitwise_not(state, [node_index, _value]) do
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", 0)
  end

  @doc "Left bit shift operation"
  def bitwise_left_shift(state, [node_index, value, shift_amount]) when is_integer(value) and is_integer(shift_amount) do
    value32 = clamp_to_int32(value)
    
    # Clamp shift amount to reasonable range (0-31 for 32-bit)
    safe_shift = max(0, min(31, shift_amount))
    
    result = clamp_to_int32(Bitwise.bsl(value32, safe_shift))
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  def bitwise_left_shift(state, [node_index, _value, _shift_amount]) do
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", 0)
  end

  @doc "Right bit shift operation (arithmetic shift)"
  def bitwise_right_shift(state, [node_index, value, shift_amount]) when is_integer(value) and is_integer(shift_amount) do
    value32 = clamp_to_int32(value)
    
    # Clamp shift amount to reasonable range (0-31 for 32-bit)
    safe_shift = max(0, min(31, shift_amount))
    
    result = Bitwise.bsr(value32, safe_shift)
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  def bitwise_right_shift(state, [node_index, _value, _shift_amount]) do
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", 0)
  end

  @doc "Test if specific bit is set (returns true/false)"
  def bitwise_test_bit(state, [node_index, value, bit_position]) when is_integer(value) and is_integer(bit_position) do
    value32 = clamp_to_int32(value)
    
    # Clamp bit position to valid range (0-31 for 32-bit)
    safe_bit = max(0, min(31, bit_position))
    
    # Test bit using bitwise AND with mask
    mask = Bitwise.bsl(1, safe_bit)
    result = Bitwise.band(value32, mask) != 0
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  def bitwise_test_bit(state, [node_index, _value, _bit_position]) do
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", false)
  end

  @doc "Set specific bit to 1"
  def bitwise_set_bit(state, [node_index, value, bit_position]) when is_integer(value) and is_integer(bit_position) do
    value32 = clamp_to_int32(value)
    
    # Clamp bit position to valid range (0-31 for 32-bit)
    safe_bit = max(0, min(31, bit_position))
    
    # Set bit using bitwise OR with mask
    mask = Bitwise.bsl(1, safe_bit)
    result = clamp_to_int32(Bitwise.bor(value32, mask))
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  def bitwise_set_bit(state, [node_index, _value, _bit_position]) do
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", 0)
  end

  @doc "Clear specific bit to 0"
  def bitwise_clear_bit(state, [node_index, value, bit_position]) when is_integer(value) and is_integer(bit_position) do
    value32 = clamp_to_int32(value)
    
    # Clamp bit position to valid range (0-31 for 32-bit)
    safe_bit = max(0, min(31, bit_position))
    
    # Clear bit using bitwise AND with inverted mask
    mask = Bitwise.bsl(1, safe_bit)
    inverted_mask = Bitwise.bnot(mask)
    result = clamp_to_int32(Bitwise.band(value32, inverted_mask))
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  def bitwise_clear_bit(state, [node_index, _value, _bit_position]) do
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", 0)
  end

  @doc "Toggle specific bit"
  def bitwise_toggle_bit(state, [node_index, value, bit_position]) when is_integer(value) and is_integer(bit_position) do
    value32 = clamp_to_int32(value)
    
    # Clamp bit position to valid range (0-31 for 32-bit)
    safe_bit = max(0, min(31, bit_position))
    
    # Toggle bit using bitwise XOR with mask
    mask = Bitwise.bsl(1, safe_bit)
    result = clamp_to_int32(Bitwise.bxor(value32, mask))
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  def bitwise_toggle_bit(state, [node_index, _value, _bit_position]) do
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", 0)
  end

  # Helper function to clamp values to 32-bit signed integer range
  defp clamp_to_int32(value) when is_integer(value) do
    cond do
      value > @max_int32 -> @max_int32
      value < @min_int32 -> @min_int32
      true -> value
    end
  end

  # Task method functions - decompose KHR spec strings to atom-based actions

  @doc "Task method for math/bitwise/and - decomposes to atom-based action"
  def bitwise_and_task_method(_state, [node_id, a, b]) do
    [[:khr_math_bitwise_and, node_id, a, b]]
  end

  @doc "Task method for math/bitwise/or - decomposes to atom-based action"
  def bitwise_or_task_method(_state, [node_id, a, b]) do
    [[:khr_math_bitwise_or, node_id, a, b]]
  end

  @doc "Task method for math/bitwise/xor - decomposes to atom-based action"
  def bitwise_xor_task_method(_state, [node_id, a, b]) do
    [[:khr_math_bitwise_xor, node_id, a, b]]
  end

  @doc "Task method for math/bitwise/not - decomposes to atom-based action"
  def bitwise_not_task_method(_state, [node_id, value]) do
    [[:khr_math_bitwise_not, node_id, value]]
  end

  @doc "Task method for math/bitwise/left_shift - decomposes to atom-based action"
  def bitwise_left_shift_task_method(_state, [node_id, value, shift_amount]) do
    [[:khr_math_bitwise_left_shift, node_id, value, shift_amount]]
  end

  @doc "Task method for math/bitwise/right_shift - decomposes to atom-based action"
  def bitwise_right_shift_task_method(_state, [node_id, value, shift_amount]) do
    [[:khr_math_bitwise_right_shift, node_id, value, shift_amount]]
  end

  @doc "Task method for math/bitwise/test_bit - decomposes to atom-based action"
  def bitwise_test_bit_task_method(_state, [node_id, value, bit_position]) do
    [[:khr_math_bitwise_test_bit, node_id, value, bit_position]]
  end

  @doc "Task method for math/bitwise/set_bit - decomposes to atom-based action"
  def bitwise_set_bit_task_method(_state, [node_id, value, bit_position]) do
    [[:khr_math_bitwise_set_bit, node_id, value, bit_position]]
  end

  @doc "Task method for math/bitwise/clear_bit - decomposes to atom-based action"
  def bitwise_clear_bit_task_method(_state, [node_id, value, bit_position]) do
    [[:khr_math_bitwise_clear_bit, node_id, value, bit_position]]
  end

  @doc "Task method for math/bitwise/toggle_bit - decomposes to atom-based action"
  def bitwise_toggle_bit_task_method(_state, [node_id, value, bit_position]) do
    [[:khr_math_bitwise_toggle_bit, node_id, value, bit_position]]
  end
end
