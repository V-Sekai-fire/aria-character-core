# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaMath.Quaternion.Core do
  @moduledoc """
  Core quaternion mathematical operations.

  Basic quaternion operations including multiplication, conjugation,
  dot product, length calculation, and normalization.
  """

  import Kernel, except: [length: 1]

  @type quaternion :: {float(), float(), float(), float()}

  @doc """
  Creates a new Quaternion from four float components in XYZW order.

  ## Examples

      iex> AriaMath.Quaternion.Core.new(0.0, 0.0, 0.0, 1.0)
      {0.0, 0.0, 0.0, 1.0}
  """
  @spec new(float(), float(), float(), float()) :: quaternion()
  def new(x, y, z, w) when is_number(x) and is_number(y) and is_number(z) and is_number(w) do
    {x / 1, y / 1, z / 1, w / 1}
  end

  @doc """
  Quaternion conjugation operation.

  Implements `math/quatConjugate` operation from KHR Interactivity spec.

  Returns conjugated quaternion with negated x, y, z components and unchanged w component.
  NaN and infinity values are propagated according to IEEE-754.

  ## Examples

      iex> AriaMath.Quaternion.Core.conjugate({1.0, 2.0, 3.0, 4.0})
      {-1.0, -2.0, -3.0, 4.0}

      iex> AriaMath.Quaternion.Core.conjugate({0.0, 0.0, 0.0, 1.0})
      {-0.0, -0.0, -0.0, 1.0}
  """
  @spec conjugate(quaternion()) :: quaternion()
  def conjugate({x, y, z, w}) do
    {-x, -y, -z, w}
  end

  @doc """
  Quaternion multiplication operation.

  Implements `math/quatMul` operation from KHR Interactivity spec.

  Returns quaternion product following Hamilton product rules.
  NaN and infinity values are propagated according to IEEE-754.

  ## Examples

      iex> AriaMath.Quaternion.Core.multiply({0.0, 0.0, 0.0, 1.0}, {1.0, 0.0, 0.0, 0.0})
      {1.0, 0.0, 0.0, 0.0}
  """
  @spec multiply(quaternion(), quaternion()) :: quaternion()
  def multiply({ax, ay, az, aw}, {bx, by, bz, bw}) do
    {
      aw * bx + ax * bw + ay * bz - az * by,
      aw * by + ay * bw + az * bx - ax * bz,
      aw * bz + az * bw + ax * by - ay * bx,
      aw * bw - ax * bx - ay * by - az * bz
    }
  end

  @doc """
  Component-wise dot product for quaternions.

  Returns sum of per-component products: a.x * b.x + a.y * b.y + a.z * b.z + a.w * b.w
  NaN and infinity values are propagated according to IEEE-754.

  ## Examples

      iex> AriaMath.Quaternion.Core.dot({1.0, 0.0, 0.0, 0.0}, {0.0, 1.0, 0.0, 0.0})
      0.0

      iex> AriaMath.Quaternion.Core.dot({0.0, 0.0, 0.0, 1.0}, {0.0, 0.0, 0.0, 1.0})
      1.0
  """
  @spec dot(quaternion(), quaternion()) :: float()
  def dot({ax, ay, az, aw}, {bx, by, bz, bw}) do
    ax * bx + ay * by + az * bz + aw * bw
  end

  @doc """
  Quaternion length (magnitude).

  Returns the Euclidean length of the quaternion.
  Uses same IEEE-754 special case handling as Vector3.length.

  ## Examples

      iex> AriaMath.Quaternion.Core.length({0.0, 0.0, 0.0, 1.0})
      1.0

      iex> AriaMath.Quaternion.Core.length({1.0, 1.0, 1.0, 1.0})
      2.0
  """
  @spec length(quaternion()) :: float()
  def length({x, y, z, w}) do
    cond do
      # If any component is positive or negative infinity, return positive infinity
      is_infinite(x) or is_infinite(y) or is_infinite(z) or is_infinite(w) ->
        :positive_infinity

      # If no components are infinity and any component is NaN, return NaN
      is_nan(x) or is_nan(y) or is_nan(z) or is_nan(w) ->
        :nan

      # If all components are positive or negative zeros, return positive zero
      x == 0.0 and y == 0.0 and z == 0.0 and w == 0.0 ->
        0.0

      # Normal case
      true ->
        :math.sqrt(x * x + y * y + z * z + w * w)
    end
  end

  @doc """
  Quaternion normalization with validity checking.

  Implements `math/normalize` operation from KHR Interactivity spec for quaternions.

  Returns {normalized_quaternion, is_valid} where:
  - normalized_quaternion: unit quaternion in same direction as input, or identity if invalid
  - is_valid: true if output has unit length, false otherwise

  ## Examples

      iex> AriaMath.Quaternion.Core.normalize({0.0, 0.0, 0.0, 2.0})
      {{0.0, 0.0, 0.0, 1.0}, true}

      iex> AriaMath.Quaternion.Core.normalize({0.0, 0.0, 0.0, 0.0})
      {{0.0, 0.0, 0.0, 1.0}, false}
  """
  @spec normalize(quaternion()) :: {quaternion(), boolean()}
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
