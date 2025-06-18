# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.NodeLibrary.KHRInteractivity.MathArithmetic do
  @moduledoc """
  Math arithmetic nodes for glTF KHR_interactivity specification.
  
  Provides basic arithmetic operations: abs, sign, neg, add, sub, mul, div, rem,
  min, max, clamp, floor, ceil, round, trunc, fract, saturate, mix.
  """
  
  alias AriaEngine.Domain.Actions
  alias AriaEngine.StateV2
  
  @doc "Register math arithmetic actions with a domain"
  @spec register_actions(AriaEngine.Domain.Core.t()) :: AriaEngine.Domain.Core.t()
  def register_actions(domain) do
    domain
    |> Actions.add_action(:khr_math_abs, &math_abs/2, %{
      domain: "khr_interactivity",
      category: "math_arithmetic",
      khr_node_type: "math/abs",
      description: "Absolute value operation"
    })
    |> Actions.add_action(:khr_math_sign, &math_sign/2, %{
      domain: "khr_interactivity", 
      category: "math_arithmetic",
      khr_node_type: "math/sign",
      description: "Sign function (-1, 0, 1)"
    })
    |> Actions.add_action(:khr_math_neg, &math_neg/2, %{
      domain: "khr_interactivity",
      category: "math_arithmetic", 
      khr_node_type: "math/neg",
      description: "Negation operation"
    })
    |> Actions.add_action(:khr_math_add, &math_add/2, %{
      domain: "khr_interactivity",
      category: "math_arithmetic",
      khr_node_type: "math/add", 
      description: "Addition operation"
    })
    |> Actions.add_action(:khr_math_sub, &math_sub/2, %{
      domain: "khr_interactivity",
      category: "math_arithmetic",
      khr_node_type: "math/sub",
      description: "Subtraction operation"
    })
    |> Actions.add_action(:khr_math_mul, &math_mul/2, %{
      domain: "khr_interactivity",
      category: "math_arithmetic",
      khr_node_type: "math/mul",
      description: "Multiplication operation" 
    })
    |> Actions.add_action(:khr_math_div, &math_div/2, %{
      domain: "khr_interactivity",
      category: "math_arithmetic", 
      khr_node_type: "math/div",
      description: "Division operation"
    })
    |> Actions.add_action(:khr_math_rem, &math_rem/2, %{
      domain: "khr_interactivity",
      category: "math_arithmetic",
      khr_node_type: "math/rem", 
      description: "Remainder operation"
    })
    |> Actions.add_action(:khr_math_min, &math_min/2, %{
      domain: "khr_interactivity",
      category: "math_arithmetic",
      khr_node_type: "math/min",
      description: "Minimum operation"
    })
    |> Actions.add_action(:khr_math_max, &math_max/2, %{
      domain: "khr_interactivity", 
      category: "math_arithmetic",
      khr_node_type: "math/max",
      description: "Maximum operation"
    })
    |> Actions.add_action(:khr_math_clamp, &math_clamp/2, %{
      domain: "khr_interactivity",
      category: "math_arithmetic",
      khr_node_type: "math/clamp", 
      description: "Clamp operation"
    })
    |> Actions.add_action(:khr_math_floor, &math_floor/2, %{
      domain: "khr_interactivity",
      category: "math_arithmetic",
      khr_node_type: "math/floor",
      description: "Floor operation"
    })
    |> Actions.add_action(:khr_math_ceil, &math_ceil/2, %{
      domain: "khr_interactivity",
      category: "math_arithmetic", 
      khr_node_type: "math/ceil",
      description: "Ceiling operation"
    })
    |> Actions.add_action(:khr_math_round, &math_round/2, %{
      domain: "khr_interactivity",
      category: "math_arithmetic",
      khr_node_type: "math/round",
      description: "Round operation"
    })
    |> Actions.add_action(:khr_math_trunc, &math_trunc/2, %{
      domain: "khr_interactivity",
      category: "math_arithmetic",
      khr_node_type: "math/trunc", 
      description: "Truncate operation"
    })
    |> Actions.add_action(:khr_math_fract, &math_fract/2, %{
      domain: "khr_interactivity", 
      category: "math_arithmetic",
      khr_node_type: "math/fract",
      description: "Fractional operation"
    })
    |> Actions.add_action(:khr_math_saturate, &math_saturate/2, %{
      domain: "khr_interactivity",
      category: "math_arithmetic",
      khr_node_type: "math/saturate",
      description: "Saturate operation (clamp to [0,1])"
    })
    |> Actions.add_action(:khr_math_mix, &math_mix/2, %{
      domain: "khr_interactivity",
      category: "math_arithmetic", 
      khr_node_type: "math/mix",
      description: "Linear interpolation operation"
    })
  end
  
  # Math arithmetic implementation
  def math_abs(state, [node_index, x]) when is_number(x) do
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", abs(x))
  end
  
  def math_sign(state, [node_index, x]) when is_number(x) do
    result = cond do
      x > 0 -> 1
      x < 0 -> -1
      x == 0 -> 0
      true -> :nan  # For NaN input
    end
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end
  
  def math_neg(state, [node_index, x]) when is_number(x) do
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", -x)
  end
  
  def math_add(state, [node_index, a, b]) when is_number(a) and is_number(b) do
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", a + b)
  end
  
  def math_sub(state, [node_index, a, b]) when is_number(a) and is_number(b) do
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", a - b)
  end
  
  def math_mul(state, [node_index, a, b]) when is_number(a) and is_number(b) do
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", a * b)
  end
  
  def math_div(state, [node_index, a, b]) when is_number(a) and is_number(b) do
    result = cond do
      b == 0.0 and a > 0 -> :positive_infinity
      b == 0.0 and a < 0 -> :negative_infinity  
      b == 0.0 and a == 0 -> :nan
      true -> a / b
    end
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end
  
  def math_rem(state, [node_index, a, b]) when is_number(a) and is_number(b) do
    result = if b != 0, do: :math.fmod(a, b), else: :nan
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end
  
  def math_min(state, [node_index, a, b]) when is_number(a) and is_number(b) do
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", min(a, b))
  end
  
  def math_max(state, [node_index, a, b]) when is_number(a) and is_number(b) do
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", max(a, b))
  end
  
  def math_clamp(state, [node_index, value, min_val, max_val]) 
      when is_number(value) and is_number(min_val) and is_number(max_val) do
    # KHR spec: min(max(a, min(b, c)), max(b, c))
    # This handles reversed bounds correctly
    result = min(max(value, min(min_val, max_val)), max(min_val, max_val))
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end
  
  def math_floor(state, [node_index, x]) when is_number(x) do
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", :math.floor(x))
  end
  
  def math_ceil(state, [node_index, x]) when is_number(x) do
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", :math.ceil(x))
  end
  
  def math_round(state, [node_index, x]) when is_number(x) do
    # KHR spec requires rounding away from zero for half-way cases
    result = if x < 0, do: -round(-x), else: round(x)
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end
  
  def math_trunc(state, [node_index, x]) when is_number(x) do
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", trunc(x))
  end
  
  def math_fract(state, [node_index, x]) when is_number(x) do
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", x - :math.floor(x))
  end
  
  def math_saturate(state, [node_index, x]) when is_number(x) do
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", max(0, min(1, x)))
  end
  
  def math_mix(state, [node_index, a, b, t]) when is_number(a) and is_number(b) and is_number(t) do
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", (1 - t) * a + t * b)
  end
end
