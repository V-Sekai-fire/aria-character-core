# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule NodeLibrary.KHRInteractivity.MathHyperbolic do
  @moduledoc """
  KHR_interactivity Math Hyperbolic Nodes

  Implements hyperbolic operations from the glTF KHR_interactivity specification:
  - khr_math_sinh: Hyperbolic sine function
  - khr_math_cosh: Hyperbolic cosine function
  - khr_math_tanh: Hyperbolic tangent function
  - khr_math_asinh: Inverse hyperbolic sine function
  - khr_math_acosh: Inverse hyperbolic cosine function
  - khr_math_atanh: Inverse hyperbolic tangent function

  All operations handle NaN and infinity according to the KHR_interactivity spec.
  """

  alias StateV2
  alias Domain.Actions

  @doc "Register all math hyperbolic actions with a domain"
  @spec register_actions(Domain.Core.t()) :: Domain.Core.t()
  def register_actions(domain) do
    domain
    |> Actions.add_action(:khr_math_sinh, &math_sinh/2, %{
      domain: "khr_interactivity",
      category: "math_hyperbolic",
      khr_node_type: "math/sinh",
      description: "Hyperbolic sine function"
    })
    |> Actions.add_action(:khr_math_cosh, &math_cosh/2, %{
      domain: "khr_interactivity",
      category: "math_hyperbolic",
      khr_node_type: "math/cosh",
      description: "Hyperbolic cosine function"
    })
    |> Actions.add_action(:khr_math_tanh, &math_tanh/2, %{
      domain: "khr_interactivity",
      category: "math_hyperbolic",
      khr_node_type: "math/tanh",
      description: "Hyperbolic tangent function"
    })
    |> Actions.add_action(:khr_math_asinh, &math_asinh/2, %{
      domain: "khr_interactivity",
      category: "math_hyperbolic",
      khr_node_type: "math/asinh",
      description: "Inverse hyperbolic sine function"
    })
    |> Actions.add_action(:khr_math_acosh, &math_acosh/2, %{
      domain: "khr_interactivity",
      category: "math_hyperbolic",
      khr_node_type: "math/acosh",
      description: "Inverse hyperbolic cosine function"
    })
    |> Actions.add_action(:khr_math_atanh, &math_atanh/2, %{
      domain: "khr_interactivity",
      category: "math_hyperbolic",
      khr_node_type: "math/atanh",
      description: "Inverse hyperbolic tangent function"
    })
  end

  @doc """
  Hyperbolic sine function.
  
  Special cases:
  - sinh(±0) = ±0
  - sinh(±∞) = ±∞
  """
  def math_sinh(state, [node_index, a]) when is_number(a) do
    result = cond do
      a == :nan -> :nan
      a == 0.0 or a == -0.0 -> a  # Preserve sign of zero
      a == :positive_infinity -> :positive_infinity
      a == :negative_infinity -> :negative_infinity
      true -> :math.sinh(a)
    end
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  @doc """
  Hyperbolic cosine function.
  
  Special cases:
  - cosh(±0) = +1
  - cosh(±∞) = +∞
  """
  def math_cosh(state, [node_index, a]) when is_number(a) do
    result = cond do
      a == :nan -> :nan
      a == 0.0 or a == -0.0 -> 1.0
      a == :positive_infinity or a == :negative_infinity -> :positive_infinity
      true -> :math.cosh(a)
    end
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  @doc """
  Hyperbolic tangent function.
  
  Special cases:
  - tanh(±0) = ±0
  - tanh(±∞) = ±1
  """
  def math_tanh(state, [node_index, a]) when is_number(a) do
    result = cond do
      a == :nan -> :nan
      a == 0.0 or a == -0.0 -> a  # Preserve sign of zero
      a == :positive_infinity -> 1.0
      a == :negative_infinity -> -1.0
      true -> :math.tanh(a)
    end
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  @doc """
  Inverse hyperbolic sine function.
  
  Special cases:
  - asinh(±0) = ±0
  - asinh(±∞) = ±∞
  """
  def math_asinh(state, [node_index, a]) when is_number(a) do
    result = cond do
      a == :nan -> :nan
      a == 0.0 or a == -0.0 -> a  # Preserve sign of zero
      a == :positive_infinity -> :positive_infinity
      a == :negative_infinity -> :negative_infinity
      true -> :math.asinh(a)
    end
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  @doc """
  Inverse hyperbolic cosine function.
  
  Special cases:
  - acosh(a) where a < 1 = NaN
  - acosh(1) = +0
  - acosh(+∞) = +∞
  """
  def math_acosh(state, [node_index, a]) when is_number(a) do
    result = cond do
      a == :nan -> :nan
      a < 1 -> :nan
      a == 1.0 -> 0.0
      a == :positive_infinity -> :positive_infinity
      true -> :math.acosh(a)
    end
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  @doc """
  Inverse hyperbolic tangent function.
  
  Special cases:
  - atanh(a) where |a| > 1 = NaN
  - atanh(±1) = ±∞
  - atanh(±0) = ±0
  """
  def math_atanh(state, [node_index, a]) when is_number(a) do
    result = cond do
      a == :nan -> :nan
      abs(a) > 1 -> :nan
      a == 1.0 -> :positive_infinity
      a == -1.0 -> :negative_infinity
      a == 0.0 or a == -0.0 -> a  # Preserve sign of zero
      true -> :math.atanh(a)
    end
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end
end
