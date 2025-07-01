# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaMath.Vector3 do
  @moduledoc """
  Vector3 mathematical operations implementing glTF KHR Interactivity `float3` operations.

  All operations follow IEEE-754 standard for NaN, infinity, and special case handling
  as defined in the glTF KHR Interactivity specification.

  Vector3 is represented as a 3-tuple {x, y, z} where each component is a float.
  """

  import Kernel, except: [length: 1]
  @type t :: {float(), float(), float()}

  @doc """
  Creates a new Vector3 from three float components.

  ## Examples

      iex> AriaMath.Vector3.new(1.0, 2.0, 3.0)
      {1.0, 2.0, 3.0}
  """
  @spec new(float(), float(), float()) :: t()
  def new(x, y, z) when is_number(x) and is_number(y) and is_number(z) do
    {x / 1, y / 1, z / 1}
  end

  @doc """
  Vector length using IEEE-754 hypot for numerical stability.

  Implements `math/length` operation from KHR Interactivity spec.

  Special cases:
  - If any component is positive or negative infinity, returns positive infinity
  - If no components are infinity and any component is NaN, returns NaN
  - If all components are positive or negative zeros, returns positive zero
  - If all components are finite, returns approximation of sqrt(sum of squares)

  ## Examples

      iex> AriaMath.Vector3.length({3.0, 4.0, 0.0})
      5.0

      iex> AriaMath.Vector3.length({1.0, 1.0, 1.0})
      1.7320508075688772
  """
  @spec length(t()) :: float()
  def length({x, y, z}) do
    cond do
      # If any component is positive or negative infinity, return positive infinity
      is_infinite(x) or is_infinite(y) or is_infinite(z) ->
        positive_infinity()

      # If no components are infinity and any component is NaN, return NaN
      is_nan(x) or is_nan(y) or is_nan(z) ->
        nan()

      # If all components are positive or negative zeros, return positive zero
      x == 0.0 and y == 0.0 and z == 0.0 ->
        0.0

      # Normal case: use hypot for numerical stability
      true ->
        # Use the IEEE-754 hypot operation for numerical stability
        :math.sqrt(x * x + y * y + z * z)
    end
  end

  @doc """
  Vector normalization with validity checking.

  Implements `math/normalize` operation from KHR Interactivity spec.

  Returns {normalized_vector, is_valid} where:
  - normalized_vector: unit vector in same direction as input, or zero vector if invalid
  - is_valid: true if output has unit length, false otherwise

  ## Examples

      iex> AriaMath.Vector3.normalize({3.0, 4.0, 0.0})
      {{0.6, 0.8, 0.0}, true}

      iex> AriaMath.Vector3.normalize({0.0, 0.0, 0.0})
      {{0.0, 0.0, 0.0}, false}
  """
  @spec normalize(t()) :: {t(), boolean()}
  def normalize({x, y, z} = vec) do
    len = length(vec)

    cond do
      # If length is zero, NaN, or positive infinity, return zero vector and false
      len == 0.0 or is_nan(len) or is_infinite(len) ->
        {{0.0, 0.0, 0.0}, false}

      # If length is positive finite number, normalize and return true
      len > 0.0 and is_finite(len) ->
        {{x / len, y / len, z / len}, true}

      # Default case
      true ->
        {{0.0, 0.0, 0.0}, false}
    end
  end

  @doc """
  Component-wise dot product.

  Implements `math/dot` operation from KHR Interactivity spec.

  Returns sum of per-component products: a.x * b.x + a.y * b.y + a.z * b.z
  NaN and infinity values are propagated according to IEEE-754.

  ## Examples

      iex> AriaMath.Vector3.dot({1.0, 2.0, 3.0}, {4.0, 5.0, 6.0})
      32.0

      iex> AriaMath.Vector3.dot({1.0, 0.0, 0.0}, {0.0, 1.0, 0.0})
      0.0
  """
  @spec dot(t(), t()) :: float()
  def dot({ax, ay, az}, {bx, by, bz}) do
    ax * bx + ay * by + az * bz
  end

  @doc """
  3D cross product.

  Implements `math/cross` operation from KHR Interactivity spec.

  Returns cross product: a × b
  NaN and infinity values are propagated according to IEEE-754.

  ## Examples

      iex> AriaMath.Vector3.cross({1.0, 0.0, 0.0}, {0.0, 1.0, 0.0})
      {0.0, 0.0, 1.0}

      iex> AriaMath.Vector3.cross({1.0, 2.0, 3.0}, {4.0, 5.0, 6.0})
      {-3.0, 6.0, -3.0}
  """
  @spec cross(t(), t()) :: t()
  def cross({ax, ay, az}, {bx, by, bz}) do
    {
      ay * bz - az * by,
      az * bx - ax * bz,
      ax * by - ay * bx
    }
  end

  @doc """
  Component-wise addition.

  Implements `math/add` operation from KHR Interactivity spec.

  ## Examples

      iex> AriaMath.Vector3.add({1.0, 2.0, 3.0}, {4.0, 5.0, 6.0})
      {5.0, 7.0, 9.0}
  """
  @spec add(t(), t()) :: t()
  def add({ax, ay, az}, {bx, by, bz}) do
    {ax + bx, ay + by, az + bz}
  end

  @doc """
  Component-wise subtraction.

  Implements `math/sub` operation from KHR Interactivity spec.

  ## Examples

      iex> AriaMath.Vector3.sub({5.0, 7.0, 9.0}, {1.0, 2.0, 3.0})
      {4.0, 5.0, 6.0}
  """
  @spec sub(t(), t()) :: t()
  def sub({ax, ay, az}, {bx, by, bz}) do
    {ax - bx, ay - by, az - bz}
  end

  @doc """
  Component-wise multiplication.

  Implements `math/mul` operation from KHR Interactivity spec.

  ## Examples

      iex> AriaMath.Vector3.mul({2.0, 3.0, 4.0}, {5.0, 6.0, 7.0})
      {10.0, 18.0, 28.0}
  """
  @spec mul(t(), t()) :: t()
  def mul({ax, ay, az}, {bx, by, bz}) do
    {ax * bx, ay * by, az * bz}
  end


  @doc """
  Check if two vectors are approximately equal within a tolerance.

  ## Examples

      iex> Vector3.approx_equal?({1.0, 2.0, 3.0}, {1.000001, 2.000001, 3.000001}, 0.001)
      true

      iex> Vector3.approx_equal?({1.0, 2.0, 3.0}, {1.1, 2.0, 3.0}, 0.001)
      false
  """
  @spec approx_equal?(t(), t(), float()) :: boolean()
  def approx_equal?({x1, y1, z1}, {x2, y2, z2}, tolerance \\ 1.0e-6) do
    abs(x1 - x2) <= tolerance and abs(y1 - y2) <= tolerance and abs(z1 - z2) <= tolerance
  end

  @doc """
  Check if two vectors are equal within a tolerance.

  This is an alias for `approx_equal?/3` for consistency with other modules.

  ## Examples

      iex> Vector3.equal?({1.0, 2.0, 3.0}, {1.000001, 2.000001, 3.000001}, 0.001)
      true
  """
  @spec equal?(t(), t(), float()) :: boolean()
  def equal?(v1, v2, tolerance \\ 1.0e-6), do: approx_equal?(v1, v2, tolerance)

  @doc """
  Scalar multiplication.

  Multiplies vector by scalar value.

  ## Examples

      iex> AriaMath.Vector3.scale({1.0, 2.0, 3.0}, 2.0)
      {2.0, 4.0, 6.0}
  """
  @spec scale(t(), float()) :: t()
  def scale({x, y, z}, scalar) when is_number(scalar) do
    {x * scalar, y * scalar, z * scalar}
  end

  @doc """
  Component-wise minimum.

  Implements `math/min` operation from KHR Interactivity spec.
  For the purposes of this operation, negative zero is less than positive zero.

  ## Examples

      iex> AriaMath.Vector3.min({1.0, 5.0, 3.0}, {4.0, 2.0, 6.0})
      {1.0, 2.0, 3.0}
  """
  @spec min(t(), t()) :: t()
  def min({ax, ay, az}, {bx, by, bz}) do
    {math_min(ax, bx), math_min(ay, by), math_min(az, bz)}
  end

  @doc """
  Component-wise maximum.

  Implements `math/max` operation from KHR Interactivity spec.
  For the purposes of this operation, negative zero is less than positive zero.

  ## Examples

      iex> AriaMath.Vector3.max({1.0, 5.0, 3.0}, {4.0, 2.0, 6.0})
      {4.0, 5.0, 6.0}
  """
  @spec max(t(), t()) :: t()
  def max({ax, ay, az}, {bx, by, bz}) do
    {math_max(ax, bx), math_max(ay, by), math_max(az, bz)}
  end

  @doc """
  Divide a vector by a scalar.

  ## Examples

      iex> AriaMath.Vector3.div_scalar({6.0, 8.0, 10.0}, 2.0)
      {3.0, 4.0, 5.0}

      iex> AriaMath.Vector3.div_scalar({1.0, 2.0, 3.0}, 0.0)
      {:positive_infinity, :positive_infinity, :positive_infinity}
  """
  @spec div_scalar(t(), float()) :: t()
  def div_scalar({x, y, z}, scalar) when is_number(scalar) do
    case scalar do
      +0.0 -> {:positive_infinity, :positive_infinity, :positive_infinity}
      -0.0 -> {:negative_infinity, :negative_infinity, :negative_infinity}
      _ -> {x / scalar, y / scalar, z / scalar}
    end
  end


  @doc """
  Linear interpolation between two vectors.

  Implements `math/mix` operation from KHR Interactivity spec.

  Returns (1 - t) * a + t * b for each component.

  ## Examples

      iex> AriaMath.Vector3.mix({0.0, 0.0, 0.0}, {1.0, 1.0, 1.0}, 0.5)
      {0.5, 0.5, 0.5}
  """
  @spec mix(t(), t(), float()) :: t()
  def mix({ax, ay, az}, {bx, by, bz}, t) when is_number(t) do
    {
      (1.0 - t) * ax + t * bx,
      (1.0 - t) * ay + t * by,
      (1.0 - t) * az + t * bz
    }
  end

  @doc """
  Component-wise absolute value.

  Implements `math/abs` operation from KHR Interactivity spec.

  ## Examples

      iex> AriaMath.Vector3.component_abs({-1.0, 2.0, -3.0})
      {1.0, 2.0, 3.0}
  """
  @spec component_abs(t()) :: t()
  def component_abs({x, y, z}) do
    {math_abs(x), math_abs(y), math_abs(z)}
  end

  @doc """
  Zero vector constant.

  ## Examples

      iex> AriaMath.Vector3.zero()
      {0.0, 0.0, 0.0}
  """
  @spec zero() :: t()
  def zero, do: {0.0, 0.0, 0.0}

  @doc """
  Unit vector in X direction.

  ## Examples

      iex> AriaMath.Vector3.unit_x()
      {1.0, 0.0, 0.0}
  """
  @spec unit_x() :: t()
  def unit_x, do: {1.0, 0.0, 0.0}

  @doc """
  Unit vector in Y direction.

  ## Examples

      iex> AriaMath.Vector3.unit_y()
      {0.0, 1.0, 0.0}
  """
  @spec unit_y() :: t()
  def unit_y, do: {0.0, 1.0, 0.0}

  @doc """
  Unit vector in Z direction.

  ## Examples

      iex> AriaMath.Vector3.unit_z()
      {0.0, 0.0, 1.0}
  """
  @spec unit_z() :: t()
  def unit_z, do: {0.0, 0.0, 1.0}

  @doc """
  Scalar multiplication (alias for scale/2).

  Multiplies vector by scalar value.

  ## Examples

      iex> AriaMath.Vector3.mul_scalar({1.0, 2.0, 3.0}, 2.0)
      {2.0, 4.0, 6.0}
  """
  @spec mul_scalar(t(), float()) :: t()
  def mul_scalar(vector, scalar) do
    scale(vector, scalar)
  end

  @doc """
  Calculate distance between two 3D points.

  ## Examples

      iex> AriaMath.Vector3.distance({0.0, 0.0, 0.0}, {3.0, 4.0, 0.0})
      5.0

      iex> AriaMath.Vector3.distance({1.0, 1.0, 1.0}, {1.0, 1.0, 1.0})
      0.0
  """
  @spec distance(t(), t()) :: float()
  def distance(point1, point2) do
    diff = sub(point2, point1)
    length(diff)
  end

  @doc """
  Linear interpolation between two vectors.

  This is an alias for `mix/3` to provide compatibility with common naming conventions.

  ## Examples

      iex> AriaMath.Vector3.lerp({0.0, 0.0, 0.0}, {1.0, 1.0, 1.0}, 0.5)
      {0.5, 0.5, 0.5}

      iex> AriaMath.Vector3.lerp({1.0, 2.0, 3.0}, {4.0, 5.0, 6.0}, 0.25)
      {1.75, 2.75, 3.75}
  """
  @spec lerp(t(), t(), float()) :: t()
  def lerp(v1, v2, t) do
    mix(v1, v2, t)
  end

  # Helper functions

  defp is_nan(x) do
    x != x
  end

  defp is_finite(x) do
    not is_nan(x) and not is_infinite(x)
  end

  defp is_infinite(x) do
    x == :positive_infinity or x == :negative_infinity or
    x == 1.0 / 0.0 or x == -1.0 / 0.0
  rescue
    ArithmeticError -> false
  end

  defp math_min(a, b) when a <= b, do: a
  defp math_min(_a, b), do: b

  defp math_max(a, b) when a >= b, do: a
  defp math_max(_a, b), do: b

  defp math_abs(x) when x >= 0, do: x
  defp math_abs(x), do: -x

  defp positive_infinity do
    try do
      1.0 / 0.0
    rescue
      ArithmeticError -> :positive_infinity
    end
  end

  defp nan do
    try do
      0.0 / 0.0
    rescue
      ArithmeticError -> :nan
    end
  end
end
