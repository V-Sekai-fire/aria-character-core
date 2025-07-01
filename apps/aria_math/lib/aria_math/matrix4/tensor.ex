# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaMath.Matrix4.Tensor do
  @moduledoc """
  Nx tensor-based Matrix4 operations.

  This module provides the same API as Matrix4.Core but uses Nx tensors
  for optimized numerical computing and potential GPU acceleration.
  """

  @type matrix4_tensor :: Nx.Tensor.t()
  @type matrix4_tuple :: {
    float(), float(), float(), float(),
    float(), float(), float(), float(),
    float(), float(), float(), float(),
    float(), float(), float(), float()
  }

  @doc """
  Creates a new Matrix4 tensor from 16 float components in row-major order.

  ## Examples

      iex> AriaMath.Matrix4.Tensor.new(
      ...>   1.0, 0.0, 0.0, 0.0,
      ...>   0.0, 1.0, 0.0, 0.0,
      ...>   0.0, 0.0, 1.0, 0.0,
      ...>   0.0, 0.0, 0.0, 1.0
      ...> )
      #Nx.Tensor<
        f32[4][4]
        [
          [1.0, 0.0, 0.0, 0.0],
          [0.0, 1.0, 0.0, 0.0],
          [0.0, 0.0, 1.0, 0.0],
          [0.0, 0.0, 0.0, 1.0]
        ]
      >
  """
  @spec new(
    float(), float(), float(), float(),
    float(), float(), float(), float(),
    float(), float(), float(), float(),
    float(), float(), float(), float()
  ) :: matrix4_tensor()
  def new(
    m00, m01, m02, m03,
    m10, m11, m12, m13,
    m20, m21, m22, m23,
    m30, m31, m32, m33
  ) do
    Nx.tensor([
      [m00, m01, m02, m03],
      [m10, m11, m12, m13],
      [m20, m21, m22, m23],
      [m30, m31, m32, m33]
    ], type: :f32)
  end

  @doc """
  Creates a Matrix4 tensor from a 16-tuple.

  ## Examples

      iex> tuple = {1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0}
      iex> AriaMath.Matrix4.Tensor.from_tuple(tuple)
      #Nx.Tensor<
        f32[4][4]
        [
          [1.0, 0.0, 0.0, 0.0],
          [0.0, 1.0, 0.0, 0.0],
          [0.0, 0.0, 1.0, 0.0],
          [0.0, 0.0, 0.0, 1.0]
        ]
      >
  """
  @spec from_tuple(matrix4_tuple()) :: matrix4_tensor()
  def from_tuple({
    m00, m01, m02, m03,
    m10, m11, m12, m13,
    m20, m21, m22, m23,
    m30, m31, m32, m33
  }) do
    new(
      m00, m01, m02, m03,
      m10, m11, m12, m13,
      m20, m21, m22, m23,
      m30, m31, m32, m33
    )
  end

  @doc """
  Converts a Matrix4 tensor to a 16-tuple.

  ## Examples

      iex> matrix = AriaMath.Matrix4.Tensor.identity()
      iex> AriaMath.Matrix4.Tensor.to_tuple(matrix)
      {1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0}
  """
  @spec to_tuple(matrix4_tensor()) :: matrix4_tuple()
  def to_tuple(tensor) do
    [[m00, m01, m02, m03], [m10, m11, m12, m13], [m20, m21, m22, m23], [m30, m31, m32, m33]] =
      Nx.to_list(tensor)
    {m00, m01, m02, m03, m10, m11, m12, m13, m20, m21, m22, m23, m30, m31, m32, m33}
  end

  @doc """
  Creates an identity matrix using Nx operations.

  ## Examples

      iex> AriaMath.Matrix4.Tensor.identity()
      #Nx.Tensor<
        f32[4][4]
        [
          [1.0, 0.0, 0.0, 0.0],
          [0.0, 1.0, 0.0, 0.0],
          [0.0, 0.0, 1.0, 0.0],
          [0.0, 0.0, 0.0, 1.0]
        ]
      >
  """
  @spec identity() :: matrix4_tensor()
  def identity do
    Nx.eye(4, type: :f32)
  end

  @doc """
  Matrix multiplication using Nx operations.

  ## Examples

      iex> a = AriaMath.Matrix4.Tensor.identity()
      iex> b = AriaMath.Matrix4.Tensor.identity()
      iex> result = AriaMath.Matrix4.Tensor.multiply(a, b)
      iex> AriaMath.Matrix4.Tensor.equal?(result, AriaMath.Matrix4.Tensor.identity())
      true
  """
  @spec multiply(matrix4_tensor(), matrix4_tensor()) :: matrix4_tensor()
  def multiply(a, b) do
    Nx.dot(a, b)
  end

  @doc """
  Batch matrix multiplication for multiple matrix pairs.

  ## Examples

      iex> a_matrices = Nx.stack([AriaMath.Matrix4.Tensor.identity(), AriaMath.Matrix4.Tensor.identity()])
      iex> b_matrices = Nx.stack([AriaMath.Matrix4.Tensor.identity(), AriaMath.Matrix4.Tensor.identity()])
      iex> results = AriaMath.Matrix4.Tensor.multiply_batch(a_matrices, b_matrices)
      iex> Nx.shape(results)
      {2, 4, 4}
  """
  @spec multiply_batch(Nx.Tensor.t(), Nx.Tensor.t()) :: Nx.Tensor.t()
  def multiply_batch(a_matrices, b_matrices) do
    Nx.dot(a_matrices, b_matrices)
  end

  @doc """
  Matrix transpose using Nx operations.

  ## Examples

      iex> matrix = AriaMath.Matrix4.Tensor.new(
      ...>   1.0, 2.0, 3.0, 4.0,
      ...>   5.0, 6.0, 7.0, 8.0,
      ...>   9.0, 10.0, 11.0, 12.0,
      ...>   13.0, 14.0, 15.0, 16.0
      ...> )
      iex> transposed = AriaMath.Matrix4.Tensor.transpose(matrix)
      iex> Nx.to_list(transposed)
      [[1.0, 5.0, 9.0, 13.0], [2.0, 6.0, 10.0, 14.0], [3.0, 7.0, 11.0, 15.0], [4.0, 8.0, 12.0, 16.0]]
  """
  @spec transpose(matrix4_tensor()) :: matrix4_tensor()
  def transpose(matrix) do
    Nx.transpose(matrix)
  end

  @doc """
  Batch matrix transpose for multiple matrices.

  ## Examples

      iex> matrices = Nx.stack([AriaMath.Matrix4.Tensor.identity(), AriaMath.Matrix4.Tensor.identity()])
      iex> transposed = AriaMath.Matrix4.Tensor.transpose_batch(matrices)
      iex> Nx.shape(transposed)
      {2, 4, 4}
  """
  @spec transpose_batch(Nx.Tensor.t()) :: Nx.Tensor.t()
  def transpose_batch(matrices) do
    Nx.transpose(matrices, axes: [0, 2, 1])
  end

  @doc """
  Matrix determinant using Nx operations.

  ## Examples

      iex> matrix = AriaMath.Matrix4.Tensor.identity()
      iex> AriaMath.Matrix4.Tensor.determinant(matrix)
      1.0
  """
  @spec determinant(matrix4_tensor()) :: float()
  def determinant(matrix) do
    Nx.LinAlg.determinant(matrix) |> Nx.to_number()
  end

  @doc """
  Batch matrix determinant for multiple matrices.

  ## Examples

      iex> matrices = Nx.stack([AriaMath.Matrix4.Tensor.identity(), AriaMath.Matrix4.Tensor.identity()])
      iex> dets = AriaMath.Matrix4.Tensor.determinant_batch(matrices)
      iex> Nx.to_list(dets)
      [1.0, 1.0]
  """
  @spec determinant_batch(Nx.Tensor.t()) :: Nx.Tensor.t()
  def determinant_batch(matrices) do
    Nx.LinAlg.determinant(matrices)
  end

  @doc """
  Matrix inversion using Nx operations with validity checking.

  Returns {inverted_matrix, is_valid} where:
  - inverted_matrix: inverse matrix if valid, or identity matrix if invalid
  - is_valid: true if matrix is invertible, false otherwise

  ## Examples

      iex> matrix = AriaMath.Matrix4.Tensor.identity()
      iex> {inverse, valid} = AriaMath.Matrix4.Tensor.invert(matrix)
      iex> valid
      true
      iex> AriaMath.Matrix4.Tensor.equal?(inverse, AriaMath.Matrix4.Tensor.identity())
      true
  """
  @spec invert(matrix4_tensor()) :: {matrix4_tensor(), boolean()}
  def invert(matrix) do
    det = Nx.LinAlg.determinant(matrix) |> Nx.to_number()

    if abs(det) < 1.0e-10 do
      # Matrix is singular, return identity and false
      {identity(), false}
    else
      try do
        inverse = Nx.LinAlg.invert(matrix)
        {inverse, true}
      rescue
        _ ->
          # Inversion failed, return identity and false
          {identity(), false}
      end
    end
  end

  @doc """
  Batch matrix inversion for multiple matrices.

  ## Examples

      iex> matrices = Nx.stack([AriaMath.Matrix4.Tensor.identity(), AriaMath.Matrix4.Tensor.identity()])
      iex> {inverses, valid_mask} = AriaMath.Matrix4.Tensor.invert_batch(matrices)
      iex> Nx.to_list(valid_mask)
      [1, 1]  # Both matrices are invertible
  """
  @spec invert_batch(Nx.Tensor.t()) :: {Nx.Tensor.t(), Nx.Tensor.t()}
  def invert_batch(matrices) do
    dets = Nx.LinAlg.determinant(matrices)
    valid_mask = Nx.greater(Nx.abs(dets), 1.0e-10)

    # For invalid matrices, we'll replace with identity
    identity_batch = Nx.broadcast(identity(), Nx.shape(matrices))

    try do
      inverses = Nx.LinAlg.invert(matrices)
      # Replace invalid inverses with identity matrices
      safe_inverses = Nx.select(
        Nx.new_axis(Nx.new_axis(valid_mask, -1), -1),
        inverses,
        identity_batch
      )
      {safe_inverses, valid_mask}
    rescue
      _ ->
        # If batch inversion fails, return identity matrices and all false
        {identity_batch, Nx.broadcast(0, Nx.shape(dets))}
    end
  end

  @doc """
  Transform a Vector3 by this matrix (treating vector as homogeneous coordinate with w=1).

  ## Examples

      iex> matrix = AriaMath.Matrix4.Tensor.identity()
      iex> vector = AriaMath.Vector3.Tensor.new(1.0, 2.0, 3.0)
      iex> result = AriaMath.Matrix4.Tensor.transform_vector3(matrix, vector)
      iex> AriaMath.Vector3.Tensor.to_tuple(result)
      {1.0, 2.0, 3.0}
  """
  @spec transform_vector3(matrix4_tensor(), AriaMath.Vector3.Tensor.vector3_tensor()) :: AriaMath.Vector3.Tensor.vector3_tensor()
  def transform_vector3(matrix, vector) do
    # Convert Vector3 to homogeneous coordinates (add w=1)
    homogeneous = Nx.concatenate([vector, Nx.tensor([1.0])])

    # Transform by matrix
    transformed = Nx.dot(matrix, homogeneous)

    # Extract x, y, z components (ignore w)
    Nx.slice_along_axis(transformed, 0, 3, axis: 0)
  end

  @doc """
  Batch transform multiple Vector3s by multiple matrices.

  ## Examples

      iex> matrices = Nx.stack([AriaMath.Matrix4.Tensor.identity(), AriaMath.Matrix4.Tensor.identity()])
      iex> vectors = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
      iex> results = AriaMath.Matrix4.Tensor.transform_vector3_batch(matrices, vectors)
      iex> Nx.to_list(results)
      [[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]]
  """
  @spec transform_vector3_batch(Nx.Tensor.t(), Nx.Tensor.t()) :: Nx.Tensor.t()
  def transform_vector3_batch(matrices, vectors) do
    # Add homogeneous coordinate (w=1) to all vectors
    ones = Nx.broadcast(1.0, {Nx.axis_size(vectors, 0), 1})
    homogeneous = Nx.concatenate([vectors, ones], axis: 1)

    # Transform by matrices (batch matrix-vector multiplication)
    transformed = Nx.dot(matrices, Nx.new_axis(homogeneous, -1))

    # Remove the last axis and extract x, y, z components
    squeezed = Nx.squeeze(transformed, axes: [-1])
    Nx.slice_along_axis(squeezed, 0, 3, axis: 1)
  end

  @doc """
  Creates a translation matrix from a Vector3.

  ## Examples

      iex> translation = AriaMath.Vector3.Tensor.new(1.0, 2.0, 3.0)
      iex> matrix = AriaMath.Matrix4.Tensor.translation(translation)
      iex> # Check that it's a translation matrix
      iex> [row0, row1, row2, row3] = Nx.to_list(matrix)
      iex> row3
      [1.0, 2.0, 3.0, 1.0]
  """
  @spec translation(AriaMath.Vector3.Tensor.vector3_tensor()) :: matrix4_tensor()
  def translation(vector) do
    [x, y, z] = Nx.to_list(vector)

    new(
      1.0, 0.0, 0.0, x,
      0.0, 1.0, 0.0, y,
      0.0, 0.0, 1.0, z,
      0.0, 0.0, 0.0, 1.0
    )
  end

  @doc """
  Creates a uniform scale matrix.

  ## Examples

      iex> matrix = AriaMath.Matrix4.Tensor.scale(2.0)
      iex> # Check diagonal elements
      iex> diag = Nx.take_diagonal(matrix) |> Nx.to_list()
      iex> diag
      [2.0, 2.0, 2.0, 1.0]
  """
  @spec scale(float()) :: matrix4_tensor()
  def scale(factor) when is_number(factor) do
    new(
      factor, 0.0, 0.0, 0.0,
      0.0, factor, 0.0, 0.0,
      0.0, 0.0, factor, 0.0,
      0.0, 0.0, 0.0, 1.0
    )
  end

  @doc """
  Creates a non-uniform scale matrix from a Vector3.

  ## Examples

      iex> scale_vec = AriaMath.Vector3.Tensor.new(2.0, 3.0, 4.0)
      iex> matrix = AriaMath.Matrix4.Tensor.scale_vector3(scale_vec)
      iex> diag = Nx.take_diagonal(matrix) |> Nx.to_list()
      iex> diag
      [2.0, 3.0, 4.0, 1.0]
  """
  @spec scale_vector3(AriaMath.Vector3.Tensor.vector3_tensor()) :: matrix4_tensor()
  def scale_vector3(vector) do
    [x, y, z] = Nx.to_list(vector)

    new(
      x, 0.0, 0.0, 0.0,
      0.0, y, 0.0, 0.0,
      0.0, 0.0, z, 0.0,
      0.0, 0.0, 0.0, 1.0
    )
  end

  @doc """
  Checks if two matrices are approximately equal within a tolerance.

  ## Examples

      iex> a = AriaMath.Matrix4.Tensor.identity()
      iex> b = AriaMath.Matrix4.Tensor.identity()
      iex> AriaMath.Matrix4.Tensor.equal?(a, b)
      true
  """
  @spec equal?(matrix4_tensor(), matrix4_tensor(), float()) :: boolean()
  def equal?(a, b, tolerance \\ 1.0e-6) do
    diff = Nx.subtract(a, b)
    max_diff = Nx.abs(diff) |> Nx.reduce_max() |> Nx.to_number()
    max_diff <= tolerance
  end

  @doc """
  Batch matrix equality check for multiple matrix pairs.

  ## Examples

      iex> m1_batch = Nx.stack([AriaMath.Matrix4.Tensor.identity(), AriaMath.Matrix4.Tensor.identity()])
      iex> m2_batch = Nx.stack([AriaMath.Matrix4.Tensor.identity(), AriaMath.Matrix4.Tensor.identity()])
      iex> results = AriaMath.Matrix4.Tensor.equal_batch?(m1_batch, m2_batch)
      iex> Nx.to_list(results)
      [1, 1]  # Both pairs are equal
  """
  @spec equal_batch?(Nx.Tensor.t(), Nx.Tensor.t(), float()) :: Nx.Tensor.t()
  def equal_batch?(m1_batch, m2_batch, tolerance \\ 1.0e-6) do
    diff = Nx.subtract(m1_batch, m2_batch)
    max_diff_per_matrix = Nx.abs(diff) |> Nx.reduce_max(axes: [1, 2])
    Nx.less_equal(max_diff_per_matrix, tolerance)
  end

  @doc """
  Matrix transpose using Nx operations.

  ## Examples

      iex> m = AriaMath.Matrix4.Tensor.new([
      ...>   [1.0, 2.0, 3.0, 4.0],
      ...>   [5.0, 6.0, 7.0, 8.0],
      ...>   [9.0, 10.0, 11.0, 12.0],
      ...>   [13.0, 14.0, 15.0, 16.0]
      ...> ])
      iex> transposed = AriaMath.Matrix4.Tensor.transpose_nx(m)
      iex> Nx.shape(transposed)
      {4, 4}
  """
  @spec transpose_nx(Nx.Tensor.t()) :: Nx.Tensor.t()
  def transpose_nx(matrix) do
    Nx.transpose(matrix, axes: [1, 0])
  end

  @doc """
  Matrix inverse using Nx operations.

  ## Examples

      iex> m = AriaMath.Matrix4.Tensor.identity()
      iex> inv = AriaMath.Matrix4.Tensor.inverse_nx(m)
      iex> AriaMath.Matrix4.Tensor.equal?(m, inv)
      true
  """
  @spec inverse_nx(Nx.Tensor.t()) :: Nx.Tensor.t()
  def inverse_nx(matrix) do
    # Use Nx.LinAlg.invert for matrix inversion
    # Handle potential singular matrices by adding small regularization
    regularized = Nx.add(matrix, Nx.multiply(Nx.eye(4), 1.0e-12))
    Nx.LinAlg.invert(regularized)
  end

  @doc """
  Create a translation matrix using Nx operations.

  ## Examples

      iex> trans = AriaMath.Matrix4.Tensor.translation_nx({1.0, 2.0, 3.0})
      iex> Nx.shape(trans)
      {4, 4}
  """
  @spec translation_nx({float(), float(), float()}) :: Nx.Tensor.t()
  def translation_nx({x, y, z}) do
    Nx.tensor([
      [1.0, 0.0, 0.0, x],
      [0.0, 1.0, 0.0, y],
      [0.0, 0.0, 1.0, z],
      [0.0, 0.0, 0.0, 1.0]
    ], type: :f32)
  end

  @doc """
  Transform multiple points using a matrix with batch operations.

  Points are assumed to be homogeneous (w = 1.0) for transformation.

  ## Examples

      iex> matrix = AriaMath.Matrix4.Tensor.translation_nx({1.0, 2.0, 3.0})
      iex> points = Nx.tensor([[0.0, 0.0, 0.0], [1.0, 1.0, 1.0]], type: :f32)
      iex> transformed = AriaMath.Matrix4.Tensor.transform_points_batch(matrix, points)
      iex> Nx.shape(transformed)
      {2, 3}
  """
  @spec transform_points_batch(Nx.Tensor.t(), Nx.Tensor.t()) :: Nx.Tensor.t()
  def transform_points_batch(matrix, points) do
    # Convert points to homogeneous coordinates by adding w = 1.0
    num_points = Nx.axis_size(points, 0)
    ones = Nx.broadcast(1.0, {num_points, 1})
    homogeneous_points = Nx.concatenate([points, ones], axis: 1)

    # Transform homogeneous points: matrix * points^T, then transpose back
    transformed_homo = Nx.dot(homogeneous_points, [1], matrix, [0])

    # Extract x, y, z components (drop w component)
    Nx.slice_along_axis(transformed_homo, 0, 3, axis: 1)
  end

  @doc """
  Transform multiple vectors using a matrix with batch operations.

  Vectors are assumed to be directions (w = 0.0) for transformation.

  ## Examples

      iex> matrix = AriaMath.Matrix4.Tensor.identity()
      iex> vectors = Nx.tensor([[1.0, 0.0, 0.0], [0.0, 1.0, 0.0]], type: :f32)
      iex> transformed = AriaMath.Matrix4.Tensor.transform_vectors_batch(matrix, vectors)
      iex> Nx.shape(transformed)
      {2, 3}
  """
  @spec transform_vectors_batch(Nx.Tensor.t(), Nx.Tensor.t()) :: Nx.Tensor.t()
  def transform_vectors_batch(matrix, vectors) do
    # Convert vectors to homogeneous coordinates by adding w = 0.0
    num_vectors = Nx.axis_size(vectors, 0)
    zeros = Nx.broadcast(0.0, {num_vectors, 1})
    homogeneous_vectors = Nx.concatenate([vectors, zeros], axis: 1)

    # Transform homogeneous vectors: matrix * vectors^T, then transpose back
    transformed_homo = Nx.dot(homogeneous_vectors, [1], matrix, [0])

    # Extract x, y, z components (drop w component)
    Nx.slice_along_axis(transformed_homo, 0, 3, axis: 1)
  end

  @doc """
  Create a scaling matrix using Nx operations.

  ## Examples

      iex> scale = AriaMath.Matrix4.Tensor.scaling_nx({2.0, 3.0, 4.0})
      iex> Nx.shape(scale)
      {4, 4}
  """
  @spec scaling_nx({float(), float(), float()}) :: Nx.Tensor.t()
  def scaling_nx({x, y, z}) do
    Nx.tensor([
      [x, 0.0, 0.0, 0.0],
      [0.0, y, 0.0, 0.0],
      [0.0, 0.0, z, 0.0],
      [0.0, 0.0, 0.0, 1.0]
    ], type: :f32)
  end

  @doc """
  Create a rotation matrix around X-axis using Nx operations.

  ## Examples

      iex> rot = AriaMath.Matrix4.Tensor.rotation_x_nx(:math.pi() / 2)
      iex> Nx.shape(rot)
      {4, 4}
  """
  @spec rotation_x_nx(float()) :: Nx.Tensor.t()
  def rotation_x_nx(angle) when is_number(angle) do
    cos_a = :math.cos(angle)
    sin_a = :math.sin(angle)

    Nx.tensor([
      [1.0, 0.0, 0.0, 0.0],
      [0.0, cos_a, -sin_a, 0.0],
      [0.0, sin_a, cos_a, 0.0],
      [0.0, 0.0, 0.0, 1.0]
    ], type: :f32)
  end

  @doc """
  Create a rotation matrix around Y-axis using Nx operations.

  ## Examples

      iex> rot = AriaMath.Matrix4.Tensor.rotation_y_nx(:math.pi() / 2)
      iex> Nx.shape(rot)
      {4, 4}
  """
  @spec rotation_y_nx(float()) :: Nx.Tensor.t()
  def rotation_y_nx(angle) when is_number(angle) do
    cos_a = :math.cos(angle)
    sin_a = :math.sin(angle)

    Nx.tensor([
      [cos_a, 0.0, sin_a, 0.0],
      [0.0, 1.0, 0.0, 0.0],
      [-sin_a, 0.0, cos_a, 0.0],
      [0.0, 0.0, 0.0, 1.0]
    ], type: :f32)
  end

  @doc """
  Create a rotation matrix around Z-axis using Nx operations.

  ## Examples

      iex> rot = AriaMath.Matrix4.Tensor.rotation_z_nx(:math.pi() / 2)
      iex> Nx.shape(rot)
      {4, 4}
  """
  @spec rotation_z_nx(float()) :: Nx.Tensor.t()
  def rotation_z_nx(angle) when is_number(angle) do
    cos_a = :math.cos(angle)
    sin_a = :math.sin(angle)

    Nx.tensor([
      [cos_a, -sin_a, 0.0, 0.0],
      [sin_a, cos_a, 0.0, 0.0],
      [0.0, 0.0, 1.0, 0.0],
      [0.0, 0.0, 0.0, 1.0]
    ], type: :f32)
  end

  @doc """
  Convert a Matrix4 tensor to a list of tuples (row-wise).

  ## Examples

      iex> matrix = AriaMath.Matrix4.Tensor.identity()
      iex> AriaMath.Matrix4.Tensor.to_tuple_list(matrix)
      [{1.0, 0.0, 0.0, 0.0}, {0.0, 1.0, 0.0, 0.0}, {0.0, 0.0, 1.0, 0.0}, {0.0, 0.0, 0.0, 1.0}]
  """
  @spec to_tuple_list(matrix4_tensor()) :: [tuple()]
  def to_tuple_list(matrix) do
    matrix
    |> Nx.to_list()
    |> Enum.map(&List.to_tuple/1)
  end

  @doc """
  Convert a list of tuples to a Matrix4 tensor.

  ## Examples

      iex> tuple_list = [{1.0, 0.0, 0.0, 0.0}, {0.0, 1.0, 0.0, 0.0}, {0.0, 0.0, 1.0, 0.0}, {0.0, 0.0, 0.0, 1.0}]
      iex> matrix = AriaMath.Matrix4.Tensor.from_tuple_list(tuple_list)
      iex> AriaMath.Matrix4.Tensor.equal?(matrix, AriaMath.Matrix4.Tensor.identity())
      true
  """
  @spec from_tuple_list([tuple()]) :: matrix4_tensor()
  def from_tuple_list(tuple_list) do
    tuple_list
    |> Enum.map(&Tuple.to_list/1)
    |> Nx.tensor(type: :f32)
  end

  @doc """
  Batch matrix inversion using Nx operations.

  ## Examples

      iex> matrices = Nx.stack([AriaMath.Matrix4.Tensor.identity(), AriaMath.Matrix4.Tensor.identity()])
      iex> inverses = AriaMath.Matrix4.Tensor.inverse_batch(matrices)
      iex> Nx.shape(inverses)
      {2, 4, 4}
  """
  @spec inverse_batch(Nx.Tensor.t()) :: Nx.Tensor.t()
  def inverse_batch(matrices) do
    Nx.LinAlg.invert(matrices)
  end

  @doc """
  Batch scaling matrix creation from vectors.

  ## Examples

      iex> scales = Nx.tensor([[2.0, 3.0, 4.0], [1.5, 2.5, 3.5]])
      iex> matrices = AriaMath.Matrix4.Tensor.scaling_batch(scales)
      iex> Nx.shape(matrices)
      {2, 4, 4}
  """
  @spec scaling_batch(Nx.Tensor.t()) :: Nx.Tensor.t()
  def scaling_batch(scale_vectors) do
    batch_size = Nx.axis_size(scale_vectors, 0)

    # Create identity matrices for the batch
    identities = Nx.broadcast(identity(), {batch_size, 4, 4})

    # Extract scale components
    scale_x = scale_vectors[[.., 0]]
    scale_y = scale_vectors[[.., 1]]
    scale_z = scale_vectors[[.., 2]]

    # Apply scaling to diagonal elements
    scaled_matrices = identities
    |> Nx.put_slice([0, 0, 0], Nx.reshape(scale_x, {batch_size, 1, 1}))
    |> Nx.put_slice([0, 1, 1], Nx.reshape(scale_y, {batch_size, 1, 1}))
    |> Nx.put_slice([0, 2, 2], Nx.reshape(scale_z, {batch_size, 1, 1}))

    scaled_matrices
  end

  @doc """
  Linear interpolation between two batches of matrices.

  ## Examples

      iex> m1_batch = Nx.stack([AriaMath.Matrix4.Tensor.identity(), AriaMath.Matrix4.Tensor.identity()])
      iex> m2_batch = Nx.stack([AriaMath.Matrix4.Tensor.scale(2.0), AriaMath.Matrix4.Tensor.scale(3.0)])
      iex> t_values = Nx.tensor([0.5, 0.5])
      iex> interpolated = AriaMath.Matrix4.Tensor.lerp_batch(m1_batch, m2_batch, t_values)
      iex> Nx.shape(interpolated)
      {2, 4, 4}
  """
  @spec lerp_batch(Nx.Tensor.t(), Nx.Tensor.t(), Nx.Tensor.t()) :: Nx.Tensor.t()
  def lerp_batch(m1_batch, m2_batch, t_batch) do
    # Linear interpolation: (1 - t) * m1 + t * m2
    t_expanded = Nx.reshape(t_batch, {Nx.axis_size(t_batch, 0), 1, 1})
    one_minus_t = Nx.subtract(1.0, t_expanded)

    term1 = Nx.multiply(one_minus_t, m1_batch)
    term2 = Nx.multiply(t_expanded, m2_batch)

    Nx.add(term1, term2)
  end

  @doc """
  Transform multiple point sets using multiple matrices with batch operations.

  Each matrix transforms its corresponding set of points. This is different from
  transform_points_batch which uses a single matrix for all points.

  ## Examples

      iex> matrices = Nx.stack([AriaMath.Matrix4.Tensor.identity(), AriaMath.Matrix4.Tensor.translation_nx({1.0, 0.0, 0.0})])
      iex> points = Nx.tensor([[[0.0, 0.0, 0.0], [1.0, 1.0, 1.0]], [[2.0, 2.0, 2.0], [3.0, 3.0, 3.0]]], type: :f32)
      iex> transformed = AriaMath.Matrix4.Tensor.transform_points_batch_multi(matrices, points)
      iex> Nx.shape(transformed)
      {2, 2, 3}
  """
  @spec transform_points_batch_multi(Nx.Tensor.t(), Nx.Tensor.t()) :: Nx.Tensor.t()
  def transform_points_batch_multi(matrices, points) do
    # matrices: {num_matrices, 4, 4}
    # points: {num_matrices, num_points, 3}

    # Convert points to homogeneous coordinates by adding w = 1.0
    {num_matrices, num_points, _} = Nx.shape(points)
    ones = Nx.broadcast(1.0, {num_matrices, num_points, 1})
    homogeneous_points = Nx.concatenate([points, ones], axis: 2)

    # Batch matrix multiplication: each matrix transforms its corresponding point set
    # Use batched dot product: matrices[i] * homogeneous_points[i]^T
    transformed_homo = Nx.dot(matrices, [2], homogeneous_points, [2])

    # Extract x, y, z components (drop w component)
    Nx.slice_along_axis(transformed_homo, 0, 3, axis: 2)
  end

  @doc """
  Extract translation vectors from batch of transformation matrices.

  ## Examples

      iex> trans_vec = AriaMath.Vector3.Tensor.new(1.0, 2.0, 3.0)
      iex> matrix = AriaMath.Matrix4.Tensor.translation(trans_vec)
      iex> matrices = Nx.stack([matrix, matrix])
      iex> translations = AriaMath.Matrix4.Tensor.extract_translations_batch(matrices)
      iex> Nx.shape(translations)
      {2, 3}
  """
  @spec extract_translations_batch(Nx.Tensor.t()) :: Nx.Tensor.t()
  def extract_translations_batch(matrices) do
    # Extract the translation column (last column, first 3 rows)
    matrices[[.., 0..2, 3]]
  end

  @doc """
  Extract rotation matrices from batch of transformation matrices.

  ## Examples

      iex> matrices = Nx.stack([AriaMath.Matrix4.Tensor.identity(), AriaMath.Matrix4.Tensor.identity()])
      iex> rotations = AriaMath.Matrix4.Tensor.extract_rotations_batch(matrices)
      iex> Nx.shape(rotations)
      {2, 3, 3}
  """
  @spec extract_rotations_batch(Nx.Tensor.t()) :: Nx.Tensor.t()
  def extract_rotations_batch(matrices) do
    # Extract the upper-left 3x3 rotation part
    matrices[[.., 0..2, 0..2]]
  end

end
