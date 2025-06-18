defmodule AriaEngine.NodeLibrary.KHRInteractivity.MathTrigonometry do
  @moduledoc """
  KHR_interactivity Math Trigonometry Nodes

  Implements trigonometric operations from the glTF KHR_interactivity specification:
  - khr_math_rad: Converts degrees to radians
  - khr_math_deg: Converts radians to degrees
  - khr_math_sin: Sine function
  - khr_math_cos: Cosine function
  - khr_math_tan: Tangent function
  - khr_math_asin: Arcsine function
  - khr_math_acos: Arccosine function
  - khr_math_atan: Arctangent function
  - khr_math_atan2: Arctangent 2 function

  All operations handle NaN and infinity according to the KHR_interactivity spec.
  """

  alias AriaEngine.StateV2
  alias AriaEngine.Domain.Actions

  @doc "Register all math trigonometry actions with a domain"
  @spec register_actions(AriaEngine.Domain.Core.t()) :: AriaEngine.Domain.Core.t()
  def register_actions(domain) do
    domain
    |> Actions.add_action(:khr_math_rad, &math_rad/2, %{
      domain: "khr_interactivity",
      category: "math_trigonometry",
      khr_node_type: "math/rad",
      description: "Converts degrees to radians"
    })
    |> Actions.add_action(:khr_math_deg, &math_deg/2, %{
      domain: "khr_interactivity",
      category: "math_trigonometry",
      khr_node_type: "math/deg",
      description: "Converts radians to degrees"
    })
    |> Actions.add_action(:khr_math_sin, &math_sin/2, %{
      domain: "khr_interactivity",
      category: "math_trigonometry",
      khr_node_type: "math/sin",
      description: "Sine function"
    })
    |> Actions.add_action(:khr_math_cos, &math_cos/2, %{
      domain: "khr_interactivity",
      category: "math_trigonometry",
      khr_node_type: "math/cos",
      description: "Cosine function"
    })
    |> Actions.add_action(:khr_math_tan, &math_tan/2, %{
      domain: "khr_interactivity",
      category: "math_trigonometry",
      khr_node_type: "math/tan",
      description: "Tangent function"
    })
    |> Actions.add_action(:khr_math_asin, &math_asin/2, %{
      domain: "khr_interactivity",
      category: "math_trigonometry",
      khr_node_type: "math/asin",
      description: "Arcsine function"
    })
    |> Actions.add_action(:khr_math_acos, &math_acos/2, %{
      domain: "khr_interactivity",
      category: "math_trigonometry",
      khr_node_type: "math/acos",
      description: "Arccosine function"
    })
    |> Actions.add_action(:khr_math_atan, &math_atan/2, %{
      domain: "khr_interactivity",
      category: "math_trigonometry",
      khr_node_type: "math/atan",
      description: "Arctangent function"
    })
    |> Actions.add_action(:khr_math_atan2, &math_atan2/2, %{
      domain: "khr_interactivity",
      category: "math_trigonometry",
      khr_node_type: "math/atan2",
      description: "Arctangent 2 function"
    })
  end

  @doc """
  Converts degrees to radians.
  
  Returns a * π / 180
  """
  def math_rad(state, [node_index, a]) when is_number(a) do
    result = a * :math.pi() / 180.0
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  @doc """
  Converts radians to degrees.
  
  Returns a * 180 / π
  """
  def math_deg(state, [node_index, a]) when is_number(a) do
    result = a * 180.0 / :math.pi()
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  @doc """
  Sine function.
  
  Special cases:
  - sin(±0) = ±0
  - sin(±∞) = NaN
  """
  def math_sin(state, [node_index, a]) when is_number(a) do
    result = cond do
      a == :nan -> :nan
      a == :positive_infinity or a == :negative_infinity -> :nan
      a == 0.0 or a == -0.0 -> a  # Preserve sign of zero
      true -> :math.sin(a)
    end
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  @doc """
  Cosine function.
  
  Special cases:
  - cos(±0) = +1
  - cos(±∞) = NaN
  """
  def math_cos(state, [node_index, a]) when is_number(a) do
    result = cond do
      a == :nan -> :nan
      a == :positive_infinity or a == :negative_infinity -> :nan
      a == 0.0 or a == -0.0 -> 1.0
      true -> :math.cos(a)
    end
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  @doc """
  Tangent function.
  
  Special cases:
  - tan(±0) = ±0
  - tan(±∞) = NaN
  """
  def math_tan(state, [node_index, a]) when is_number(a) do
    result = cond do
      a == :nan -> :nan
      a == :positive_infinity or a == :negative_infinity -> :nan
      a == 0.0 or a == -0.0 -> a  # Preserve sign of zero
      true -> :math.tan(a)
    end
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  @doc """
  Arcsine function.
  
  Special cases:
  - asin(±0) = ±0
  - asin(a) where |a| > 1 = NaN
  - Returns value in [-π/2, π/2]
  """
  def math_asin(state, [node_index, a]) when is_number(a) do
    result = cond do
      a == :nan -> :nan
      a == 0.0 or a == -0.0 -> a  # Preserve sign of zero
      abs(a) > 1 -> :nan
      true -> :math.asin(a)
    end
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  @doc """
  Arccosine function.
  
  Special cases:
  - acos(1) = +0
  - acos(a) where |a| > 1 = NaN
  - Returns value in [0, π]
  """
  def math_acos(state, [node_index, a]) when is_number(a) do
    result = cond do
      a == :nan -> :nan
      a == 1.0 -> 0.0
      abs(a) > 1 -> :nan
      true -> :math.acos(a)
    end
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  @doc """
  Arctangent function.
  
  Special cases:
  - atan(±0) = ±0
  - atan(±∞) = ±π/2
  - Returns value in [-π/2, π/2]
  """
  def math_atan(state, [node_index, a]) when is_number(a) do
    result = cond do
      a == :nan -> :nan
      a == 0.0 or a == -0.0 -> a  # Preserve sign of zero
      a == :positive_infinity -> :math.pi() / 2.0
      a == :negative_infinity -> -:math.pi() / 2.0
      true -> :math.atan(a)
    end
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  @doc """
  Arctangent 2 function.
  
  Returns the angle between the positive X-axis and the vector from (0,0) to (X,Y).
  Follows IEEE-754 standard for all special cases.
  """
  def math_atan2(state, [node_index, y, x]) when is_number(y) and is_number(x) do
    result = :math.atan2(y, x)
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end
end
