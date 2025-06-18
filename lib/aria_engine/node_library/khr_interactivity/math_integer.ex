defmodule AriaEngine.NodeLibrary.KHRInteractivity.MathInteger do
  @moduledoc """
  KHR_interactivity Math Integer Operations

  Implements integer-specific mathematical operations from the glTF KHR_interactivity specification:
  - math/integer/add: Integer addition with overflow handling
  - math/integer/subtract: Integer subtraction with underflow handling
  - math/integer/multiply: Integer multiplication with overflow handling
  - math/integer/divide: Integer division with truncation
  - math/integer/mod: Modulo operation (remainder)
  - math/integer/min: Minimum of two integers
  - math/integer/max: Maximum of two integers
  - math/integer/abs: Absolute value
  - math/integer/sign: Sign of integer (-1, 0, 1)
  - math/integer/clamp: Clamp integer to range

  All operations use 32-bit signed integer arithmetic with proper overflow/underflow handling.
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
    |> Methods.add_task_methods("math/integer/add", [
      {"basic_operation", &integer_add_task_method/2}
    ])
    |> Methods.add_task_methods("math/integer/subtract", [
      {"basic_operation", &integer_subtract_task_method/2}
    ])
    |> Methods.add_task_methods("math/integer/multiply", [
      {"basic_operation", &integer_multiply_task_method/2}
    ])
    |> Methods.add_task_methods("math/integer/divide", [
      {"basic_operation", &integer_divide_task_method/2}
    ])
    |> Methods.add_task_methods("math/integer/mod", [
      {"basic_operation", &integer_mod_task_method/2}
    ])
    |> Methods.add_task_methods("math/integer/min", [
      {"basic_operation", &integer_min_task_method/2}
    ])
    |> Methods.add_task_methods("math/integer/max", [
      {"basic_operation", &integer_max_task_method/2}
    ])
    |> Methods.add_task_methods("math/integer/abs", [
      {"basic_operation", &integer_abs_task_method/2}
    ])
    |> Methods.add_task_methods("math/integer/sign", [
      {"basic_operation", &integer_sign_task_method/2}
    ])
    |> Methods.add_task_methods("math/integer/clamp", [
      {"basic_operation", &integer_clamp_task_method/2}
    ])
  end

  @doc "Register all integer math actions with a domain"
  @spec register_actions(Core.t()) :: Core.t()
  def register_actions(domain) do
    domain
    |> Actions.add_action(:khr_math_integer_add, &integer_add/2, %{
      domain: "khr_interactivity",
      category: "math_integer",
      khr_node_type: "math/integer/add",
      description: "Add two 32-bit signed integers with overflow handling"
    })
    |> Actions.add_action(:khr_math_integer_subtract, &integer_subtract/2, %{
      domain: "khr_interactivity",
      category: "math_integer",
      khr_node_type: "math/integer/subtract",
      description: "Subtract two 32-bit signed integers with underflow handling"
    })
    |> Actions.add_action(:khr_math_integer_multiply, &integer_multiply/2, %{
      domain: "khr_interactivity",
      category: "math_integer",
      khr_node_type: "math/integer/multiply",
      description: "Multiply two 32-bit signed integers with overflow handling"
    })
    |> Actions.add_action(:khr_math_integer_divide, &integer_divide/2, %{
      domain: "khr_interactivity",
      category: "math_integer",
      khr_node_type: "math/integer/divide",
      description: "Divide two 32-bit signed integers with truncation"
    })
    |> Actions.add_action(:khr_math_integer_mod, &integer_mod/2, %{
      domain: "khr_interactivity",
      category: "math_integer",
      khr_node_type: "math/integer/mod",
      description: "Modulo operation on 32-bit signed integers"
    })
    |> Actions.add_action(:khr_math_integer_min, &integer_min/2, %{
      domain: "khr_interactivity",
      category: "math_integer",
      khr_node_type: "math/integer/min",
      description: "Minimum of two 32-bit signed integers"
    })
    |> Actions.add_action(:khr_math_integer_max, &integer_max/2, %{
      domain: "khr_interactivity",
      category: "math_integer",
      khr_node_type: "math/integer/max",
      description: "Maximum of two 32-bit signed integers"
    })
    |> Actions.add_action(:khr_math_integer_abs, &integer_abs/2, %{
      domain: "khr_interactivity",
      category: "math_integer",
      khr_node_type: "math/integer/abs",
      description: "Absolute value of 32-bit signed integer"
    })
    |> Actions.add_action(:khr_math_integer_sign, &integer_sign/2, %{
      domain: "khr_interactivity",
      category: "math_integer",
      khr_node_type: "math/integer/sign",
      description: "Sign of 32-bit signed integer (-1, 0, 1)"
    })
    |> Actions.add_action(:khr_math_integer_clamp, &integer_clamp/2, %{
      domain: "khr_interactivity",
      category: "math_integer",
      khr_node_type: "math/integer/clamp",
      description: "Clamp 32-bit signed integer to range [min, max]"
    })
  end

  # 32-bit signed integer limits
  @max_int32 2_147_483_647
  @min_int32 -2_147_483_648

  @doc "Add two integers with overflow handling"
  def integer_add(state, [node_index, a, b]) when is_integer(a) and is_integer(b) do
    # Clamp inputs to 32-bit range
    a32 = clamp_to_int32(a)
    b32 = clamp_to_int32(b)
    
    result = case a32 + b32 do
      sum when sum > @max_int32 -> @max_int32
      sum when sum < @min_int32 -> @min_int32
      sum -> sum
    end
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  def integer_add(state, [node_index, _a, _b]) do
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", 0)
  end

  @doc "Subtract two integers with underflow handling"
  def integer_subtract(state, [node_index, a, b]) when is_integer(a) and is_integer(b) do
    a32 = clamp_to_int32(a)
    b32 = clamp_to_int32(b)
    
    result = case a32 - b32 do
      diff when diff > @max_int32 -> @max_int32
      diff when diff < @min_int32 -> @min_int32
      diff -> diff
    end
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  def integer_subtract(state, [node_index, _a, _b]) do
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", 0)
  end

  @doc "Multiply two integers with overflow handling"
  def integer_multiply(state, [node_index, a, b]) when is_integer(a) and is_integer(b) do
    a32 = clamp_to_int32(a)
    b32 = clamp_to_int32(b)
    
    result = case a32 * b32 do
      product when product > @max_int32 -> @max_int32
      product when product < @min_int32 -> @min_int32
      product -> product
    end
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  def integer_multiply(state, [node_index, _a, _b]) do
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", 0)
  end

  @doc "Divide two integers with truncation (division by zero returns 0)"
  def integer_divide(state, [node_index, a, b]) when is_integer(a) and is_integer(b) do
    a32 = clamp_to_int32(a)
    b32 = clamp_to_int32(b)
    
    result = case b32 do
      0 -> 0  # Division by zero returns 0
      _ -> div(a32, b32)  # Integer division with truncation
    end
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  def integer_divide(state, [node_index, _a, _b]) do
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", 0)
  end

  @doc "Modulo operation (remainder after division)"
  def integer_mod(state, [node_index, a, b]) when is_integer(a) and is_integer(b) do
    a32 = clamp_to_int32(a)
    b32 = clamp_to_int32(b)
    
    result = case b32 do
      0 -> 0  # Modulo by zero returns 0
      _ -> rem(a32, b32)  # Remainder operation
    end
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  def integer_mod(state, [node_index, _a, _b]) do
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", 0)
  end

  @doc "Minimum of two integers"
  def integer_min(state, [node_index, a, b]) when is_integer(a) and is_integer(b) do
    a32 = clamp_to_int32(a)
    b32 = clamp_to_int32(b)
    
    result = min(a32, b32)
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  def integer_min(state, [node_index, _a, _b]) do
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", 0)
  end

  @doc "Maximum of two integers"
  def integer_max(state, [node_index, a, b]) when is_integer(a) and is_integer(b) do
    a32 = clamp_to_int32(a)
    b32 = clamp_to_int32(b)
    
    result = max(a32, b32)
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  def integer_max(state, [node_index, _a, _b]) do
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", 0)
  end

  @doc "Absolute value of integer"
  def integer_abs(state, [node_index, value]) when is_integer(value) do
    value32 = clamp_to_int32(value)
    
    result = abs(value32)
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  def integer_abs(state, [node_index, _value]) do
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", 0)
  end

  @doc "Sign of integer (-1, 0, 1)"
  def integer_sign(state, [node_index, value]) when is_integer(value) do
    value32 = clamp_to_int32(value)
    
    result = cond do
      value32 > 0 -> 1
      value32 < 0 -> -1
      true -> 0
    end
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  def integer_sign(state, [node_index, _value]) do
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", 0)
  end

  @doc "Clamp integer to range [min_val, max_val]"
  def integer_clamp(state, [node_index, value, min_val, max_val]) when is_integer(value) and is_integer(min_val) and is_integer(max_val) do
    value32 = clamp_to_int32(value)
    min32 = clamp_to_int32(min_val)
    max32 = clamp_to_int32(max_val)
    
    # Ensure min <= max
    {actual_min, actual_max} = if min32 <= max32, do: {min32, max32}, else: {max32, min32}
    
    result = cond do
      value32 < actual_min -> actual_min
      value32 > actual_max -> actual_max
      true -> value32
    end
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  def integer_clamp(state, [node_index, _value, _min_val, _max_val]) do
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

  @doc "Task method for math/integer/add - decomposes to atom-based action"
  def integer_add_task_method(_state, [node_id, a, b]) do
    [[:khr_math_integer_add, node_id, a, b]]
  end

  @doc "Task method for math/integer/subtract - decomposes to atom-based action"
  def integer_subtract_task_method(_state, [node_id, a, b]) do
    [[:khr_math_integer_subtract, node_id, a, b]]
  end

  @doc "Task method for math/integer/multiply - decomposes to atom-based action"
  def integer_multiply_task_method(_state, [node_id, a, b]) do
    [[:khr_math_integer_multiply, node_id, a, b]]
  end

  @doc "Task method for math/integer/divide - decomposes to atom-based action"
  def integer_divide_task_method(_state, [node_id, a, b]) do
    [[:khr_math_integer_divide, node_id, a, b]]
  end

  @doc "Task method for math/integer/mod - decomposes to atom-based action"
  def integer_mod_task_method(_state, [node_id, a, b]) do
    [[:khr_math_integer_mod, node_id, a, b]]
  end

  @doc "Task method for math/integer/min - decomposes to atom-based action"
  def integer_min_task_method(_state, [node_id, a, b]) do
    [[:khr_math_integer_min, node_id, a, b]]
  end

  @doc "Task method for math/integer/max - decomposes to atom-based action"
  def integer_max_task_method(_state, [node_id, a, b]) do
    [[:khr_math_integer_max, node_id, a, b]]
  end

  @doc "Task method for math/integer/abs - decomposes to atom-based action"
  def integer_abs_task_method(_state, [node_id, value]) do
    [[:khr_math_integer_abs, node_id, value]]
  end

  @doc "Task method for math/integer/sign - decomposes to atom-based action"
  def integer_sign_task_method(_state, [node_id, value]) do
    [[:khr_math_integer_sign, node_id, value]]
  end

  @doc "Task method for math/integer/clamp - decomposes to atom-based action"
  def integer_clamp_task_method(_state, [node_id, value, min_val, max_val]) do
    [[:khr_math_integer_clamp, node_id, value, min_val, max_val]]
  end
end
