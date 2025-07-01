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

  # Core operations
  defdelegate new(x, y, z), to: AriaMath.Vector3.Core
  defdelegate length(vec), to: AriaMath.Vector3.Core
  defdelegate normalize(vec), to: AriaMath.Vector3.Core
  defdelegate dot(vec1, vec2), to: AriaMath.Vector3.Core
  defdelegate cross(vec1, vec2), to: AriaMath.Vector3.Core

  # Arithmetic operations
  defdelegate add(vec1, vec2), to: AriaMath.Vector3.Arithmetic
  defdelegate sub(vec1, vec2), to: AriaMath.Vector3.Arithmetic
  defdelegate mul(vec1, vec2), to: AriaMath.Vector3.Arithmetic
  defdelegate scale(vec, scalar), to: AriaMath.Vector3.Arithmetic
  defdelegate mul_scalar(vec, scalar), to: AriaMath.Vector3.Arithmetic
  defdelegate mix(vec1, vec2, t), to: AriaMath.Vector3.Arithmetic
  defdelegate lerp(vec1, vec2, t), to: AriaMath.Vector3.Arithmetic
  defdelegate min(vec1, vec2), to: AriaMath.Vector3.Arithmetic
  defdelegate max(vec1, vec2), to: AriaMath.Vector3.Arithmetic
  defdelegate component_abs(vec), to: AriaMath.Vector3.Arithmetic

  # Utility functions
  defdelegate approx_equal?(vec1, vec2, tolerance \\ 1.0e-6), to: AriaMath.Vector3.Utilities
  defdelegate equal?(vec1, vec2, tolerance \\ 1.0e-6), to: AriaMath.Vector3.Utilities
  defdelegate distance(point1, point2), to: AriaMath.Vector3.Utilities
  defdelegate zero(), to: AriaMath.Vector3.Utilities
  defdelegate unit_x(), to: AriaMath.Vector3.Utilities
  defdelegate unit_y(), to: AriaMath.Vector3.Utilities
  defdelegate unit_z(), to: AriaMath.Vector3.Utilities

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
end
