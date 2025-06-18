defmodule AriaEngine.NodeLibrary.KHRInteractivity.MathSwizzle do
  @moduledoc """
  KHR_interactivity Math Swizzle Nodes

  Implements vector/matrix combine and extract operations from the glTF KHR_interactivity specification:
  - khr_math_combine2/3/4: Combine floats into vectors
  - khr_math_combine2x2/3x3/4x4: Combine floats into matrices
  - khr_math_extract2/3/4: Extract floats from vectors
  - khr_math_extract2x2/3x3/4x4: Extract floats from matrices

  All operations handle NaN and infinity according to the KHR_interactivity spec.
  """

  alias AriaEngine.StateV2
  alias AriaEngine.Domain.Actions

  @doc "Register all math swizzle actions with a domain"
  @spec register_actions(AriaEngine.Domain.Core.t()) :: AriaEngine.Domain.Core.t()
  def register_actions(domain) do
    domain
    |> Actions.add_action(:khr_math_combine2, &math_combine2/2, %{
      domain: "khr_interactivity",
      category: "math_swizzle",
      khr_node_type: "math/combine2",
      description: "Combine two floats into a two-component vector"
    })
    |> Actions.add_action(:khr_math_combine3, &math_combine3/2, %{
      domain: "khr_interactivity",
      category: "math_swizzle", 
      khr_node_type: "math/combine3",
      description: "Combine three floats into a three-component vector"
    })
    |> Actions.add_action(:khr_math_combine4, &math_combine4/2, %{
      domain: "khr_interactivity",
      category: "math_swizzle",
      khr_node_type: "math/combine4", 
      description: "Combine four floats into a four-component vector"
    })
    |> Actions.add_action(:khr_math_combine2x2, &math_combine2x2/2, %{
      domain: "khr_interactivity",
      category: "math_swizzle",
      khr_node_type: "math/combine2x2",
      description: "Combine 4 floats into a 2x2 matrix"
    })
    |> Actions.add_action(:khr_math_combine3x3, &math_combine3x3/2, %{
      domain: "khr_interactivity",
      category: "math_swizzle",
      khr_node_type: "math/combine3x3", 
      description: "Combine 9 floats into a 3x3 matrix"
    })
    |> Actions.add_action(:khr_math_combine4x4, &math_combine4x4/2, %{
      domain: "khr_interactivity",
      category: "math_swizzle",
      khr_node_type: "math/combine4x4",
      description: "Combine 16 floats into a 4x4 matrix"
    })
    |> Actions.add_action(:khr_math_extract2, &math_extract2/2, %{
      domain: "khr_interactivity", 
      category: "math_swizzle",
      khr_node_type: "math/extract2",
      description: "Extract two floats from a two-component vector"
    })
    |> Actions.add_action(:khr_math_extract3, &math_extract3/2, %{
      domain: "khr_interactivity",
      category: "math_swizzle",
      khr_node_type: "math/extract3",
      description: "Extract three floats from a three-component vector"
    })
    |> Actions.add_action(:khr_math_extract4, &math_extract4/2, %{
      domain: "khr_interactivity",
      category: "math_swizzle", 
      khr_node_type: "math/extract4",
      description: "Extract four floats from a four-component vector"
    })
    |> Actions.add_action(:khr_math_extract2x2, &math_extract2x2/2, %{
      domain: "khr_interactivity",
      category: "math_swizzle",
      khr_node_type: "math/extract2x2",
      description: "Extract 4 floats from a 2x2 matrix"
    })
    |> Actions.add_action(:khr_math_extract3x3, &math_extract3x3/2, %{
      domain: "khr_interactivity",
      category: "math_swizzle",
      khr_node_type: "math/extract3x3",
      description: "Extract 9 floats from a 3x3 matrix"
    })
    |> Actions.add_action(:khr_math_extract4x4, &math_extract4x4/2, %{
      domain: "khr_interactivity",
      category: "math_swizzle",
      khr_node_type: "math/extract4x4", 
      description: "Extract 16 floats from a 4x4 matrix"
    })
  end

  @doc "Combine two floats into a two-component vector"
  def math_combine2(state, [node_index, a, b]) when is_number(a) and is_number(b) do
    result = [a, b]
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  @doc "Combine three floats into a three-component vector"
  def math_combine3(state, [node_index, a, b, c]) when is_number(a) and is_number(b) and is_number(c) do
    result = [a, b, c]
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  @doc "Combine four floats into a four-component vector"
  def math_combine4(state, [node_index, a, b, c, d]) when is_number(a) and is_number(b) and is_number(c) and is_number(d) do
    result = [a, b, c, d]
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  @doc "Combine 4 floats into a 2x2 matrix (column-major order)"
  def math_combine2x2(state, [node_index, a, b, c, d]) when is_number(a) and is_number(b) and is_number(c) and is_number(d) do
    # Column-major order: [c0r0, c0r1, c1r0, c1r1]
    result = [a, b, c, d]
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  @doc "Combine 9 floats into a 3x3 matrix (column-major order)"
  def math_combine3x3(state, [node_index, a, b, c, d, e, f, g, h, i]) do
    if Enum.all?([a, b, c, d, e, f, g, h, i], &is_number/1) do
      # Column-major order
      result = [a, b, c, d, e, f, g, h, i]
      
      state
      |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
    else
      state
      |> StateV2.set_fact(Integer.to_string(node_index), "value", List.duplicate(:nan, 9))
    end
  end

  @doc "Combine 16 floats into a 4x4 matrix (column-major order)"
  def math_combine4x4(state, [node_index | components]) when length(components) == 16 do
    if Enum.all?(components, &is_number/1) do
      # Column-major order
      result = components
      
      state
      |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
    else
      state
      |> StateV2.set_fact(Integer.to_string(node_index), "value", List.duplicate(:nan, 16))
    end
  end

  @doc "Extract two floats from a two-component vector"
  def math_extract2(state, [node_index, vector]) when is_list(vector) do
    if length(vector) == 2 do
      [a, b] = vector
      
      state
      |> StateV2.set_fact(Integer.to_string(node_index), "0", a)
      |> StateV2.set_fact(Integer.to_string(node_index), "1", b)
    else
      state
      |> StateV2.set_fact(Integer.to_string(node_index), "0", :nan)
      |> StateV2.set_fact(Integer.to_string(node_index), "1", :nan)
    end
  end

  @doc "Extract three floats from a three-component vector"
  def math_extract3(state, [node_index, vector]) when is_list(vector) do
    if length(vector) == 3 do
      [a, b, c] = vector
      
      state
      |> StateV2.set_fact(Integer.to_string(node_index), "0", a)
      |> StateV2.set_fact(Integer.to_string(node_index), "1", b)
      |> StateV2.set_fact(Integer.to_string(node_index), "2", c)
    else
      state
      |> StateV2.set_fact(Integer.to_string(node_index), "0", :nan)
      |> StateV2.set_fact(Integer.to_string(node_index), "1", :nan)
      |> StateV2.set_fact(Integer.to_string(node_index), "2", :nan)
    end
  end

  @doc "Extract four floats from a four-component vector"
  def math_extract4(state, [node_index, vector]) when is_list(vector) do
    if length(vector) == 4 do
      [a, b, c, d] = vector
      
      state
      |> StateV2.set_fact(Integer.to_string(node_index), "0", a)
      |> StateV2.set_fact(Integer.to_string(node_index), "1", b)
      |> StateV2.set_fact(Integer.to_string(node_index), "2", c)
      |> StateV2.set_fact(Integer.to_string(node_index), "3", d)
    else
      state
      |> StateV2.set_fact(Integer.to_string(node_index), "0", :nan)
      |> StateV2.set_fact(Integer.to_string(node_index), "1", :nan)
      |> StateV2.set_fact(Integer.to_string(node_index), "2", :nan)
      |> StateV2.set_fact(Integer.to_string(node_index), "3", :nan)
    end
  end

  @doc "Extract 4 floats from a 2x2 matrix (column-major order)"
  def math_extract2x2(state, [node_index, matrix]) when is_list(matrix) do
    if length(matrix) == 4 do
      [a, b, c, d] = matrix
      
      state
      |> StateV2.set_fact(Integer.to_string(node_index), "0", a)
      |> StateV2.set_fact(Integer.to_string(node_index), "1", b)
      |> StateV2.set_fact(Integer.to_string(node_index), "2", c)
      |> StateV2.set_fact(Integer.to_string(node_index), "3", d)
    else
      state
      |> StateV2.set_fact(Integer.to_string(node_index), "0", :nan)
      |> StateV2.set_fact(Integer.to_string(node_index), "1", :nan)
      |> StateV2.set_fact(Integer.to_string(node_index), "2", :nan)
      |> StateV2.set_fact(Integer.to_string(node_index), "3", :nan)
    end
  end

  @doc "Extract 9 floats from a 3x3 matrix (column-major order)"
  def math_extract3x3(state, [node_index, matrix]) when is_list(matrix) do
    if length(matrix) == 9 do
      Enum.with_index(matrix)
      |> Enum.reduce(state, fn {value, index}, acc_state ->
        StateV2.set_fact(acc_state, Integer.to_string(node_index), Integer.to_string(index), value)
      end)
    else
      Enum.reduce(0..8, state, fn index, acc_state ->
        StateV2.set_fact(acc_state, Integer.to_string(node_index), Integer.to_string(index), :nan)
      end)
    end
  end

  @doc "Extract 16 floats from a 4x4 matrix (column-major order)"
  def math_extract4x4(state, [node_index, matrix]) when is_list(matrix) do
    if length(matrix) == 16 do
      Enum.with_index(matrix)
      |> Enum.reduce(state, fn {value, index}, acc_state ->
        StateV2.set_fact(acc_state, Integer.to_string(node_index), Integer.to_string(index), value)
      end)
    else
      Enum.reduce(0..15, state, fn index, acc_state ->
        StateV2.set_fact(acc_state, Integer.to_string(node_index), Integer.to_string(index), :nan)
      end)
    end
  end
end
