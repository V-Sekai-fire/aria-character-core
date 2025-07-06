# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaQcp.QCP.SinglePoint do
  @moduledoc """
  Single point rotation calculations for the QCP algorithm.

  Handles the special case of aligning two single points using quaternion rotation.
  """

  alias AriaMath.{Vector3, Quaternion}
  alias AriaQcp.QCP.Utils

  @doc """
  Calculates rotation quaternion for aligning two single points.
  """
  @spec calculate_single_point_rotation(Vector3.t(), Vector3.t()) :: {:ok, Quaternion.t()}
  def calculate_single_point_rotation(moved_point, target_point) do
    u_length = Vector3.length(moved_point)
    v_length = Vector3.length(target_point)

    # Handle zero-length vectors
    if u_length < 1.0e-15 or v_length < 1.0e-15 do
      {:ok, {0.0, 0.0, 0.0, 1.0}}
    else
      # Normalize the vectors
      {u_norm, _} = Vector3.normalize(moved_point)
      {v_norm, _} = Vector3.normalize(target_point)

      dot = Vector3.dot(u_norm, v_norm)

      quaternion = cond do
        # Vectors are already aligned (within tolerance)
        dot > 0.9999999 ->
          {0.0, 0.0, 0.0, 1.0}

        # Vectors are opposite (180-degree rotation needed)
        dot < -0.9999999 ->
          # Find a perpendicular axis for 180-degree rotation
          {ux, uy, _uz} = u_norm

          # Choose the axis that gives the largest cross product component
          perp_axis = cond do
            abs(ux) < 0.9 -> {1.0, 0.0, 0.0}
            abs(uy) < 0.9 -> {0.0, 1.0, 0.0}
            true -> {0.0, 0.0, 1.0}
          end

          cross = Vector3.cross(u_norm, perp_axis)
          {normalized_cross, _} = Vector3.normalize(cross)
          {cx, cy, cz} = normalized_cross

          # 180-degree rotation quaternion: (x, y, z, w) where w = 0
          {cx, cy, cz, 0.0}

        # General case: rotation between non-opposite vectors
        true ->
          # Use the half-angle formula for quaternion from two vectors
          # This is more numerically stable than the standard formula

          # Calculate the half-way vector (bisector)
          half_way = Vector3.add(u_norm, v_norm)
          {half_way_normalized, success} = Vector3.normalize(half_way)

          if success do
            # Calculate quaternion using half-way vector method
            # q = [cross(u, half_way), dot(u, half_way)]
            cross = Vector3.cross(u_norm, half_way_normalized)
            w = Vector3.dot(u_norm, half_way_normalized)
            {x, y, z} = cross

            # This should already be normalized, but verify
            quat_magnitude = :math.sqrt(x*x + y*y + z*z + w*w)
            if quat_magnitude > 1.0e-15 do
              {x / quat_magnitude, y / quat_magnitude, z / quat_magnitude, w / quat_magnitude}
            else
              {0.0, 0.0, 0.0, 1.0}
            end
          else
            # Fallback to standard method if half-way vector fails
            cross = Vector3.cross(u_norm, v_norm)
            {x, y, z} = cross
            w = 1.0 + dot

            quat_magnitude = :math.sqrt(x*x + y*y + z*z + w*w)
            if quat_magnitude > 1.0e-15 do
              {x / quat_magnitude, y / quat_magnitude, z / quat_magnitude, w / quat_magnitude}
            else
              {0.0, 0.0, 0.0, 1.0}
            end
          end
      end

      # Apply RMD check to ensure pure rotation
      final_quaternion = Utils.apply_rmd_flipping_check(quaternion)

      {:ok, final_quaternion}
    end
  end
end
