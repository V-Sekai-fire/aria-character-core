# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule NodeLibrary.KHRInteractivity.MathExponential do
  @moduledoc """
  KHR_interactivity Math Exponential Nodes

  Implements exponential operations from the glTF KHR_interactivity specification:
  - khr_math_exp: Exponent function (e^a)
  - khr_math_log: Natural logarithm function
  - khr_math_log2: Base-2 logarithm function
  - khr_math_log10: Base-10 logarithm function
  - khr_math_sqrt: Square root function
  - khr_math_cbrt: Cube root function
  - khr_math_pow: Power function (a^b)

  All operations handle NaN and infinity according to the KHR_interactivity spec.
  """

  alias StateV2
  alias Domain.Actions

  @doc "Register all math exponential actions with a domain"
  @spec register_actions(Domain.Core.t()) :: Domain.Core.t()
  def register_actions(domain) do
    domain
    |> Actions.add_action(:khr_math_exp, &math_exp/2, %{
      domain: "khr_interactivity",
      category: "math_exponential",
      khr_node_type: "math/exp",
      description: "Exponent function"
    })
    |> Actions.add_action(:khr_math_log, &math_log/2, %{
      domain: "khr_interactivity",
      category: "math_exponential",
      khr_node_type: "math/log",
      description: "Natural logarithm function"
    })
    |> Actions.add_action(:khr_math_log2, &math_log2/2, %{
      domain: "khr_interactivity",
      category: "math_exponential",
      khr_node_type: "math/log2",
      description: "Base-2 logarithm function"
    })
    |> Actions.add_action(:khr_math_log10, &math_log10/2, %{
      domain: "khr_interactivity",
      category: "math_exponential",
      khr_node_type: "math/log10",
      description: "Base-10 logarithm function"
    })
    |> Actions.add_action(:khr_math_sqrt, &math_sqrt/2, %{
      domain: "khr_interactivity",
      category: "math_exponential",
      khr_node_type: "math/sqrt",
      description: "Square root function"
    })
    |> Actions.add_action(:khr_math_cbrt, &math_cbrt/2, %{
      domain: "khr_interactivity",
      category: "math_exponential",
      khr_node_type: "math/cbrt",
      description: "Cube root function"
    })
    |> Actions.add_action(:khr_math_pow, &math_pow/2, %{
      domain: "khr_interactivity",
      category: "math_exponential",
      khr_node_type: "math/pow",
      description: "Power function"
    })
  end

  @doc """
  Exponent function (e^a).
  
  Special cases:
  - exp(-∞) = +0
  - exp(±0) = +1
  - exp(+∞) = +∞
  """
  def math_exp(state, [node_index, a]) when is_number(a) do
    result = cond do
      a == :nan -> :nan
      a == :negative_infinity -> 0.0
      a == 0.0 or a == -0.0 -> 1.0
      a == :positive_infinity -> :positive_infinity
      true -> :math.exp(a)
    end
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  @doc """
  Natural logarithm function.
  
  Special cases:
  - log(a) where a < 0 = NaN
  - log(±0) = -∞
  - log(+1) = +0
  - log(+∞) = +∞
  """
  def math_log(state, [node_index, a]) when is_number(a) do
    result = cond do
      a == :nan -> :nan
      a < 0 -> :nan
      a == 0.0 or a == -0.0 -> :negative_infinity
      a == 1.0 -> 0.0
      a == :positive_infinity -> :positive_infinity
      true -> :math.log(a)
    end
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  @doc """
  Base-2 logarithm function.
  
  Special cases:
  - log2(a) where a < 0 = NaN
  - log2(±0) = -∞
  - log2(+1) = +0
  - log2(+∞) = +∞
  """
  def math_log2(state, [node_index, a]) when is_number(a) do
    result = cond do
      a == :nan -> :nan
      a < 0 -> :nan
      a == 0.0 or a == -0.0 -> :negative_infinity
      a == 1.0 -> 0.0
      a == :positive_infinity -> :positive_infinity
      true -> :math.log2(a)
    end
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  @doc """
  Base-10 logarithm function.
  
  Special cases:
  - log10(a) where a < 0 = NaN
  - log10(±0) = -∞
  - log10(+1) = +0
  - log10(+∞) = +∞
  """
  def math_log10(state, [node_index, a]) when is_number(a) do
    result = cond do
      a == :nan -> :nan
      a < 0 -> :nan
      a == 0.0 or a == -0.0 -> :negative_infinity
      a == 1.0 -> 0.0
      a == :positive_infinity -> :positive_infinity
      true -> :math.log10(a)
    end
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  @doc """
  Square root function.
  
  Special cases:
  - sqrt(a) where a < 0 = NaN
  - sqrt(±0) = ±0
  - sqrt(+∞) = +∞
  """
  def math_sqrt(state, [node_index, a]) when is_number(a) do
    result = cond do
      a == :nan -> :nan
      a < 0 -> :nan
      a == 0.0 or a == -0.0 -> a  # Preserve sign of zero
      a == :positive_infinity -> :positive_infinity
      true -> :math.sqrt(a)
    end
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  @doc """
  Cube root function.
  
  Special cases:
  - cbrt(±0) = ±0
  - cbrt(±∞) = ±∞
  """
  def math_cbrt(state, [node_index, a]) when is_number(a) do
    result = cond do
      a == :nan -> :nan
      a == 0.0 or a == -0.0 -> a  # Preserve sign of zero
      a == :positive_infinity -> :positive_infinity
      a == :negative_infinity -> :negative_infinity
      true -> 
        # Elixir doesn't have a built-in cbrt, so we implement it
        if a >= 0 do
          :math.pow(a, 1.0/3.0)
        else
          -:math.pow(-a, 1.0/3.0)
        end
    end
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  @doc """
  Power function (a^b).
  
  Follows IEEE-754 standard with KHR_interactivity modifications:
  - NaN^(±0) = 1
  - (+1)^(±∞) = NaN
  - (-1)^(±∞) = NaN  
  - (±1)^NaN = NaN
  """
  def math_pow(state, [node_index, a, b]) when is_number(a) and is_number(b) do
    result = cond do
      # KHR_interactivity special cases that differ from IEEE-754
      a == :nan and (b == 0.0 or b == -0.0) -> 1.0
      (a == 1.0 or a == -1.0) and (b == :positive_infinity or b == :negative_infinity) -> :nan
      (a == 1.0 or a == -1.0) and b == :nan -> :nan
      
      # Standard IEEE-754 cases (handled by Elixir's :math.pow)
      true -> :math.pow(a, b)
    end
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end
end
