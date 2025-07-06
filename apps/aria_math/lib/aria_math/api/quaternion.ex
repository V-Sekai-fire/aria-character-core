# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaMath.API.Quaternion do
  @moduledoc """
  Quaternion operations for the AriaMath external API.

  This module contains all Quaternion-related delegations and operations
  for the AriaMath external API, keeping the main API module focused.
  """

  alias AriaMath.Quaternion

  @doc """
  Create a quaternion from four components.

  ## Examples

      iex> AriaMath.API.Quaternion.quaternion(0.0, 0.0, 0.0, 1.0)
      {0.0, 0.0, 0.0, 1.0}
  """
  def quaternion(x, y, z, w), do: {x / 1, y / 1, z / 1, w / 1}

  @doc """
  Create an identity quaternion.

  ## Examples

      iex> AriaMath.API.Quaternion.identity_quaternion()
      {0.0, 0.0, 0.0, 1.0}
  """
  def identity_quaternion(), do: {0.0, 0.0, 0.0, 1.0}

  @doc """
  Create a quaternion from axis-angle representation.

  ## Examples

      iex> AriaMath.API.Quaternion.quaternion_from_axis_angle({0.0, 0.0, 1.0}, :math.pi / 2)
      {0.0, 0.0, 0.7071067811865476, 0.7071067811865475}
  """
  defdelegate quaternion_from_axis_angle(axis, angle), to: Quaternion, as: :from_axis_angle

  @doc """
  Create a quaternion from Euler angles (yaw, pitch, roll).

  ## Examples

      iex> AriaMath.API.Quaternion.quaternion_from_euler(0.0, 0.0, :math.pi / 2)
      {0.0, 0.0, 0.7071067811865476, 0.7071067811865475}
  """
  defdelegate quaternion_from_euler(yaw, pitch, roll), to: Quaternion, as: :from_euler

  @doc """
  Multiply two quaternions (compose rotations).

  ## Examples

      q1 = AriaMath.API.Quaternion.quaternion_from_axis_angle({0.0, 0.0, 1.0}, :math.pi / 4)
      q2 = AriaMath.API.Quaternion.quaternion_from_axis_angle({0.0, 0.0, 1.0}, :math.pi / 4)
      result = AriaMath.API.Quaternion.quaternion_multiply(q1, q2)
  """
  defdelegate quaternion_multiply(q1, q2), to: Quaternion, as: :multiply

  @doc """
  Multiply two quaternions (alias for quaternion_multiply/2).

  ## Examples

      q1 = AriaMath.API.Quaternion.quaternion_from_axis_angle({0.0, 0.0, 1.0}, :math.pi / 4)
      q2 = AriaMath.API.Quaternion.quaternion_from_axis_angle({0.0, 0.0, 1.0}, :math.pi / 4)
      result = AriaMath.API.Quaternion.multiply_quaternions(q1, q2)
  """
  defdelegate multiply_quaternions(q1, q2), to: Quaternion, as: :multiply

  @doc """
  Normalize a quaternion to unit length.

  ## Examples

      q = {0.0, 0.0, 1.0, 1.0}
      normalized = AriaMath.API.Quaternion.quaternion_normalize(q)
  """
  def quaternion_normalize(quaternion) do
    {normalized, _valid} = Quaternion.normalize(quaternion)
    normalized
  end

  @doc """
  Normalize a quaternion to unit length (alias for quaternion_normalize/1).

  ## Examples

      q = {0.0, 0.0, 1.0, 1.0}
      normalized = AriaMath.API.Quaternion.normalize_quaternion(q)
  """
  defdelegate normalize_quaternion(quaternion), to: Quaternion, as: :normalize

  @doc """
  Rotate a 3D vector by a quaternion.

  ## Examples

      q = AriaMath.API.Quaternion.quaternion_from_axis_angle({0.0, 0.0, 1.0}, :math.pi / 2)
      rotated = AriaMath.API.Quaternion.quaternion_rotate(q, {1.0, 0.0, 0.0})
  """
  defdelegate quaternion_rotate(quaternion, vector), to: Quaternion, as: :rotate

  @doc """
  Compute the conjugate of a quaternion.

  ## Examples

      q = {1.0, 2.0, 3.0, 4.0}
      conjugate = AriaMath.API.Quaternion.quaternion_conjugate(q)
  """
  defdelegate quaternion_conjugate(quaternion), to: Quaternion, as: :conjugate

  @doc """
  Spherical linear interpolation between two quaternions.

  ## Examples

      q1 = AriaMath.API.Quaternion.quaternion_from_axis_angle({0.0, 0.0, 1.0}, 0.0)
      q2 = AriaMath.API.Quaternion.quaternion_from_axis_angle({0.0, 0.0, 1.0}, :math.pi / 2)
      result = AriaMath.API.Quaternion.quaternion_slerp(q1, q2, 0.5)
  """
  defdelegate quaternion_slerp(q1, q2, t), to: Quaternion, as: :slerp
end
