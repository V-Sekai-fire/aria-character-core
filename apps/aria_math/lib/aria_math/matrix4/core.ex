# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaMath.Matrix4.Core do
  @moduledoc """
  Core matrix operations for Matrix4.

  Contains fundamental matrix operations like multiplication, determinant,
  inverse, and transpose operations.
  """

  alias AriaMath.Matrix4

  @doc """
  Matrix multiplication.

  Implements `math/matMul` operation from KHR Interactivity spec.

  Returns matrix product C = A * B following standard matrix multiplication rules.
  NaN and infinity values are propagated according to IEEE-754.
  """
  @spec multiply(Matrix4.t(), Matrix4.t()) :: Matrix4.t()
  def multiply(
        {a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14, a15},
        {b0, b1, b2, b3, b4, b5, b6, b7, b8, b9, b10, b11, b12, b13, b14, b15}
      ) do
    {
      # Column 0
      a0 * b0 + a4 * b1 + a8 * b2 + a12 * b3,
      a1 * b0 + a5 * b1 + a9 * b2 + a13 * b3,
      a2 * b0 + a6 * b1 + a10 * b2 + a14 * b3,
      a3 * b0 + a7 * b1 + a11 * b2 + a15 * b3,
      # Column 1
      a0 * b4 + a4 * b5 + a8 * b6 + a12 * b7,
      a1 * b4 + a5 * b5 + a9 * b6 + a13 * b7,
      a2 * b4 + a6 * b5 + a10 * b6 + a14 * b7,
      a3 * b4 + a7 * b5 + a11 * b6 + a15 * b7,
      # Column 2
      a0 * b8 + a4 * b9 + a8 * b10 + a12 * b11,
      a1 * b8 + a5 * b9 + a9 * b10 + a13 * b11,
      a2 * b8 + a6 * b9 + a10 * b10 + a14 * b11,
      a3 * b8 + a7 * b9 + a11 * b10 + a15 * b11,
      # Column 3
      a0 * b12 + a4 * b13 + a8 * b14 + a12 * b15,
      a1 * b12 + a5 * b13 + a9 * b14 + a13 * b15,
      a2 * b12 + a6 * b13 + a10 * b14 + a14 * b15,
      a3 * b12 + a7 * b13 + a11 * b14 + a15 * b15
    }
  end

  @doc """
  Matrix determinant calculation.

  Implements `math/matDeterminant` operation from KHR Interactivity spec.

  Returns the determinant of the 4x4 matrix.
  NaN and infinity values are propagated according to IEEE-754.
  """
  @spec determinant(Matrix4.t()) :: float()
  def determinant({m0, m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, m12, m13, m14, m15}) do
    # Using cofactor expansion along first row
    minor_0 = (m5 * (m10 * m15 - m11 * m14) - m6 * (m9 * m15 - m11 * m13) + m7 * (m9 * m14 - m10 * m13))
    minor_1 = (m4 * (m10 * m15 - m11 * m14) - m6 * (m8 * m15 - m11 * m12) + m7 * (m8 * m14 - m10 * m12))
    minor_2 = (m4 * (m9 * m15 - m11 * m13) - m5 * (m8 * m15 - m11 * m12) + m7 * (m8 * m13 - m9 * m12))
    minor_3 = (m4 * (m9 * m14 - m10 * m13) - m5 * (m8 * m14 - m10 * m12) + m6 * (m8 * m13 - m9 * m12))

    m0 * minor_0 - m1 * minor_1 + m2 * minor_2 - m3 * minor_3
  end

  @doc """
  Matrix inversion with validity checking.

  Implements `math/matInverse` operation from KHR Interactivity spec.

  Returns {inverted_matrix, is_valid} where:
  - inverted_matrix: inverse matrix, or identity if invalid
  - is_valid: true if matrix is invertible, false otherwise
  """
  @spec inverse(Matrix4.t()) :: {Matrix4.t(), boolean()}
  def inverse(matrix) do
    det = determinant(matrix)

    cond do
      # If determinant is zero, NaN, or infinity, return identity and false
      det == 0.0 or is_nan_float(det) or is_infinite_float(det) ->
        {Matrix4.identity(), false}

      # If determinant is valid, calculate inverse
      true ->
        inv_matrix = calculate_inverse(matrix, det)
        {inv_matrix, true}
    end
  end

  @doc """
  Matrix transpose operation.

  Implements `math/matTranspose` operation from KHR Interactivity spec.

  Returns the transpose of the matrix.
  NaN and infinity values are propagated according to IEEE-754.
  """
  @spec transpose(Matrix4.t()) :: Matrix4.t()
  def transpose({m0, m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, m12, m13, m14, m15}) do
    {m0/1, m4/1, m8/1, m12/1, m1/1, m5/1, m9/1, m13/1, m2/1, m6/1, m10/1, m14/1, m3/1, m7/1, m11/1, m15/1}
  end

  # Helper functions for IEEE-754 compliance
  defp is_nan_float(value) when is_float(value) do
    value != value
  end

  defp is_infinite_float(value) when is_float(value) do
    value == :positive_infinity or value == :negative_infinity
  end

  # Clean up floating-point precision errors
  defp clean_float(value) when is_float(value) do
    epsilon = 1.0e-15
    cond do
      abs(value) < epsilon -> 0.0
      abs(value - 1.0) < epsilon -> 1.0
      abs(value + 1.0) < epsilon -> -1.0
      value == -0.0 -> 0.0  # Convert -0.0 to 0.0
      true -> value
    end
  end

  defp calculate_inverse({m0, m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, m12, m13, m14, m15}, det) do
    inv_det = 1.0 / det

    # Calculate cofactor matrix and multiply by 1/det
    {
      clean_float(inv_det * (m5 * (m10 * m15 - m11 * m14) - m6 * (m9 * m15 - m11 * m13) + m7 * (m9 * m14 - m10 * m13))),
      clean_float(inv_det * -(m1 * (m10 * m15 - m11 * m14) - m2 * (m9 * m15 - m11 * m13) + m3 * (m9 * m14 - m10 * m13))),
      clean_float(inv_det * (m1 * (m6 * m15 - m7 * m14) - m2 * (m5 * m15 - m7 * m13) + m3 * (m5 * m14 - m6 * m13))),
      clean_float(inv_det * -(m1 * (m6 * m11 - m7 * m10) - m2 * (m5 * m11 - m7 * m9) + m3 * (m5 * m10 - m6 * m9))),

      clean_float(inv_det * -(m4 * (m10 * m15 - m11 * m14) - m6 * (m8 * m15 - m11 * m12) + m7 * (m8 * m14 - m10 * m12))),
      clean_float(inv_det * (m0 * (m10 * m15 - m11 * m14) - m2 * (m8 * m15 - m11 * m12) + m3 * (m8 * m14 - m10 * m12))),
      clean_float(inv_det * -(m0 * (m6 * m15 - m7 * m14) - m2 * (m4 * m15 - m7 * m12) + m3 * (m4 * m14 - m6 * m12))),
      clean_float(inv_det * (m0 * (m6 * m11 - m7 * m10) - m2 * (m4 * m11 - m7 * m8) + m3 * (m4 * m10 - m6 * m8))),

      clean_float(inv_det * (m4 * (m9 * m15 - m11 * m13) - m5 * (m8 * m15 - m11 * m12) + m7 * (m8 * m13 - m9 * m12))),
      clean_float(inv_det * -(m0 * (m9 * m15 - m11 * m13) - m1 * (m8 * m15 - m11 * m12) + m3 * (m8 * m13 - m9 * m12))),
      clean_float(inv_det * (m0 * (m5 * m15 - m7 * m13) - m1 * (m4 * m15 - m7 * m12) + m3 * (m4 * m13 - m5 * m12))),
      clean_float(inv_det * -(m0 * (m5 * m11 - m7 * m9) - m1 * (m4 * m11 - m7 * m8) + m3 * (m4 * m9 - m5 * m8))),

      clean_float(inv_det * -(m4 * (m9 * m14 - m10 * m13) - m5 * (m8 * m14 - m10 * m12) + m6 * (m8 * m13 - m9 * m12))),
      clean_float(inv_det * (m0 * (m9 * m14 - m10 * m13) - m1 * (m8 * m14 - m10 * m12) + m2 * (m8 * m13 - m9 * m12))),
      clean_float(inv_det * -(m0 * (m5 * m14 - m6 * m13) - m1 * (m4 * m14 - m6 * m12) + m2 * (m4 * m13 - m5 * m12))),
      clean_float(inv_det * (m0 * (m5 * m10 - m6 * m9) - m1 * (m4 * m10 - m6 * m8) + m2 * (m4 * m9 - m5 * m8)))
    }
  end
end
