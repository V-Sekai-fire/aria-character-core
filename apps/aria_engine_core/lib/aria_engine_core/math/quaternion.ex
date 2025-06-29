defmodule AriaEngineCore.Math.Quaternion do
  @moduledoc """
  Quaternion mathematical operations implementing glTF KHR Interactivity `float4` quaternion operations.

  All operations follow IEEE-754 standard for NaN, infinity, and special case handling
  as defined in the glTF KHR Interactivity specification.

  Quaternion is represented as a 4-tuple {x, y, z, w} using XYZW order where w is the scalar component.
  This follows glTF convention.
  """

  import Kernel, except: [length: 1]
  alias __MODULE__
  alias AriaEngineCore.Math.Vector3

  @type t :: {float(), float(), float(), float()}

  @doc """
  Creates a new Quaternion from four float components in XYZW order.

  ## Examples

      iex> AriaEngineCore.Math.Quaternion.new(0.0, 0.0, 0.0, 1.0)
      {0.0, 0.0, 0.0, 1.0}
  """
  @spec new(float(), float(), float(), float()) :: t()
  def new(x, y, z, w) when is_number(x) and is_number(y) and is_number(z) and is_number(w) do
    {x / 1, y / 1, z / 1, w / 1}
  end

  @doc """
  Quaternion conjugation operation.

  Implements `math/quatConjugate` operation from KHR Interactivity spec.

  Returns conjugated quaternion with negated x, y, z components and unchanged w component.
  NaN and infinity values are propagated according to IEEE-754.

  ## Examples

      iex> AriaEngineCore.Math.Quaternion.conjugate({1.0, 2.0, 3.0, 4.0})
      {-1.0, -2.0, -3.0, 4.0}

      iex> AriaEngineCore.Math.Quaternion.conjugate({0.0, 0.0, 0.0, 1.0})
      {-0.0, -0.0, -0.0, 1.0}
  """
  @spec conjugate(t()) :: t()
  def conjugate({x, y, z, w}) do
    {-x, -y, -z, w}
  end

  @doc """
  Quaternion multiplication operation.

  Implements `math/quatMul` operation from KHR Interactivity spec.

  Returns quaternion product following Hamilton product rules.
  NaN and infinity values are propagated according to IEEE-754.

  ## Examples

      iex> AriaEngineCore.Math.Quaternion.multiply({0.0, 0.0, 0.0, 1.0}, {1.0, 0.0, 0.0, 0.0})
      {1.0, 0.0, 0.0, 0.0}
  """
  @spec multiply(t(), t()) :: t()
  def multiply({ax, ay, az, aw}, {bx, by, bz, bw}) do
    {
      aw * bx + ax * bw + ay * bz - az * by,
      aw * by + ay * bw + az * bx - ax * bz,
      aw * bz + az * bw + ax * by - ay * bx,
      aw * bw - ax * bx - ay * by - az * bz
    }
  end

  @doc """
  Angle between two quaternions.

  Implements `math/quatAngleBetween` operation from KHR Interactivity spec.

  CAUTION: This operation assumes that both input quaternions are unit quaternions.

  Returns angle in radians between two quaternions.
  NaN and infinity values are propagated according to IEEE-754.

  ## Examples

      iex> AriaEngineCore.Math.Quaternion.angle_between({0.0, 0.0, 0.0, 1.0}, {0.0, 0.0, 0.0, 1.0})
      0.0
  """
  @spec angle_between(t(), t()) :: float()
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

      iex> AriaEngineCore.Math.Quaternion.from_axis_angle({0.0, 0.0, 1.0}, :math.pi() / 2.0)
      {0.0, 0.0, 0.7071067811865475, 0.7071067811865476}
  """
  @spec from_axis_angle(Vector3.t(), float()) :: t()
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

      iex> AriaEngineCore.Math.Quaternion.to_axis_angle({0.0, 0.0, 0.7071067811865476, 0.7071067811865475})
      {{0.0, 0.0, 1.0}, 1.5707963267948968}
  """
  @spec to_axis_angle(t()) :: {Vector3.t(), float()}
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

      iex> AriaEngineCore.Math.Quaternion.from_directions({1.0, 0.0, 0.0}, {0.0, 1.0, 0.0})
      {0.0, 0.0, 0.7071067811865475, 0.7071067811865476}
  """
  @spec from_directions(Vector3.t(), Vector3.t()) :: t()
  def from_directions({ax, ay, az} = a, {bx, by, bz} = b) do
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
  Quaternion normalization with validity checking.

  Implements `math/normalize` operation from KHR Interactivity spec for quaternions.

  Returns {normalized_quaternion, is_valid} where:
  - normalized_quaternion: unit quaternion in same direction as input, or identity if invalid
  - is_valid: true if output has unit length, false otherwise

  ## Examples

      iex> AriaEngineCore.Math.Quaternion.normalize({0.0, 0.0, 0.0, 2.0})
      {{0.0, 0.0, 0.0, 1.0}, true}

      iex> AriaEngineCore.Math.Quaternion.normalize({0.0, 0.0, 0.0, 0.0})
      {{0.0, 0.0, 0.0, 1.0}, false}
  """
  @spec normalize(t()) :: {t(), boolean()}
  def normalize({x, y, z, w} = quat) do
    len = length(quat)

    cond do
      # If length is zero, NaN, or infinity, return identity and false
      len == 0.0 or is_nan(len) or is_infinite(len) ->
        {{0.0, 0.0, 0.0, 1.0}, false}

      # If length is positive finite number, normalize and return true
      len > 0.0 and is_finite(len) ->
        {{x / len, y / len, z / len, w / len}, true}

      # Default case
      true ->
        {{0.0, 0.0, 0.0, 1.0}, false}
    end
  end

  @doc """
  Quaternion length (magnitude).

  Returns the Euclidean length of the quaternion.
  Uses same IEEE-754 special case handling as Vector3.length.

  ## Examples

      iex> AriaEngineCore.Math.Quaternion.length({0.0, 0.0, 0.0, 1.0})
      1.0

      iex> AriaEngineCore.Math.Quaternion.length({1.0, 1.0, 1.0, 1.0})
      2.0
  """
  @spec length(t()) :: float()
  def length({x, y, z, w}) do
    cond do
      # If any component is positive or negative infinity, return positive infinity
      is_infinite(x) or is_infinite(y) or is_infinite(z) or is_infinite(w) ->
        :math.pow(1.0, 0.0) / 0.0  # positive infinity

      # If no components are infinity and any component is NaN, return NaN
      is_nan(x) or is_nan(y) or is_nan(z) or is_nan(w) ->
        :math.pow(-1.0, 0.5)  # NaN

      # If all components are positive or negative zeros, return positive zero
      x == 0.0 and y == 0.0 and z == 0.0 and w == 0.0 ->
        0.0

      # Normal case
      true ->
        :math.sqrt(x * x + y * y + z * z + w * w)
    end
  end

  @doc """
  Component-wise dot product for quaternions.

  Returns sum of per-component products: a.x * b.x + a.y * b.y + a.z * b.z + a.w * b.w
  NaN and infinity values are propagated according to IEEE-754.

  ## Examples

      iex> AriaEngineCore.Math.Quaternion.dot({1.0, 0.0, 0.0, 0.0}, {0.0, 1.0, 0.0, 0.0})
      0.0

      iex> AriaEngineCore.Math.Quaternion.dot({0.0, 0.0, 0.0, 1.0}, {0.0, 0.0, 0.0, 1.0})
      1.0
  """
  @spec dot(t(), t()) :: float()
  def dot({ax, ay, az, aw}, {bx, by, bz, bw}) do
    ax * bx + ay * by + az * bz + aw * bw
  end

  @doc """
  Spherical linear interpolation between two quaternions.

  Implements spherical linear interpolation (slerp) for smooth quaternion interpolation.
  Uses the shortest path between quaternions.

  ## Examples

      iex> AriaEngineCore.Math.Quaternion.slerp({0.0, 0.0, 0.0, 1.0}, {1.0, 0.0, 0.0, 0.0}, 0.5)
      {0.7071067811865475, 0.0, 0.0, 0.7071067811865476}
  """
  @spec slerp(t(), t(), float()) :: t()
  def slerp({ax, ay, az, aw} = a, {bx, by, bz, bw} = b, t) when is_number(t) do
    # Calculate dot product
    dot_prod = dot(a, b)

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

        {normalized, _} = normalize(result)
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

      iex> AriaEngineCore.Math.Quaternion.rotate_vector({0.0, 0.0, 0.7071067811865475, 0.7071067811865476}, {1.0, 0.0, 0.0})
      {0.0, 1.0, 0.0}
  """
  @spec rotate_vector(t(), Vector3.t()) :: Vector3.t()
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
  Identity quaternion constant.

  ## Examples

      iex> AriaEngineCore.Math.Quaternion.identity()
      {0.0, 0.0, 0.0, 1.0}
  """
  @spec identity() :: t()
  def identity, do: {0.0, 0.0, 0.0, 1.0}

  @doc """
  Check if quaternion is approximately identity.

  ## Examples

      iex> AriaEngineCore.Math.Quaternion.is_identity?({0.0, 0.0, 0.0, 1.0})
      true

      iex> AriaEngineCore.Math.Quaternion.is_identity?({0.1, 0.0, 0.0, 0.995})
      false
  """
  @spec is_identity?(t()) :: boolean()
  def is_identity?({x, y, z, w}) do
    epsilon = 1.0e-6
    abs(x) < epsilon and abs(y) < epsilon and abs(z) < epsilon and abs(w - 1.0) < epsilon
  end

  # Helper functions

  defp is_nan(x) do
    x != x
  end

  defp is_finite(x) do
    not is_nan(x) and not is_infinite(x)
  end

  defp is_infinite(x) do
    x == :positive_infinity or x == :negative_infinity
  end

end
