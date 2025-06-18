# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.NodeLibrary.KHRInteractivity.MathConstants do
  @moduledoc """
  Math constant nodes for glTF KHR_interactivity specification.
  
  Provides mathematical constants: e, pi, infinity, and NaN.
  """
  
  alias AriaEngine.Domain.Actions
  alias AriaEngine.StateV2
  
  @doc "Register math constant actions with a domain"
  @spec register_actions(AriaEngine.Domain.Core.t()) :: AriaEngine.Domain.Core.t()
  def register_actions(domain) do
    domain
    |> Actions.add_action(:khr_math_e, &math_e/2, %{
      domain: "khr_interactivity",
      category: "math_constants", 
      khr_node_type: "math/e",
      description: "Euler's number (2.718281828459045)"
    })
    |> Actions.add_action(:khr_math_pi, &math_pi/2, %{
      domain: "khr_interactivity",
      category: "math_constants",
      khr_node_type: "math/pi", 
      description: "Pi constant (3.141592653589793)"
    })
    |> Actions.add_action(:khr_math_inf, &math_inf/2, %{
      domain: "khr_interactivity",
      category: "math_constants",
      khr_node_type: "math/inf",
      description: "Positive infinity"
    })
    |> Actions.add_action(:khr_math_nan, &math_nan/2, %{
      domain: "khr_interactivity",
      category: "math_constants", 
      khr_node_type: "math/nan",
      description: "Not a Number"
    })
  end
  
  # Math constants implementation
  def math_e(state, [node_index]) do
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", :math.exp(1))
  end
  
  def math_pi(state, [node_index]) do
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", :math.pi())
  end
  
  def math_inf(state, [node_index]) do
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", :positive_infinity)
  end
  
  def math_nan(state, [node_index]) do
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", :nan)
  end
end
