# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

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

  # Nx tensor-based operations
  alias AriaMath.Matrix4.Tensor

  @doc """
  Creates a new Matrix4 tensor from 16 float components.
  """
  defdelegate new_nx(
    m00, m01, m02, m03,
    m10, m11, m12, m13,
    m20, m21, m22, m23,
    m30, m31, m32, m33
  ), to: Tensor, as: :new

  @doc """
  Creates a Matrix4 tensor from a tuple.
  """
  defdelegate from_tuple(tuple), to: Tensor

  @doc """
  Converts a Matrix4 tensor to a tuple.
  """
  defdelegate to_tuple(tensor), to: Tensor

  @doc """
  Creates an identity matrix using Nx operations.
  """
  defdelegate identity_nx(), to: Tensor, as: :identity

  @doc """
  Matrix multiplication using Nx operations.
  """
  defdelegate multiply_nx(a, b), to: Tensor, as: :multiply

  @doc """
  Batch matrix multiplication for multiple matrix pairs.
  """
  defdelegate multiply_batch(a_matrices, b_matrices), to: Tensor

  @doc """
  Matrix transpose using Nx operations.
  """
  defdelegate transpose_nx(matrix), to: Tensor, as: :transpose

  @doc """
  Batch matrix transpose for multiple matrices.
  """
  defdelegate transpose_batch(matrices), to: Tensor

  @doc """
  Matrix determinant using Nx operations.
  """
  defdelegate determinant_nx(matrix), to: Tensor, as: :determinant

  @doc """
  Batch matrix determinant for multiple matrices.
  """
  defdelegate determinant_batch(matrices), to: Tensor

  @doc """
  Matrix inversion using Nx operations.
  """
  defdelegate invert_nx(matrix), to: Tensor, as: :invert

  @doc """
  Batch matrix inversion for multiple matrices.
  """
  defdelegate invert_batch(matrices), to: Tensor

  @doc """
  Transform a Vector3 by this matrix using Nx operations.
  """
  defdelegate transform_vector3_nx(matrix, vector), to: Tensor, as: :transform_vector3

  @doc """
  Batch transform multiple Vector3s by multiple matrices.
  """
  defdelegate transform_vector3_batch(matrices, vectors), to: Tensor

  @doc """
  Creates a translation matrix from a Vector3 using Nx operations.
  """
  defdelegate translation_nx(vector), to: Tensor, as: :translation

  @doc """
  Creates a uniform scale matrix using Nx operations.
  """
  defdelegate scale_nx(factor), to: Tensor, as: :scale

  @doc """
  Creates a non-uniform scale matrix from a Vector3 using Nx operations.
  """
  defdelegate scale_vector3_nx(vector), to: Tensor, as: :scale_vector3

  @doc """
  Checks if two matrices are approximately equal using Nx operations.
  """
  defdelegate equal_nx?(a, b, tolerance \\ 1.0e-6), to: Tensor, as: :equal?

  @doc """
  Batch equality check for multiple matrix pairs.
  """
  defdelegate equal_batch?(a_matrices, b_matrices, tolerance \\ 1.0e-6), to: Tensor

  @doc """
  Matrix inversion using Nx operations (alias for invert_nx).
  """
  defdelegate inverse_nx(matrix), to: Tensor, as: :invert

  @doc """
  Batch transform multiple points by a single matrix.
  """
  defdelegate transform_points_batch(matrix, points), to: Tensor

  @doc """
  Batch transform multiple vectors by a single matrix.
  """
  defdelegate transform_vectors_batch(matrix, vectors), to: Tensor

  @doc """
  Convert matrix to tuple list format.
  """
  defdelegate to_tuple_list(matrix), to: Tensor

  @doc """
  Create matrix from tuple list format.
  """
  defdelegate from_tuple_list(tuple_list), to: Tensor

end
