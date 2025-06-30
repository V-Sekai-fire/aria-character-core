# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaMath.Matrix4 do
  @moduledoc """
  Matrix4 mathematical operations implementing glTF KHR Interactivity `float4x4` matrix operations.

  All operations follow IEEE-754 standard for NaN, infinity, and special case handling
  as defined in the glTF KHR Interactivity specification.

  Matrix4 is represented as a tuple of 16 floats in column-major order, following glTF convention.
  The matrix layout is:
  ```
  [ m0  m4  m8  m12]
  [ m1  m5  m9  m13]
  [ m2  m6  m10 m14]
  [ m3  m7  m11 m15]
  ```
  """

  alias AriaMath.Matrix4.{Core, Transformations, Euler, Transforms}

  @type t :: {
          float(), float(), float(), float(),
          float(), float(), float(), float(),
          float(), float(), float(), float(),
          float(), float(), float(), float()
        }

  @doc """
  Creates a new Matrix4 from 16 float components in column-major order.

  ## Examples

      iex> AriaMath.Matrix4.new(1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1)
      {1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0}
  """
  @spec new(
          float(), float(), float(), float(),
          float(), float(), float(), float(),
          float(), float(), float(), float(),
          float(), float(), float(), float()
        ) :: t()
  def new(m0, m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, m12, m13, m14, m15) do
    {m0/1, m1/1, m2/1, m3/1, m4/1, m5/1, m6/1, m7/1, m8/1, m9/1, m10/1, m11/1, m12/1, m13/1, m14/1, m15/1}
  end

  # Core operations - delegate to Core module
  defdelegate multiply(a, b), to: Core
  defdelegate determinant(matrix), to: Core
  defdelegate inverse(matrix), to: Core
  defdelegate transpose(matrix), to: Core

  # Transformation operations - delegate to Transformations module
  defdelegate get_translation(matrix), to: Transformations
  defdelegate translation(vector), to: Transformations
  defdelegate scaling(vector), to: Transformations
  defdelegate rotation(quat_or_matrix), to: Transformations
  defdelegate compose(translation, rotation, scale), to: Transformations
  defdelegate decompose(matrix), to: Transformations

  # Euler operations - delegate to Euler module
  defdelegate from_euler(x, y, z), to: Euler
  defdelegate from_euler(x, y, z, order), to: Euler

  # Transform operations - delegate to Transforms module
  defdelegate transform_point(matrix, point), to: Transforms
  defdelegate transform_direction(matrix, direction), to: Transforms
  defdelegate transform_vector(matrix, vector), to: Transforms
  defdelegate identity(), to: Transforms
  defdelegate zero(), to: Transforms
  defdelegate equal?(a, b), to: Transforms

  # Additional transformation operations - delegate to Transformations module
  defdelegate extract_basis(matrix), to: Transformations
  defdelegate orthogonalize(matrix), to: Transformations

end
