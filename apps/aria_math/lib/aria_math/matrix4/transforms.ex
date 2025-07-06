# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaMath.Matrix4.Transforms do
  @moduledoc """
  Point and vector transformation operations for Matrix4.
  """

  alias AriaMath.{Matrix4, Vector3}

  @doc """
  Transform a Vector3 point by the matrix.
  """
  @spec transform_point(Matrix4.t(), Vector3.t()) :: Vector3.t()
  def transform_point({m0, m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, m12, m13, m14, m15}, {x, y, z}) do
    # Transform with w=1 (point)
    tx = m0 * x + m4 * y + m8 * z + m12
    ty = m1 * x + m5 * y + m9 * z + m13
    tz = m2 * x + m6 * y + m10 * z + m14
    tw = m3 * x + m7 * y + m11 * z + m15

    # Perspective divide if needed
    if tw != 0.0 and tw != 1.0 do
      {tx / tw, ty / tw, tz / tw}
    else
      {tx, ty, tz}
    end
  end

  @doc """
  Transform a Vector3 direction by the matrix.
  """
  @spec transform_direction(Matrix4.t(), Vector3.t()) :: Vector3.t()
  def transform_direction({m0, m1, m2, _, m4, m5, m6, _, m8, m9, m10, _, _, _, _, _}, {x, y, z}) do
    # Transform with w=0 (direction)
    {
      m0 * x + m4 * y + m8 * z,
      m1 * x + m5 * y + m9 * z,
      m2 * x + m6 * y + m10 * z
    }
  end

  @doc """
  Transform a 3D vector by this matrix (alias for transform_direction/2).
  """
  @spec transform_vector(Matrix4.t(), Vector3.t()) :: Vector3.t()
  def transform_vector(matrix, vector) do
    transform_direction(matrix, vector)
  end

  @doc """
  Identity matrix constant.
  """
  @spec identity() :: Matrix4.t()
  def identity do
    {1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0}
  end

  @doc """
  Zero matrix constant.
  """
  @spec zero() :: Matrix4.t()
  def zero do
    {0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0}
  end

  @doc """
  Compare two matrices for equality with floating point tolerance.
  """
  @spec equal?(Matrix4.t(), Matrix4.t()) :: boolean()
  def equal?(
        {a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15},
        {b0, b1, b2, b3, b4, b5, b6, b7, b8, b9, b10, b11, b12, b13, b14, b15}
      ) do
    epsilon = 1.0e-6

    abs(a0 - b0) < epsilon and abs(a1 - b1) < epsilon and
    abs(a2 - b2) < epsilon and abs(a3 - b3) < epsilon and
    abs(a4 - b4) < epsilon and abs(a5 - b5) < epsilon and
    abs(a6 - b6) < epsilon and abs(a7 - b7) < epsilon and
    abs(a8 - b8) < epsilon and abs(a9 - b9) < epsilon and
    abs(a10 - b10) < epsilon and abs(a11 - b11) < epsilon and
    abs(a12 - b12) < epsilon and abs(a13 - b13) < epsilon and
    abs(a14 - b14) < epsilon and abs(a15 - b15) < epsilon
  end
end
