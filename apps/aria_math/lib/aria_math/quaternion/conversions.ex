# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaMath.Quaternion.Conversions do
  @moduledoc """
  Quaternion conversion operations.

  Functions for converting between quaternions and other representations
  like axis-angle, directions, and Euler angles.
  """

  alias AriaMath.Vector3

  @type quaternion :: {float(), float(), float(), float()}

  @doc """
  Angle between two quaternions.

  Implements `math/quatAngleBetween` operation from KHR Interactivity spec.

  CAUTION: This operation assumes that both input quaternions are unit quaternions.

  Returns angle in radians between two quaternions.
  NaN and infinity values are propagated according to IEEE-754.

  ## Examples

      iex> AriaMath.Quaternion.Conversions.angle_between({0.0, 0.0, 0.0, 1.0}, {0.0, 0.0, 0.0, 1.0})
      0.0
  """
  @spec angle_between(quaternion(), quaternion()) :: float()
  def angle_between({ax, ay, az, aw}, {bx, by, bz, bw}) do
    dot_product = ax * bx + ay * by + az * bz + aw * bw
    2.0 * :math.acos(abs(dot_product))
  end

  @doc """
  Create quaternion from axis and angle.

  Implements `math/quatFromAxisAngle` operation from KHR Interactivity spec.

  CAUTION: This operation assumes that the rotation axis vector is unit.

  Returns rotation quaternion from unit axis vector and angle in radians.
  NaN and infinity values are propagated according to IEEE-754.

  ## Examples

      iex> AriaMath.Quaternion.Conversions.from_axis_angle({0.0, 0.0, 1.0}, :math.pi() / 2.0)
      {0.0, 0.0, 0.7071067811865475, 0.7071067811865476}
  """
  @spec from_axis_angle(Vector3.t(), float()) :: quaternion()
  def from_axis_angle({axis_x, axis_y, axis_z}, angle) when is_number(angle) do
    half_angle = 0.5 * angle
    sin_half = :math.sin(half_angle)
    cos_half = :math.cos(half_angle)

    {
      axis_x * sin_half,
      axis_y * sin_half,
      axis_z * sin_half,
      cos_half
    }
  end

  @doc """
  Decompose quaternion to axis and angle.

  Implements `math/quatToAxisAngle` operation from KHR Interactivity spec.

  CAUTION: This operation assumes that the rotation quaternion is unit.

  Returns {axis, angle} where axis is unit vector and angle is in radians.
  If quaternion is close to identity, returns arbitrary axis-aligned unit vector.

  ## Examples

      iex> AriaMath.Quaternion.Conversions.to_axis_angle({0.0, 0.0, 0.7071067811865476, 0.7071067811865475})
      {{0.0, 0.0, 1.0}, 1.5707963267948968}
  """
  @spec to_axis_angle(quaternion()) :: {Vector3.t(), float()}
  def to_axis_angle({x, y, z, w}) do
    # Implementation-defined threshold for close to identity
    threshold = 0.9999

    cond do
      # If |w| is close to 1, quaternion is close to identity
      abs(w) >= threshold ->
        # Return arbitrary axis-aligned unit vector and zero angle
        {{1.0, 0.0, 0.0}, 0.0}

      # Normal case
      true ->
        angle = 2.0 * :math.acos(abs(w))
        denominator = :math.sqrt(1.0 - w * w)

        axis = {
          x / denominator,
          y / denominator,
          z / denominator
        }

        {axis, angle}
    end
  end

  @doc """
  Create quaternion from two directional vectors.

  Implements `math/quatFromDirections` operation from KHR Interactivity spec.

  CAUTION: This operation assumes that both directions are unit vectors.

  Returns rotation quaternion that rotates from first direction to second direction.
  NaN and infinity values are propagated according to IEEE-754.

  ## Examples

      iex> AriaMath.Quaternion.Conversions.from_directions({1.0, 0.0, 0.0}, {0.0, 1.0, 0.0})
      {0.0, 0.0, 0.7071067811865475, 0.7071067811865476}
  """
  @spec from_directions(Vector3.t(), Vector3.t()) :: quaternion()
  def from_directions(a, b) do
    # Implementation-defined threshold for parallel vectors
    threshold = 0.9999

    dot_product = Vector3.dot(a, b)

    cond do
      # Vectors are nearly parallel in same direction
      dot_product >= threshold ->
        # Return identity quaternion
        {0.0, 0.0, 0.0, 1.0}

      # Vectors are nearly parallel in opposite directions
      dot_product <= -threshold ->
        # Find perpendicular axis
        {ax, ay, _az} = a
        axis =
          cond do
            abs(ax) < 0.9 -> {1.0, 0.0, 0.0}
            abs(ay) < 0.9 -> {0.0, 1.0, 0.0}
            true -> {0.0, 0.0, 1.0}
          end

        # Create perpendicular vector
        perp = Vector3.cross(a, axis)
        {normalized_perp, _} = Vector3.normalize(perp)
        {px, py, pz} = normalized_perp

        # Return 180-degree rotation around perpendicular axis
        {px, py, pz, 0.0}

      # Normal case
      true ->
        cross_product = Vector3.cross(a, b)
        {rx, ry, rz} = cross_product

        w = :math.sqrt(0.5 + 0.5 * dot_product)
        inv_denominator = 1.0 / (2.0 * w)

        {
          rx * inv_denominator,
          ry * inv_denominator,
          rz * inv_denominator,
          w
        }
    end
  end

  @doc """
  Create quaternion from Euler angles (yaw, pitch, roll).

  Creates a quaternion from Euler angles in radians.
  Order of rotation: yaw (Y), pitch (X), roll (Z).

  TODO: Use the from_euler in matrix4 instead of this one because it's missing euler orders.

  ## Examples

      iex> AriaMath.Quaternion.Conversions.from_euler(0.0, 0.0, :math.pi / 2)
      {0.0, 0.0, 0.7071067811865475, 0.7071067811865476}
  """
  @spec from_euler(float(), float(), float()) :: quaternion()
  def from_euler(yaw, pitch, roll) when is_number(yaw) and is_number(pitch) and is_number(roll) do
    # Convert to half angles
    half_yaw = yaw * 0.5
    half_pitch = pitch * 0.5
    half_roll = roll * 0.5

    # Calculate trigonometric values
    cy = :math.cos(half_yaw)
    sy = :math.sin(half_yaw)
    cp = :math.cos(half_pitch)
    sp = :math.sin(half_pitch)
    cr = :math.cos(half_roll)
    sr = :math.sin(half_roll)

    # Calculate quaternion components
    {
      cy * sp * cr + sy * cp * sr,  # x
      sy * cp * cr - cy * sp * sr,  # y
      cy * cp * sr - sy * sp * cr,  # z
      cy * cp * cr + sy * sp * sr   # w
    }
  end
end
