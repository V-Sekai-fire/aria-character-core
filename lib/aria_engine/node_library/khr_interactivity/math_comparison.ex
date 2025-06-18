# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.NodeLibrary.KHRInteractivity.MathComparison do
  @moduledoc """
  KHR_interactivity Math Comparison Nodes

  Implements comparison operations from the glTF KHR_interactivity specification:
  - khr_math_eq: Equality operation  
  - khr_math_lt: Less than operation
  - khr_math_le: Less than or equal to operation
  - khr_math_gt: Greater than operation
  - khr_math_ge: Greater than or equal to operation

  All comparison nodes handle NaN values by returning false.
  For float comparisons, negative zero equals positive zero.
  """

  alias AriaEngine.StateV2
  alias AriaEngine.Domain.Actions

  @doc "Register all math comparison actions with a domain"
  @spec register_actions(AriaEngine.Domain.Core.t()) :: AriaEngine.Domain.Core.t()
  def register_actions(domain) do
    domain
    |> Actions.add_action(:khr_math_eq, &math_eq/2, %{
      domain: "khr_interactivity",
      category: "math_comparison",
      khr_node_type: "math/eq",
      description: "Equality operation"
    })
    |> Actions.add_action(:khr_math_lt, &math_lt/2, %{
      domain: "khr_interactivity",
      category: "math_comparison",
      khr_node_type: "math/lt",
      description: "Less than operation"
    })
    |> Actions.add_action(:khr_math_le, &math_le/2, %{
      domain: "khr_interactivity",
      category: "math_comparison",
      khr_node_type: "math/le",
      description: "Less than or equal to operation"
    })
    |> Actions.add_action(:khr_math_gt, &math_gt/2, %{
      domain: "khr_interactivity",
      category: "math_comparison",
      khr_node_type: "math/gt",
      description: "Greater than operation"
    })
    |> Actions.add_action(:khr_math_ge, &math_ge/2, %{
      domain: "khr_interactivity",
      category: "math_comparison",
      khr_node_type: "math/ge",
      description: "Greater than or equal to operation"
    })
  end

  @doc """
  Equality operation for floats and integers.
  
  Returns true if the input arguments are equal, false otherwise.
  If any input value is NaN, returns false.
  For floats, negative zero equals positive zero.
  """
  def math_eq(state, [node_index, a, b]) when is_number(a) and is_number(b) do
    result = cond do
      # Handle NaN cases - NaN != NaN
      a == :nan -> false
      b == :nan -> false
      # Normal equality check (handles -0.0 == 0.0 correctly in Elixir)
      true -> a == b
    end
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  @doc """
  Less than operation for numbers.
  
  Returns true if a < b, false otherwise.
  If any input value is NaN, returns false.
  For floats, negative zero equals positive zero.
  """
  def math_lt(state, [node_index, a, b]) when is_number(a) and is_number(b) do
    result = cond do
      # Handle NaN cases
      a == :nan -> false
      b == :nan -> false
      # Normal comparison
      true -> a < b
    end
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  @doc """
  Less than or equal to operation for numbers.
  
  Returns true if a <= b, false otherwise.
  If any input value is NaN, returns false.
  For floats, negative zero equals positive zero.
  """
  def math_le(state, [node_index, a, b]) when is_number(a) and is_number(b) do
    result = cond do
      # Handle NaN cases
      a == :nan -> false
      b == :nan -> false
      # Normal comparison
      true -> a <= b
    end
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  @doc """
  Greater than operation for numbers.
  
  Returns true if a > b, false otherwise.
  If any input value is NaN, returns false.
  For floats, negative zero equals positive zero.
  """
  def math_gt(state, [node_index, a, b]) when is_number(a) and is_number(b) do
    result = cond do
      # Handle NaN cases
      a == :nan -> false
      b == :nan -> false
      # Normal comparison
      true -> a > b
    end
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  @doc """
  Greater than or equal to operation for numbers.
  
  Returns true if a >= b, false otherwise.
  If any input value is NaN, returns false.
  For floats, negative zero equals positive zero.
  """
  def math_ge(state, [node_index, a, b]) when is_number(a) and is_number(b) do
    result = cond do
      # Handle NaN cases
      a == :nan -> false
      b == :nan -> false
      # Normal comparison
      true -> a >= b
    end
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end
end
