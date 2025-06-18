# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule NodeLibrary.KHRInteractivity.MathSpecial do
  @moduledoc """
  KHR_interactivity Math Special Nodes

  Implements special math operations from the glTF KHR_interactivity specification:
  - khr_math_isnan: Not a Number check operation
  - khr_math_isinf: Infinity check operation  
  - khr_math_select: Conditional selection operation
  - khr_math_switch: Conditionally output one of the input values
  - khr_math_random: Random value generation operation
  """

  alias StateV2
  alias Domain.Actions

  @doc "Register all math special actions with a domain"
  @spec register_actions(Domain.Core.t()) :: Domain.Core.t()
  def register_actions(domain) do
    domain
    |> Actions.add_action(:khr_math_isnan, &math_isnan/2, %{
      domain: "khr_interactivity",
      category: "math_special",
      khr_node_type: "math/isnan",
      description: "Not a Number check operation"
    })
    |> Actions.add_action(:khr_math_isinf, &math_isinf/2, %{
      domain: "khr_interactivity",
      category: "math_special",
      khr_node_type: "math/isinf",
      description: "Infinity check operation"
    })
    |> Actions.add_action(:khr_math_select, &math_select/2, %{
      domain: "khr_interactivity",
      category: "math_special",
      khr_node_type: "math/select",
      description: "Conditional selection operation"
    })
    |> Actions.add_action(:khr_math_switch, &math_switch/2, %{
      domain: "khr_interactivity",
      category: "math_special",
      khr_node_type: "math/switch",
      description: "Switch operation"
    })
    |> Actions.add_action(:khr_math_random, &math_random/2, %{
      domain: "khr_interactivity",
      category: "math_special",
      khr_node_type: "math/random",
      description: "Random value generation operation"
    })
  end

  @doc """
  Not a Number check operation.
  
  Returns true if the argument is NaN, false otherwise.
  """
  def math_isnan(state, [node_index, a]) do
    result = a == :nan
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  @doc """
  Infinity check operation.
  
  Returns true if the argument is positive or negative infinity, false otherwise.
  """
  def math_isinf(state, [node_index, a]) do
    result = a == :positive_infinity or a == :negative_infinity
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  @doc """
  Conditional selection operation.
  
  Returns `a` if condition is true, `b` otherwise.
  The type T can be any supported type and must be the same for both options.
  """
  def math_select(state, [node_index, condition, a, b]) when is_boolean(condition) do
    result = if condition, do: a, else: b
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  @doc """
  Switch operation - conditionally output one of the input values.
  
  This is a simplified version that takes a selection integer and a default value.
  For a full implementation with configurable cases, additional logic would be needed
  to handle the cases configuration array.
  """
  def math_switch(state, [node_index, selection, default]) when is_integer(selection) do
    # In the basic case with no configured cases, always return default
    # A full implementation would check configured cases array
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", default)
  end

  @doc """
  Random value generation operation.
  
  Returns a pseudo-random number greater than or equal to zero and less than one.
  The value is initialized on first access and updated on each new flow activation.
  """
  def math_random(state, [node_index]) do
    # Generate random float in [0, 1)
    random_value = :rand.uniform() # Returns float in (0, 1]
    # Adjust to ensure [0, 1) range
    adjusted_value = if random_value == 1.0, do: 0.0, else: random_value
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", adjusted_value)
  end
end
