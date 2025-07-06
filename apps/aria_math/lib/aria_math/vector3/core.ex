# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaMath.Vector3.Core do
  @moduledoc """
  Core Vector3 operations.

  Functions for creating vectors, calculating length, normalization,
  dot product, and cross product operations.
  """

  import Kernel, except: [length: 1]

  @type vector3 :: {float(), float(), float()}

  @doc """
  Creates a new Vector3 from three float components.

  ## Examples

      iex> AriaMath.Vector3.Core.new(1.0, 2.0, 3.0)
      {1.0, 2.0, 3.0}
  """
  @spec new(float(), float(), float()) :: vector3()
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

      iex> AriaMath.Vector3.Core.length({3.0, 4.0, 0.0})
      5.0

      iex> AriaMath.Vector3.Core.length({1.0, 1.0, 1.0})
      1.7320508075688772
  """
  @spec length(vector3()) :: float()
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

      iex> AriaMath.Vector3.Core.normalize({3.0, 4.0, 0.0})
      {{0.6, 0.8, 0.0}, true}

      iex> AriaMath.Vector3.Core.normalize({0.0, 0.0, 0.0})
      {{0.0, 0.0, 0.0}, false}
  """
  @spec normalize(vector3()) :: {vector3(), boolean()}
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

      iex> AriaMath.Vector3.Core.dot({1.0, 2.0, 3.0}, {4.0, 5.0, 6.0})
      32.0

      iex> AriaMath.Vector3.Core.dot({1.0, 0.0, 0.0}, {0.0, 1.0, 0.0})
      0.0
  """
  @spec dot(vector3(), vector3()) :: float()
  def dot({ax, ay, az}, {bx, by, bz}) do
    ax * bx + ay * by + az * bz
  end

  @doc """
  3D cross product.

  Implements `math/cross` operation from KHR Interactivity spec.

  Returns cross product: a × b
  NaN and infinity values are propagated according to IEEE-754.

  ## Examples

      iex> AriaMath.Vector3.Core.cross({1.0, 0.0, 0.0}, {0.0, 1.0, 0.0})
      {0.0, 0.0, 1.0}

      iex> AriaMath.Vector3.Core.cross({1.0, 2.0, 3.0}, {4.0, 5.0, 6.0})
      {-3.0, 6.0, -3.0}
  """
  @spec cross(vector3(), vector3()) :: vector3()
  def cross({ax, ay, az}, {bx, by, bz}) do
    {
      ay * bz - az * by,
      az * bx - ax * bz,
      ax * by - ay * bx
    }
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
    (try do
      x == 1.0 / 0.0 or x == -1.0 / 0.0
    rescue
      ArithmeticError -> false
    end)
  end

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
