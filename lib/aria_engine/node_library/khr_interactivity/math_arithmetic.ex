# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule NodeLibrary.KHRInteractivity.MathArithmetic do
  @moduledoc """
  Math arithmetic nodes for glTF KHR_interactivity specification.
  
  Provides basic arithmetic operations: abs, sign, neg, add, sub, mul, div, rem,
  min, max, clamp, floor, ceil, round, trunc, fract, saturate, mix.
  """
  
  alias StateV2
  
  @doc "Register math arithmetic actions with a domain"
  @spec register_actions(Domain.t()) :: Domain.t()
  def register_actions(domain) do
    domain
    |> Domain.add_action(:khr_math_abs, &math_abs/2, %{
      domain: "khr_interactivity",
      category: "math_arithmetic",
      khr_node_type: "math/abs",
      description: "Absolute value operation"
    })
    |> Domain.add_action(:khr_math_sign, &math_sign/2, %{
      domain: "khr_interactivity", 
      category: "math_arithmetic",
      khr_node_type: "math/sign",
      description: "Sign function (-1, 0, 1)"
    })
    |> Domain.add_action(:khr_math_neg, &math_neg/2, %{
      domain: "khr_interactivity",
      category: "math_arithmetic", 
      khr_node_type: "math/neg",
      description: "Negation operation"
    })
    |> Domain.add_action(:khr_math_add, &math_add/2, %{
      domain: "khr_interactivity",
      category: "math_arithmetic",
      khr_node_type: "math/add", 
      description: "Addition operation"
    })
    |> Domain.add_action(:khr_math_sub, &math_sub/2, %{
      domain: "khr_interactivity",
      category: "math_arithmetic",
      khr_node_type: "math/sub",
      description: "Subtraction operation"
    })
    |> Domain.add_action(:khr_math_mul, &math_mul/2, %{
      domain: "khr_interactivity",
      category: "math_arithmetic",
      khr_node_type: "math/mul",
      description: "Multiplication operation" 
    })
    |> Domain.add_action(:khr_math_div, &math_div/2, %{
      domain: "khr_interactivity",
      category: "math_arithmetic", 
      khr_node_type: "math/div",
      description: "Division operation"
    })
    |> Domain.add_action(:khr_math_rem, &math_rem/2, %{
      domain: "khr_interactivity",
      category: "math_arithmetic",
      khr_node_type: "math/rem", 
      description: "Remainder operation"
    })
    |> Domain.add_action(:khr_math_min, &math_min/2, %{
      domain: "khr_interactivity",
      category: "math_arithmetic",
      khr_node_type: "math/min",
      description: "Minimum operation"
    })
    |> Domain.add_action(:khr_math_max, &math_max/2, %{
      domain: "khr_interactivity", 
      category: "math_arithmetic",
      khr_node_type: "math/max",
      description: "Maximum operation"
    })
    |> Domain.add_action(:khr_math_clamp, &math_clamp/2, %{
      domain: "khr_interactivity",
      category: "math_arithmetic",
      khr_node_type: "math/clamp", 
      description: "Clamp operation"
    })
    |> Domain.add_action(:khr_math_floor, &math_floor/2, %{
      domain: "khr_interactivity",
      category: "math_arithmetic",
      khr_node_type: "math/floor",
      description: "Floor operation"
    })
    |> Domain.add_action(:khr_math_ceil, &math_ceil/2, %{
      domain: "khr_interactivity",
      category: "math_arithmetic", 
      khr_node_type: "math/ceil",
      description: "Ceiling operation"
    })
    |> Domain.add_action(:khr_math_round, &math_round/2, %{
      domain: "khr_interactivity",
      category: "math_arithmetic",
      khr_node_type: "math/round",
      description: "Round operation"
    })
    |> Domain.add_action(:khr_math_trunc, &math_trunc/2, %{
      domain: "khr_interactivity",
      category: "math_arithmetic",
      khr_node_type: "math/trunc", 
      description: "Truncate operation"
    })
    |> Domain.add_action(:khr_math_fract, &math_fract/2, %{
      domain: "khr_interactivity", 
      category: "math_arithmetic",
      khr_node_type: "math/fract",
      description: "Fractional operation"
    })
    |> Domain.add_action(:khr_math_saturate, &math_saturate/2, %{
      domain: "khr_interactivity",
      category: "math_arithmetic",
      khr_node_type: "math/saturate",
      description: "Saturate operation (clamp to [0,1])"
    })
    |> Domain.add_action(:khr_math_mix, &math_mix/2, %{
      domain: "khr_interactivity",
      category: "math_arithmetic", 
      khr_node_type: "math/mix",
      description: "Linear interpolation operation"
    })
  end

  @doc "Register task methods for math arithmetic operations"
  @spec register_task_methods(Domain.t()) :: Domain.t()
  def register_task_methods(domain) do
    domain
    |> Domain.add_task_method("math/abs", "arithmetic_abs", &task_method_abs/2)
    |> Domain.add_task_method("math/sign", "arithmetic_sign", &task_method_sign/2)
    |> Domain.add_task_method("math/neg", "arithmetic_neg", &task_method_neg/2)
    |> Domain.add_task_method("math/add", "arithmetic_add", &task_method_add/2)
    |> Domain.add_task_method("math/sub", "arithmetic_sub", &task_method_sub/2)
    |> Domain.add_task_method("math/mul", "arithmetic_mul", &task_method_mul/2)
    |> Domain.add_task_method("math/div", "arithmetic_div", &task_method_div/2)
    |> Domain.add_task_method("math/rem", "arithmetic_rem", &task_method_rem/2)
    |> Domain.add_task_method("math/min", "arithmetic_min", &task_method_min/2)
    |> Domain.add_task_method("math/max", "arithmetic_max", &task_method_max/2)
    |> Domain.add_task_method("math/clamp", "arithmetic_clamp", &task_method_clamp/2)
    |> Domain.add_task_method("math/floor", "arithmetic_floor", &task_method_floor/2)
    |> Domain.add_task_method("math/ceil", "arithmetic_ceil", &task_method_ceil/2)
    |> Domain.add_task_method("math/round", "arithmetic_round", &task_method_round/2)
    |> Domain.add_task_method("math/trunc", "arithmetic_trunc", &task_method_trunc/2)
    |> Domain.add_task_method("math/fract", "arithmetic_fract", &task_method_fract/2)
    |> Domain.add_task_method("math/saturate", "arithmetic_saturate", &task_method_saturate/2)
    |> Domain.add_task_method("math/mix", "arithmetic_mix", &task_method_mix/2)
  end
  
  # Math arithmetic implementation
  def math_abs(state, [node_index, x]) when is_integer(node_index) and is_number(x) do
    state
    |> StateV2.set_fact(node_index, "value", abs(x))
  end
  
  def math_sign(state, [node_index, x]) when is_integer(node_index) and is_number(x) do
    result = cond do
      x > 0 -> 1
      x < 0 -> -1
      x == 0 -> 0
      true -> :nan  # For NaN input
    end
    
    state
    |> StateV2.set_fact(node_index, "value", result)
  end
  
  def math_neg(state, [node_index, x]) when is_integer(node_index) and is_number(x) do
    state
    |> StateV2.set_fact(node_index, "value", -x)
  end
  
  def math_add(state, [node_index, a, b]) when is_integer(node_index) and is_number(a) and is_number(b) do
    state
    |> StateV2.set_fact(node_index, "value", a + b)
  end
  
  def math_sub(state, [node_index, a, b]) when is_integer(node_index) and is_number(a) and is_number(b) do
    state
    |> StateV2.set_fact(node_index, "value", a - b)
  end
  
  def math_mul(state, [node_index, a, b]) when is_integer(node_index) and is_number(a) and is_number(b) do
    state
    |> StateV2.set_fact(node_index, "value", a * b)
  end
  
  def math_div(state, [node_index, a, b]) when is_integer(node_index) and is_number(a) and is_number(b) do
    result = cond do
      b == 0.0 and a > 0 -> :positive_infinity
      b == 0.0 and a < 0 -> :negative_infinity  
      b == 0.0 and a == 0 -> :nan
      true -> a / b
    end
    
    state
    |> StateV2.set_fact(node_index, "value", result)
  end
  
  def math_rem(state, [node_index, a, b]) when is_integer(node_index) and is_number(a) and is_number(b) do
    result = if b != 0, do: :math.fmod(a, b), else: :nan
    
    state
    |> StateV2.set_fact(node_index, "value", result)
  end
  
  def math_min(state, [node_index, a, b]) when is_integer(node_index) and is_number(a) and is_number(b) do
    state
    |> StateV2.set_fact(node_index, "value", min(a, b))
  end
  
  def math_max(state, [node_index, a, b]) when is_integer(node_index) and is_number(a) and is_number(b) do
    state
    |> StateV2.set_fact(node_index, "value", max(a, b))
  end
  
  def math_clamp(state, [node_index, value, min_val, max_val]) 
      when is_integer(node_index) and is_number(value) and is_number(min_val) and is_number(max_val) do
    # KHR spec: min(max(a, min(b, c)), max(b, c))
    # This handles reversed bounds correctly
    result = min(max(value, min(min_val, max_val)), max(min_val, max_val))
    
    state
    |> StateV2.set_fact(node_index, "value", result)
  end
  
  def math_floor(state, [node_index, x]) when is_integer(node_index) and is_number(x) do
    state
    |> StateV2.set_fact(node_index, "value", :math.floor(x))
  end
  
  def math_ceil(state, [node_index, x]) when is_integer(node_index) and is_number(x) do
    state
    |> StateV2.set_fact(node_index, "value", :math.ceil(x))
  end
  
  def math_round(state, [node_index, x]) when is_integer(node_index) and is_number(x) do
    # KHR spec requires rounding away from zero for half-way cases
    result = if x < 0, do: -round(-x), else: round(x)
    
    state
    |> StateV2.set_fact(node_index, "value", result)
  end
  
  def math_trunc(state, [node_index, x]) when is_integer(node_index) and is_number(x) do
    state
    |> StateV2.set_fact(node_index, "value", trunc(x))
  end
  
  def math_fract(state, [node_index, x]) when is_integer(node_index) and is_number(x) do
    state
    |> StateV2.set_fact(node_index, "value", x - :math.floor(x))
  end
  
  def math_saturate(state, [node_index, x]) when is_integer(node_index) and is_number(x) do
    state
    |> StateV2.set_fact(node_index, "value", max(0, min(1, x)))
  end
  
  def math_mix(state, [node_index, a, b, t]) when is_integer(node_index) and is_number(a) and is_number(b) and is_number(t) do
    state
    |> StateV2.set_fact(node_index, "value", (1 - t) * a + t * b)
  end

  # Task method implementations
  def task_method_abs(state, [node_index, x]) when is_integer(node_index) and is_number(x) do
    [{:ok, state |> StateV2.set_fact(node_index, "value", abs(x)), []}]
  end

  def task_method_sign(state, [node_index, x]) when is_integer(node_index) and is_number(x) do
    result = cond do
      x > 0 -> 1
      x < 0 -> -1
      x == 0 -> 0
      true -> :nan
    end
    [{:ok, state |> StateV2.set_fact(node_index, "value", result), []}]
  end

  def task_method_neg(state, [node_index, x]) when is_integer(node_index) and is_number(x) do
    [{:ok, state |> StateV2.set_fact(node_index, "value", -x), []}]
  end

  def task_method_add(state, [node_index, a, b]) when is_integer(node_index) and is_number(a) and is_number(b) do
    [{:ok, state |> StateV2.set_fact(node_index, "value", a + b), []}]
  end

  def task_method_sub(state, [node_index, a, b]) when is_integer(node_index) and is_number(a) and is_number(b) do
    [{:ok, state |> StateV2.set_fact(node_index, "value", a - b), []}]
  end

  def task_method_mul(state, [node_index, a, b]) when is_integer(node_index) and is_number(a) and is_number(b) do
    [{:ok, state |> StateV2.set_fact(node_index, "value", a * b), []}]
  end

  def task_method_div(state, [node_index, a, b]) when is_integer(node_index) and is_number(a) and is_number(b) do
    result = cond do
      b == 0.0 and a > 0 -> :positive_infinity
      b == 0.0 and a < 0 -> :negative_infinity  
      b == 0.0 and a == 0 -> :nan
      true -> a / b
    end
    [{:ok, state |> StateV2.set_fact(node_index, "value", result), []}]
  end

  def task_method_rem(state, [node_index, a, b]) when is_integer(node_index) and is_number(a) and is_number(b) do
    result = if b != 0, do: :math.fmod(a, b), else: :nan
    [{:ok, state |> StateV2.set_fact(node_index, "value", result), []}]
  end

  def task_method_min(state, [node_index, a, b]) when is_integer(node_index) and is_number(a) and is_number(b) do
    [{:ok, state |> StateV2.set_fact(node_index, "value", min(a, b)), []}]
  end

  def task_method_max(state, [node_index, a, b]) when is_integer(node_index) and is_number(a) and is_number(b) do
    [{:ok, state |> StateV2.set_fact(node_index, "value", max(a, b)), []}]
  end

  def task_method_clamp(state, [node_index, value, min_val, max_val]) 
      when is_integer(node_index) and is_number(value) and is_number(min_val) and is_number(max_val) do
    result = min(max(value, min(min_val, max_val)), max(min_val, max_val))
    [{:ok, state |> StateV2.set_fact(node_index, "value", result), []}]
  end

  def task_method_floor(state, [node_index, x]) when is_integer(node_index) and is_number(x) do
    [{:ok, state |> StateV2.set_fact(node_index, "value", :math.floor(x)), []}]
  end

  def task_method_ceil(state, [node_index, x]) when is_integer(node_index) and is_number(x) do
    [{:ok, state |> StateV2.set_fact(node_index, "value", :math.ceil(x)), []}]
  end

  def task_method_round(state, [node_index, x]) when is_integer(node_index) and is_number(x) do
    result = if x < 0, do: -round(-x), else: round(x)
    [{:ok, state |> StateV2.set_fact(node_index, "value", result), []}]
  end

  def task_method_trunc(state, [node_index, x]) when is_integer(node_index) and is_number(x) do
    [{:ok, state |> StateV2.set_fact(node_index, "value", trunc(x)), []}]
  end

  def task_method_fract(state, [node_index, x]) when is_integer(node_index) and is_number(x) do
    [{:ok, state |> StateV2.set_fact(node_index, "value", x - :math.floor(x)), []}]
  end

  def task_method_saturate(state, [node_index, x]) when is_integer(node_index) and is_number(x) do
    [{:ok, state |> StateV2.set_fact(node_index, "value", max(0, min(1, x))), []}]
  end

  def task_method_mix(state, [node_index, a, b, t]) when is_integer(node_index) and is_number(a) and is_number(b) and is_number(t) do
    [{:ok, state |> StateV2.set_fact(node_index, "value", (1 - t) * a + t * b), []}]
  end
end
