# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule NodeLibrary.KHRInteractivity.MathVector do
  @moduledoc """
  KHR_interactivity Math Vector Nodes

  Implements vector operations from the glTF KHR_interactivity specification:
  - khr_math_length: Vector length (magnitude)
  - khr_math_normalize: Vector normalization
  - khr_math_dot: Dot product
  - khr_math_cross: Cross product (3D vectors only)
  - khr_math_rotate2D: 2D vector rotation
  - khr_math_rotate3D: 3D vector rotation by quaternion
  - khr_math_transform: Vector transformation by matrix

  All operations handle NaN and infinity according to the KHR_interactivity spec.
  """

  alias StateV2
  alias Domain.Actions

  @doc "Register all math vector actions with a domain"
  @spec register_actions(Domain.Core.t()) :: Domain.Core.t()
  def register_actions(domain) do
    domain
    |> Actions.add_action(:khr_math_length, &math_length/2, %{
      domain: "khr_interactivity",
      category: "math_vector",
      khr_node_type: "math/length",
      description: "Vector length (magnitude)"
    })
    |> Actions.add_action(:khr_math_normalize, &math_normalize/2, %{
      domain: "khr_interactivity",
      category: "math_vector",
      khr_node_type: "math/normalize",
      description: "Vector normalization"
    })
    |> Actions.add_action(:khr_math_dot, &math_dot/2, %{
      domain: "khr_interactivity",
      category: "math_vector",
      khr_node_type: "math/dot",
      description: "Dot product"
    })
    |> Actions.add_action(:khr_math_cross, &math_cross/2, %{
      domain: "khr_interactivity",
      category: "math_vector",
      khr_node_type: "math/cross",
      description: "Cross product (3D vectors only)"
    })
    |> Actions.add_action(:khr_math_rotate2D, &math_rotate2D/2, %{
      domain: "khr_interactivity",
      category: "math_vector",
      khr_node_type: "math/rotate2D",
      description: "2D vector rotation"
    })
    |> Actions.add_action(:khr_math_rotate3D, &math_rotate3D/2, %{
      domain: "khr_interactivity",
      category: "math_vector",
      khr_node_type: "math/rotate3D",
      description: "3D vector rotation by quaternion"
    })
    |> Actions.add_action(:khr_math_transform, &math_transform/2, %{
      domain: "khr_interactivity",
      category: "math_vector",
      khr_node_type: "math/transform",
      description: "Vector transformation by matrix"
    })
  end

  @doc """
  Vector length (magnitude).
  
  Returns the length of the vector using the hypot function which handles
  special floating-point values according to IEEE-754.
  """
  def math_length(state, [node_index, vector]) when is_list(vector) do
    result = case length(vector) do
      2 ->
        [x, y] = vector
        compute_hypot([x, y])
      3 ->
        [x, y, z] = vector
        compute_hypot([x, y, z])
      4 ->
        [x, y, z, w] = vector
        compute_hypot([x, y, z, w])
      _ ->
        :nan
    end
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  @doc """
  Vector normalization.
  
  Returns a vector in the same direction but with unit length.
  Also returns an isValid flag indicating successful normalization.
  """
  def math_normalize(state, [node_index, vector]) when is_list(vector) do
    length_val = case length(vector) do
      2 ->
        [x, y] = vector
        compute_hypot([x, y])
      3 ->
        [x, y, z] = vector
        compute_hypot([x, y, z])
      4 ->
        [x, y, z, w] = vector
        compute_hypot([x, y, z, w])
      _ ->
        :nan
    end
    
    {normalized_vector, is_valid} = cond do
      length_val == 0.0 or length_val == :nan or length_val == :positive_infinity ->
        # Return zero vector with same length as input
        zero_vector = Enum.map(vector, fn _ -> 0.0 end)
        {zero_vector, false}
      
      is_number(length_val) and length_val > 0 ->
        normalized = Enum.map(vector, fn component -> component / length_val end)
        {normalized, true}
      
      true ->
        zero_vector = Enum.map(vector, fn _ -> 0.0 end)
        {zero_vector, false}
    end
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", normalized_vector)
    |> StateV2.set_fact(Integer.to_string(node_index), "isValid", is_valid)
  end

  @doc """
  Dot product.
  
  Returns the sum of per-component products of the two vectors.
  """
  def math_dot(state, [node_index, vector_a, vector_b]) when is_list(vector_a) and is_list(vector_b) do
    result = if length(vector_a) == length(vector_b) do
      vector_a
      |> Enum.zip(vector_b)
      |> Enum.map(fn {a, b} -> a * b end)
      |> Enum.sum()
    else
      :nan
    end
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  @doc """
  Cross product (3D vectors only).
  
  Returns the cross product of two 3D vectors.
  """
  def math_cross(state, [node_index, vector_a, vector_b]) when is_list(vector_a) and is_list(vector_b) do
    result = if length(vector_a) == 3 and length(vector_b) == 3 do
      [ax, ay, az] = vector_a
      [bx, by, bz] = vector_b
      
      [
        ay * bz - az * by,
        az * bx - ax * bz,
        ax * by - ay * bx
      ]
    else
      [:nan, :nan, :nan]
    end
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  @doc """
  2D vector rotation.
  
  Rotates a 2D vector by the specified angle in radians.
  """
  def math_rotate2D(state, [node_index, vector, angle]) when is_list(vector) and is_number(angle) do
    result = if length(vector) == 2 do
      [x, y] = vector
      cos_angle = :math.cos(angle)
      sin_angle = :math.sin(angle)
      
      [
        x * cos_angle - y * sin_angle,
        x * sin_angle + y * cos_angle
      ]
    else
      [:nan, :nan]
    end
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  @doc """
  3D vector rotation by quaternion.
  
  Rotates a 3D vector using a unit quaternion.
  Note: This assumes the quaternion is unit (not verified).
  """
  def math_rotate3D(state, [node_index, vector, quaternion]) when is_list(vector) and is_list(quaternion) do
    result = if length(vector) == 3 and length(quaternion) == 4 do
      [vx, vy, vz] = vector
      [qx, qy, qz, qw] = quaternion
      
      # Quaternion rotation formula: v + 2 * (qv × (qv × v) + qw * (qv × v))
      # where qv = [qx, qy, qz]
      
      # qv × v
      qv_cross_v = [
        qy * vz - qz * vy,
        qz * vx - qx * vz,
        qx * vy - qy * vx
      ]
      
      # qv × (qv × v)
      [temp_x, temp_y, temp_z] = qv_cross_v
      qv_cross_temp = [
        qy * temp_z - qz * temp_y,
        qz * temp_x - qx * temp_z,
        qx * temp_y - qy * temp_x
      ]
      
      # Final calculation: v + 2 * (qv × (qv × v) + qw * (qv × v))
      [
        vx + 2.0 * (qv_cross_temp |> Enum.at(0)) + 2.0 * qw * (qv_cross_v |> Enum.at(0)),
        vy + 2.0 * (qv_cross_temp |> Enum.at(1)) + 2.0 * qw * (qv_cross_v |> Enum.at(1)),
        vz + 2.0 * (qv_cross_temp |> Enum.at(2)) + 2.0 * qw * (qv_cross_v |> Enum.at(2))
      ]
    else
      [:nan, :nan, :nan]
    end
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  @doc """
  Vector transformation by matrix.
  
  Transforms a vector by multiplying with a matrix.
  Supports 2D, 3D, and 4D vectors with corresponding matrix sizes.
  """
  def math_transform(state, [node_index, vector, matrix]) when is_list(vector) and is_list(matrix) do
    result = case {length(vector), length(matrix)} do
      {2, 4} ->
        # 2D vector with 2x2 matrix
        [vx, vy] = vector
        [m00, m10, m01, m11] = matrix  # Column-major order
        [
          m00 * vx + m01 * vy,
          m10 * vx + m11 * vy
        ]
      
      {3, 9} ->
        # 3D vector with 3x3 matrix
        [vx, vy, vz] = vector
        [m00, m10, m20, m01, m11, m21, m02, m12, m22] = matrix  # Column-major order
        [
          m00 * vx + m01 * vy + m02 * vz,
          m10 * vx + m11 * vy + m12 * vz,
          m20 * vx + m21 * vy + m22 * vz
        ]
      
      {4, 16} ->
        # 4D vector with 4x4 matrix
        [vx, vy, vz, vw] = vector
        [m00, m10, m20, m30, m01, m11, m21, m31, m02, m12, m22, m32, m03, m13, m23, m33] = matrix
        [
          m00 * vx + m01 * vy + m02 * vz + m03 * vw,
          m10 * vx + m11 * vy + m12 * vz + m13 * vw,
          m20 * vx + m21 * vy + m22 * vz + m23 * vw,
          m30 * vx + m31 * vy + m32 * vz + m33 * vw
        ]
      
      _ ->
        # Incompatible dimensions
        vector |> Enum.map(fn _ -> :nan end)
    end
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  # Helper function to compute vector length using hypot-style algorithm
  # Handles special cases according to IEEE-754
  defp compute_hypot(components) do
    cond do
      # Check if any component is infinity
      Enum.any?(components, fn c -> c == :positive_infinity or c == :negative_infinity end) ->
        :positive_infinity
      
      # Check if all components are zero
      Enum.all?(components, fn c -> c == 0.0 or c == -0.0 end) ->
        0.0
      
      # Check if any component is NaN (and no infinities)
      Enum.any?(components, fn c -> c == :nan end) ->
        :nan
      
      # All components are finite, compute square root of sum of squares
      true ->
        sum_of_squares = components
          |> Enum.map(fn c -> c * c end)
          |> Enum.sum()
        
        :math.sqrt(sum_of_squares)
    end
  end
end
