# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule NodeLibrary.KHRInteractivity.MathConstants do
  @moduledoc """
  Math constant nodes for glTF KHR_interactivity specification.
  
  Provides mathematical constants: e, pi, infinity, and NaN.
  """
  
  alias StateV2
  
  @doc "Register math constant actions with a domain"
  @spec register_actions(Domain.t()) :: Domain.t()
  def register_actions(domain) do
    domain
    |> Domain.add_action(:khr_math_e, &math_e/2, %{
      domain: "khr_interactivity",
      category: "math_constants", 
      khr_node_type: "math/e",
      description: "Euler's number (2.718281828459045)"
    })
    |> Domain.add_action(:khr_math_pi, &math_pi/2, %{
      domain: "khr_interactivity",
      category: "math_constants",
      khr_node_type: "math/pi", 
      description: "Pi constant (3.141592653589793)"
    })
    |> Domain.add_action(:khr_math_inf, &math_inf/2, %{
      domain: "khr_interactivity",
      category: "math_constants",
      khr_node_type: "math/inf",
      description: "Positive infinity"
    })
    |> Domain.add_action(:khr_math_nan, &math_nan/2, %{
      domain: "khr_interactivity",
      category: "math_constants", 
      khr_node_type: "math/nan",
      description: "Not a Number"
    })
  end

  @doc "Register task methods for math constants"
  @spec register_task_methods(Domain.t()) :: Domain.t()
  def register_task_methods(domain) do
    domain
    |> Domain.add_task_method("math/e", "constant_e", &task_method_e/2)
    |> Domain.add_task_method("math/pi", "constant_pi", &task_method_pi/2)
    |> Domain.add_task_method("math/inf", "constant_inf", &task_method_inf/2)
    |> Domain.add_task_method("math/nan", "constant_nan", &task_method_nan/2)
  end
  
  # Math constants implementation - using integer node IDs directly
  def math_e(state, [node_index]) when is_integer(node_index) do
    state
    |> StateV2.set_fact(node_index, "value", :math.exp(1))
  end
  
  def math_pi(state, [node_index]) when is_integer(node_index) do
    state
    |> StateV2.set_fact(node_index, "value", :math.pi())
  end
  
  def math_inf(state, [node_index]) when is_integer(node_index) do
    state
    |> StateV2.set_fact(node_index, "value", :positive_infinity)
  end
  
  def math_nan(state, [node_index]) when is_integer(node_index) do
    state
    |> StateV2.set_fact(node_index, "value", :nan)
  end

  # Task method implementations - using integer node IDs directly
  def task_method_e(_state, [node_index]) when is_integer(node_index) do
    [{"khr_math_e", [node_index]}]
  end

  def task_method_pi(_state, [node_index]) when is_integer(node_index) do
    [{"khr_math_pi", [node_index]}]
  end

  def task_method_inf(_state, [node_index]) when is_integer(node_index) do
    [{"khr_math_inf", [node_index]}]
  end

  def task_method_nan(_state, [node_index]) when is_integer(node_index) do
    [{"khr_math_nan", [node_index]}]
  end
end
