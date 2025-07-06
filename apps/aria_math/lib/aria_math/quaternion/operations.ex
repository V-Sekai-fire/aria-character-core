# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaMath.Quaternion.Operations do
  @moduledoc """
  Advanced quaternion operations.

  Functions for spherical linear interpolation and vector rotation operations.
  """

  alias AriaMath.Vector3
  alias AriaMath.Quaternion.Core

  @type quaternion :: {float(), float(), float(), float()}

  @doc """
  Spherical linear interpolation between two quaternions.

  Implements spherical linear interpolation (slerp) for smooth quaternion interpolation.
  Uses the shortest path between quaternions.

  ## Examples

      iex> AriaMath.Quaternion.Operations.slerp({0.0, 0.0, 0.0, 1.0}, {1.0, 0.0, 0.0, 0.0}, 0.5)
      {0.7071067811865475, 0.0, 0.0, 0.7071067811865476}
  """
  @spec slerp(quaternion(), quaternion(), float()) :: quaternion()
  def slerp({ax, ay, az, aw} = a, {bx, by, bz, bw} = b, t) when is_number(t) do
    # Calculate dot product
    dot_prod = Core.dot(a, b)

    # Use the shortest path by flipping one quaternion if needed
    {bx, by, bz, bw, dot_prod} =
      if dot_prod < 0.0 do
        {-bx, -by, -bz, -bw, -dot_prod}
      else
        {bx, by, bz, bw, dot_prod}
      end

    # Threshold for linear interpolation to avoid division by zero
    threshold = 0.9995

    cond do
      # If quaternions are very close, use linear interpolation
      dot_prod > threshold ->
        result = {
          ax + t * (bx - ax),
          ay + t * (by - ay),
          az + t * (bz - az),
          aw + t * (bw - aw)
        }

        {normalized, _} = Core.normalize(result)
        normalized

      # Use spherical linear interpolation
      true ->
        theta_0 = :math.acos(abs(dot_prod))
        sin_theta_0 = :math.sin(theta_0)

        theta = theta_0 * t
        sin_theta = :math.sin(theta)

        s0 = :math.cos(theta) - dot_prod * sin_theta / sin_theta_0
        s1 = sin_theta / sin_theta_0

        {
          s0 * ax + s1 * bx,
          s0 * ay + s1 * by,
          s0 * az + s1 * bz,
          s0 * aw + s1 * bw
        }
    end
  end

  @doc """
  Rotate a Vector3 by this quaternion.

  Applies the rotation represented by the quaternion to a 3D vector.
  Uses the efficient formula: v' = v + 2 * cross(q.xyz, cross(q.xyz, v) + q.w * v)

  ## Examples

      iex> AriaMath.Quaternion.Operations.rotate_vector({0.0, 0.0, 0.7071067811865475, 0.7071067811865476}, {1.0, 0.0, 0.0})
      {2.220446049250313e-16, 1.0, 0.0}
  """
  @spec rotate_vector(quaternion(), Vector3.t()) :: Vector3.t()
  def rotate_vector({qx, qy, qz, qw}, {vx, vy, vz}) do
    # Quaternion vector part
    q_vec = {qx, qy, qz}
    v = {vx, vy, vz}

    # v' = v + 2 * cross(q.xyz, cross(q.xyz, v) + q.w * v)
    qw_v = Vector3.scale(v, qw)
    cross1 = Vector3.cross(q_vec, v)
    cross1_plus_qw_v = Vector3.add(cross1, qw_v)
    cross2 = Vector3.cross(q_vec, cross1_plus_qw_v)
    two_cross2 = Vector3.scale(cross2, 2.0)

    Vector3.add(v, two_cross2)
  end

  @doc """
  Rotate a Vector3 by this quaternion (alias for rotate_vector/2).

  This is an alias for rotate_vector/2 to provide compatibility
  with common naming conventions.

  ## Examples

      iex> AriaMath.Quaternion.Operations.rotate({0.0, 0.0, 0.7071067811865475, 0.7071067811865476}, {1.0, 0.0, 0.0})
      {2.220446049250313e-16, 1.0, 0.0}
  """
  @spec rotate(quaternion(), Vector3.t()) :: Vector3.t()
  def rotate(quaternion, vector) do
    rotate_vector(quaternion, vector)
  end
end
