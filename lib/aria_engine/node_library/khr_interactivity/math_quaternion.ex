# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.NodeLibrary.KHRInteractivity.MathQuaternion do
  @moduledoc """
  KHR_interactivity Math Quaternion Nodes

  Implements quaternion operations from the glTF KHR_interactivity specification:
  - khr_math_quatConjugate: Quaternion conjugation
  - khr_math_quatMul: Quaternion multiplication
  - khr_math_quatAngleBetween: Angle between two quaternions
  - khr_math_quatFromAxisAngle: Create quaternion from axis and angle
  - khr_math_quatToAxisAngle: Decompose quaternion to axis and angle
  - khr_math_quatFromDirections: Create quaternion from two directional vectors

  All operations handle NaN and infinity according to the KHR_interactivity spec.
  """

  alias AriaEngine.StateV2
  alias AriaEngine.Domain.Actions

  @doc "Register all math quaternion actions with a domain"
  @spec register_actions(AriaEngine.Domain.Core.t()) :: AriaEngine.Domain.Core.t()
  def register_actions(domain) do
    domain
    |> Actions.add_action(:khr_math_quatConjugate, &math_quat_conjugate/2, %{
      domain: "khr_interactivity",
      category: "math_quaternion",
      khr_node_type: "math/quatConjugate",
      description: "Quaternion conjugation"
    })
    |> Actions.add_action(:khr_math_quatMul, &math_quat_mul/2, %{
      domain: "khr_interactivity",
      category: "math_quaternion",
      khr_node_type: "math/quatMul",
      description: "Quaternion multiplication"
    })
    |> Actions.add_action(:khr_math_quatAngleBetween, &math_quat_angle_between/2, %{
      domain: "khr_interactivity",
      category: "math_quaternion",
      khr_node_type: "math/quatAngleBetween",
      description: "Angle between two quaternions"
    })
    |> Actions.add_action(:khr_math_quatFromAxisAngle, &math_quat_from_axis_angle/2, %{
      domain: "khr_interactivity",
      category: "math_quaternion",
      khr_node_type: "math/quatFromAxisAngle",
      description: "Create quaternion from axis and angle"
    })
    |> Actions.add_action(:khr_math_quatToAxisAngle, &math_quat_to_axis_angle/2, %{
      domain: "khr_interactivity",
      category: "math_quaternion",
      khr_node_type: "math/quatToAxisAngle",
      description: "Decompose quaternion to axis and angle"
    })
    |> Actions.add_action(:khr_math_quatFromDirections, &math_quat_from_directions/2, %{
      domain: "khr_interactivity",
      category: "math_quaternion",
      khr_node_type: "math/quatFromDirections",
      description: "Create quaternion from two directional vectors"
    })
  end

  @doc """
  Quaternion conjugation.
  
  Returns the conjugated quaternion by negating the X, Y, Z components.
  """
  def math_quat_conjugate(state, [node_index, quaternion]) when is_list(quaternion) do
    result = if length(quaternion) == 4 do
      [x, y, z, w] = quaternion
      [-x, -y, -z, w]
    else
      [:nan, :nan, :nan, :nan]
    end
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  @doc """
  Quaternion multiplication.
  
  Returns the product of two quaternions using the standard quaternion multiplication formula.
  """
  def math_quat_mul(state, [node_index, quat_a, quat_b]) when is_list(quat_a) and is_list(quat_b) do
    result = if length(quat_a) == 4 and length(quat_b) == 4 do
      [ax, ay, az, aw] = quat_a
      [bx, by, bz, bw] = quat_b
      
      [
        aw * bx + ax * bw + ay * bz - az * by,
        aw * by + ay * bw + az * bx - ax * bz,
        aw * bz + az * bw + ax * by - ay * bx,
        aw * bw - ax * bx - ay * by - az * bz
      ]
    else
      [:nan, :nan, :nan, :nan]
    end
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  @doc """
  Angle between two quaternions.
  
  Returns the angle in radians between two unit quaternions.
  Assumes both input quaternions are unit quaternions.
  """
  def math_quat_angle_between(state, [node_index, quat_a, quat_b]) when is_list(quat_a) and is_list(quat_b) do
    result = if length(quat_a) == 4 and length(quat_b) == 4 do
      [ax, ay, az, aw] = quat_a
      [bx, by, bz, bw] = quat_b
      
      # Compute dot product
      dot_product = ax * bx + ay * by + az * bz + aw * bw
      
      # Clamp to prevent acos domain errors
      clamped_dot = cond do
        dot_product > 1.0 -> 1.0
        dot_product < -1.0 -> -1.0
        true -> dot_product
      end
      
      2.0 * :math.acos(abs(clamped_dot))
    else
      :nan
    end
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  @doc """
  Create quaternion from axis and angle.
  
  Creates a unit quaternion from a rotation axis and angle in radians.
  Assumes the rotation axis vector is unit.
  """
  def math_quat_from_axis_angle(state, [node_index, axis, angle]) when is_list(axis) and is_number(angle) do
    result = if length(axis) == 3 do
      [axis_x, axis_y, axis_z] = axis
      half_angle = angle * 0.5
      sin_half = :math.sin(half_angle)
      cos_half = :math.cos(half_angle)
      
      [
        axis_x * sin_half,
        axis_y * sin_half,
        axis_z * sin_half,
        cos_half
      ]
    else
      [:nan, :nan, :nan, :nan]
    end
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end

  @doc """
  Decompose quaternion to axis and angle.
  
  Decomposes a unit quaternion into rotation axis and angle in radians.
  Assumes the rotation quaternion is unit.
  """
  def math_quat_to_axis_angle(state, [node_index, quaternion]) when is_list(quaternion) do
    {axis, angle} = if length(quaternion) == 4 do
      [x, y, z, w] = quaternion
      
      # Handle near-identity quaternion
      if abs(w) >= 0.9999 do
        # Return arbitrary axis-aligned unit vector and zero angle
        {[1.0, 0.0, 0.0], 0.0}
      else
        # Standard decomposition
        sin_half_theta = :math.sqrt(1.0 - w * w)
        
        axis_result = [
          x / sin_half_theta,
          y / sin_half_theta,
          z / sin_half_theta
        ]
        
        angle_result = 2.0 * :math.acos(abs(w))
        
        {axis_result, angle_result}
      end
    else
      {[:nan, :nan, :nan], :nan}
    end
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "axis", axis)
    |> StateV2.set_fact(Integer.to_string(node_index), "angle", angle)
  end

  @doc """
  Create quaternion from two directional vectors.
  
  Creates a quaternion that rotates from the first direction to the second.
  Assumes both directions are unit vectors.
  """
  def math_quat_from_directions(state, [node_index, dir_a, dir_b]) when is_list(dir_a) and is_list(dir_b) do
    result = if length(dir_a) == 3 and length(dir_b) == 3 do
      [ax, ay, az] = dir_a
      [bx, by, bz] = dir_b
      
      # Compute dot product
      dot = ax * bx + ay * by + az * bz
      
      cond do
        # Vectors are nearly identical
        dot >= 0.9999 ->
          [0.0, 0.0, 0.0, 1.0]
        
        # Vectors are nearly opposite
        dot <= -0.9999 ->
          # Find a perpendicular vector
          perp = cond do
            abs(ax) < 0.1 -> [1.0, 0.0, 0.0]
            abs(ay) < 0.1 -> [0.0, 1.0, 0.0]
            true -> [0.0, 0.0, 1.0]
          end
          
          # Cross product with perpendicular vector
          cross_x = ay * Enum.at(perp, 2) - az * Enum.at(perp, 1)
          cross_y = az * Enum.at(perp, 0) - ax * Enum.at(perp, 2)
          cross_z = ax * Enum.at(perp, 1) - ay * Enum.at(perp, 0)
          
          # Normalize
          length = :math.sqrt(cross_x * cross_x + cross_y * cross_y + cross_z * cross_z)
          
          if length > 0.0 do
            [cross_x / length, cross_y / length, cross_z / length, 0.0]
          else
            [1.0, 0.0, 0.0, 0.0]
          end
        
        # General case
        true ->
          # Cross product
          cross_x = ay * bz - az * by
          cross_y = az * bx - ax * bz
          cross_z = ax * by - ay * bx
          
          # Quaternion components
          w = :math.sqrt(0.5 + 0.5 * dot)
          xyz_scale = :math.sqrt(0.5 - 0.5 * dot)
          
          # Normalize cross product and scale
          cross_length = :math.sqrt(cross_x * cross_x + cross_y * cross_y + cross_z * cross_z)
          
          if cross_length > 0.0 do
            [
              (cross_x / cross_length) * xyz_scale,
              (cross_y / cross_length) * xyz_scale,
              (cross_z / cross_length) * xyz_scale,
              w
            ]
          else
            [0.0, 0.0, 0.0, 1.0]
          end
      end
    else
      [:nan, :nan, :nan, :nan]
    end
    
    state
    |> StateV2.set_fact(Integer.to_string(node_index), "value", result)
  end
end
