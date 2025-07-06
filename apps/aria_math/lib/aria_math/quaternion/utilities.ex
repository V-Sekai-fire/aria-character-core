# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaMath.Quaternion.Utilities do
  @moduledoc """
  Quaternion utility functions.

  Functions for identity quaternion, comparison operations, and helper functions.
  """

  @type quaternion :: {float(), float(), float(), float()}

  @doc """
  Identity quaternion constant.

  ## Examples

      iex> AriaMath.Quaternion.Utilities.identity()
      {0.0, 0.0, 0.0, 1.0}
  """
  @spec identity() :: quaternion()
  def identity, do: {0.0, 0.0, 0.0, 1.0}

  @doc """
  Check if a quaternion is the identity quaternion (or very close to it).

  ## Examples

      iex> AriaMath.Quaternion.Utilities.is_identity?({0.0, 0.0, 0.0, 1.0})
      true

      iex> AriaMath.Quaternion.Utilities.is_identity?({0.1, 0.0, 0.0, 0.995})
      false

      iex> AriaMath.Quaternion.Utilities.is_identity?({5.0e-8, 5.0e-8, 5.0e-8, 0.99999995})
      true
  """
  @spec is_identity?(quaternion()) :: boolean()
  def is_identity?({x, y, z, w}, tolerance \\ 1.0e-6) do
    abs(x) <= tolerance and abs(y) <= tolerance and abs(z) <= tolerance and abs(w - 1.0) <= tolerance
  end

  @doc """
  Check if two quaternions are approximately equal within a tolerance.

  ## Examples

      iex> AriaMath.Quaternion.Utilities.approx_equal?({0.0, 0.0, 0.0, 1.0}, {0.000001, 0.000001, 0.000001, 1.000001}, 0.001)
      true

      iex> AriaMath.Quaternion.Utilities.approx_equal?({0.0, 0.0, 0.0, 1.0}, {0.1, 0.0, 0.0, 1.0}, 0.001)
      false
  """
  @spec approx_equal?(quaternion(), quaternion(), float()) :: boolean()
  def approx_equal?({x1, y1, z1, w1}, {x2, y2, z2, w2}, tolerance \\ 1.0e-6) do
    abs(x1 - x2) <= tolerance and abs(y1 - y2) <= tolerance and
    abs(z1 - z2) <= tolerance and abs(w1 - w2) <= tolerance
  end

  @doc """
  Check if two quaternions are equal within a tolerance.

  This is an alias for `approx_equal?/3` for consistency with other modules.

  ## Examples

      iex> AriaMath.Quaternion.Utilities.equal?({0.0, 0.0, 0.0, 1.0}, {0.000001, 0.000001, 0.000001, 1.000001}, 0.001)
      true
  """
  @spec equal?(quaternion(), quaternion(), float()) :: boolean()
  def equal?(q1, q2, tolerance \\ 1.0e-6), do: approx_equal?(q1, q2, tolerance)
end
