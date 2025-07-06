# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaMath.Vector3.Arithmetic do
  @moduledoc """
  Vector3 arithmetic operations.

  Component-wise arithmetic operations including addition, subtraction,
  multiplication, division, scaling, and interpolation.
  """

  @type vector3 :: {float(), float(), float()}

  @doc """
  Component-wise addition.

  Implements `math/add` operation from KHR Interactivity spec.

  ## Examples

      iex> AriaMath.Vector3.Arithmetic.add({1.0, 2.0, 3.0}, {4.0, 5.0, 6.0})
      {5.0, 7.0, 9.0}
  """
  @spec add(vector3(), vector3()) :: vector3()
  def add({ax, ay, az}, {bx, by, bz}) do
    {ax + bx, ay + by, az + bz}
  end

  @doc """
  Component-wise subtraction.

  Implements `math/sub` operation from KHR Interactivity spec.

  ## Examples

      iex> AriaMath.Vector3.Arithmetic.sub({5.0, 7.0, 9.0}, {1.0, 2.0, 3.0})
      {4.0, 5.0, 6.0}
  """
  @spec sub(vector3(), vector3()) :: vector3()
  def sub({ax, ay, az}, {bx, by, bz}) do
    {ax - bx, ay - by, az - bz}
  end

  @doc """
  Component-wise multiplication.

  Implements `math/mul` operation from KHR Interactivity spec.

  ## Examples

      iex> AriaMath.Vector3.Arithmetic.mul({2.0, 3.0, 4.0}, {5.0, 6.0, 7.0})
      {10.0, 18.0, 28.0}
  """
  @spec mul(vector3(), vector3()) :: vector3()
  def mul({ax, ay, az}, {bx, by, bz}) do
    {ax * bx, ay * by, az * bz}
  end

  @doc """
  Scalar multiplication.

  Multiplies vector by scalar value.

  ## Examples

      iex> AriaMath.Vector3.Arithmetic.scale({1.0, 2.0, 3.0}, 2.0)
      {2.0, 4.0, 6.0}
  """
  @spec scale(vector3(), float()) :: vector3()
  def scale({x, y, z}, scalar) when is_number(scalar) do
    {x * scalar, y * scalar, z * scalar}
  end

  @doc """
  Scalar multiplication (alias for scale/2).

  Multiplies vector by scalar value.

  ## Examples

      iex> AriaMath.Vector3.Arithmetic.mul_scalar({1.0, 2.0, 3.0}, 2.0)
      {2.0, 4.0, 6.0}
  """
  @spec mul_scalar(vector3(), float()) :: vector3()
  def mul_scalar(vector, scalar) do
    scale(vector, scalar)
  end

  @doc """
  Linear interpolation between two vectors.

  Implements `math/mix` operation from KHR Interactivity spec.

  Returns (1 - t) * a + t * b for each component.

  ## Examples

      iex> AriaMath.Vector3.Arithmetic.mix({0.0, 0.0, 0.0}, {1.0, 1.0, 1.0}, 0.5)
      {0.5, 0.5, 0.5}
  """
  @spec mix(vector3(), vector3(), float()) :: vector3()
  def mix({ax, ay, az}, {bx, by, bz}, t) when is_number(t) do
    {
      (1.0 - t) * ax + t * bx,
      (1.0 - t) * ay + t * by,
      (1.0 - t) * az + t * bz
    }
  end

  @doc """
  Linear interpolation between two vectors.

  This is an alias for `mix/3` to provide compatibility with common naming conventions.

  ## Examples

      iex> AriaMath.Vector3.Arithmetic.lerp({0.0, 0.0, 0.0}, {1.0, 1.0, 1.0}, 0.5)
      {0.5, 0.5, 0.5}

      iex> AriaMath.Vector3.Arithmetic.lerp({1.0, 2.0, 3.0}, {4.0, 5.0, 6.0}, 0.25)
      {1.75, 2.75, 3.75}
  """
  @spec lerp(vector3(), vector3(), float()) :: vector3()
  def lerp(v1, v2, t) do
    mix(v1, v2, t)
  end

  @doc """
  Component-wise minimum.

  Implements `math/min` operation from KHR Interactivity spec.
  For the purposes of this operation, negative zero is less than positive zero.

  ## Examples

      iex> AriaMath.Vector3.Arithmetic.min({1.0, 5.0, 3.0}, {4.0, 2.0, 6.0})
      {1.0, 2.0, 3.0}
  """
  @spec min(vector3(), vector3()) :: vector3()
  def min({ax, ay, az}, {bx, by, bz}) do
    {math_min(ax, bx), math_min(ay, by), math_min(az, bz)}
  end

  @doc """
  Component-wise maximum.

  Implements `math/max` operation from KHR Interactivity spec.
  For the purposes of this operation, negative zero is less than positive zero.

  ## Examples

      iex> AriaMath.Vector3.Arithmetic.max({1.0, 5.0, 3.0}, {4.0, 2.0, 6.0})
      {4.0, 5.0, 6.0}
  """
  @spec max(vector3(), vector3()) :: vector3()
  def max({ax, ay, az}, {bx, by, bz}) do
    {math_max(ax, bx), math_max(ay, by), math_max(az, bz)}
  end

  @doc """
  Component-wise absolute value.

  Implements `math/abs` operation from KHR Interactivity spec.

  ## Examples

      iex> AriaMath.Vector3.Arithmetic.component_abs({-1.0, 2.0, -3.0})
      {1.0, 2.0, 3.0}
  """
  @spec component_abs(vector3()) :: vector3()
  def component_abs({x, y, z}) do
    {math_abs(x), math_abs(y), math_abs(z)}
  end

  # Helper functions

  defp math_min(a, b) when a <= b, do: a
  defp math_min(_a, b), do: b

  defp math_max(a, b) when a >= b, do: a
  defp math_max(_a, b), do: b

  defp math_abs(x) when x >= 0, do: x
  defp math_abs(x), do: -x
end
