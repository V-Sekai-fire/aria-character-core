# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaMath.Vector3.Utilities do
  @moduledoc """
  Vector3 utility functions.

  Includes constants, equality checks, distance calculations, and other utility functions.
  """

  @type vector3 :: {float(), float(), float()}

  @doc """
  Check if two vectors are approximately equal within a tolerance.

  ## Examples

      iex> AriaMath.Vector3.Utilities.approx_equal?({1.0, 2.0, 3.0}, {1.000001, 2.000001, 3.000001}, 0.001)
      true

      iex> AriaMath.Vector3.Utilities.approx_equal?({1.0, 2.0, 3.0}, {1.1, 2.0, 3.0}, 0.001)
      false
  """
  @spec approx_equal?(vector3(), vector3(), float()) :: boolean()
  def approx_equal?({x1, y1, z1}, {x2, y2, z2}, tolerance \\ 1.0e-6) do
    abs(x1 - x2) <= tolerance and abs(y1 - y2) <= tolerance and abs(z1 - z2) <= tolerance
  end

  @doc """
  Check if two vectors are equal within a tolerance.

  This is an alias for `approx_equal?/3` for consistency with other modules.

  ## Examples

      iex> AriaMath.Vector3.Utilities.equal?({1.0, 2.0, 3.0}, {1.000001, 2.000001, 3.000001}, 0.001)
      true
  """
  @spec equal?(vector3(), vector3(), float()) :: boolean()
  def equal?(v1, v2, tolerance \\ 1.0e-6), do: approx_equal?(v1, v2, tolerance)

  @doc """
  Calculate distance between two 3D points.

  ## Examples

      iex> AriaMath.Vector3.Utilities.distance({0.0, 0.0, 0.0}, {3.0, 4.0, 0.0})
      5.0

      iex> AriaMath.Vector3.Utilities.distance({1.0, 1.0, 1.0}, {1.0, 1.0, 1.0})
      0.0
  """
  @spec distance(vector3(), vector3()) :: float()
  def distance(point1, point2) do
    alias AriaMath.Vector3.Arithmetic
    alias AriaMath.Vector3.Core

    diff = Arithmetic.sub(point2, point1)
    Core.length(diff)
  end

  @doc """
  Zero vector constant.

  ## Examples

      iex> AriaMath.Vector3.Utilities.zero()
      {0.0, 0.0, 0.0}
  """
  @spec zero() :: vector3()
  def zero, do: {0.0, 0.0, 0.0}

  @doc """
  Unit vector in X direction.

  ## Examples

      iex> AriaMath.Vector3.Utilities.unit_x()
      {1.0, 0.0, 0.0}
  """
  @spec unit_x() :: vector3()
  def unit_x, do: {1.0, 0.0, 0.0}

  @doc """
  Unit vector in Y direction.

  ## Examples

      iex> AriaMath.Vector3.Utilities.unit_y()
      {0.0, 1.0, 0.0}
  """
  @spec unit_y() :: vector3()
  def unit_y, do: {0.0, 1.0, 0.0}

  @doc """
  Unit vector in Z direction.

  ## Examples

      iex> AriaMath.Vector3.Utilities.unit_z()
      {0.0, 0.0, 1.0}
  """
  @spec unit_z() :: vector3()
  def unit_z, do: {0.0, 0.0, 1.0}
end
