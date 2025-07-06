# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaMath.Matrix4.Core do
  @moduledoc """
  Core Matrix4 operations using Nx tensors.

  This module provides basic matrix operations including creation, multiplication,
  inversion, and fundamental transformations.
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

      iex> AriaMath.Matrix4.Core.new(
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
      iex> AriaMath.Matrix4.Core.from_tuple(tuple)
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

      iex> matrix = AriaMath.Matrix4.Core.identity()
      iex> AriaMath.Matrix4.Core.to_tuple(matrix)
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

      iex> AriaMath.Matrix4.Core.identity()
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

      iex> a = AriaMath.Matrix4.Core.identity()
      iex> b = AriaMath.Matrix4.Core.identity()
      iex> result = AriaMath.Matrix4.Core.multiply(a, b)
      iex> AriaMath.Matrix4.Core.equal?(result, AriaMath.Matrix4.Core.identity())
      true
  """
  @spec multiply(matrix4_tensor(), matrix4_tensor()) :: matrix4_tensor()
  def multiply(a, b) do
    Nx.dot(a, b)
  end

  @doc """
  Matrix transpose using Nx operations.

  ## Examples

      iex> matrix = AriaMath.Matrix4.Core.new(
      ...>   1.0, 2.0, 3.0, 4.0,
      ...>   5.0, 6.0, 7.0, 8.0,
      ...>   9.0, 10.0, 11.0, 12.0,
      ...>   13.0, 14.0, 15.0, 16.0
      ...> )
      iex> transposed = AriaMath.Matrix4.Core.transpose(matrix)
      iex> Nx.to_list(transposed)
      [[1.0, 5.0, 9.0, 13.0], [2.0, 6.0, 10.0, 14.0], [3.0, 7.0, 11.0, 15.0], [4.0, 8.0, 12.0, 16.0]]
  """
  @spec transpose(matrix4_tensor()) :: matrix4_tensor()
  def transpose(matrix) do
    Nx.transpose(matrix)
  end

  @doc """
  Matrix determinant using Nx operations.

  ## Examples

      iex> matrix = AriaMath.Matrix4.Core.identity()
      iex> AriaMath.Matrix4.Core.determinant(matrix)
      1.0
  """
  @spec determinant(matrix4_tensor()) :: float()
  def determinant(matrix) do
    Nx.LinAlg.determinant(matrix) |> Nx.to_number()
  end

  @doc """
  Matrix inversion using Nx operations with validity checking.

  Returns {inverted_matrix, is_valid} where:
  - inverted_matrix: inverse matrix if valid, or identity matrix if invalid
  - is_valid: true if matrix is invertible, false otherwise

  ## Examples

      iex> matrix = AriaMath.Matrix4.Core.identity()
      iex> {inverse, valid} = AriaMath.Matrix4.Core.invert(matrix)
      iex> valid
      true
      iex> AriaMath.Matrix4.Core.equal?(inverse, AriaMath.Matrix4.Core.identity())
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
  Matrix inversion using Nx operations (KHR Interactivity compatible).

  Returns the inverse matrix if invertible, or identity matrix if singular.
  This is a convenience wrapper around invert/1 that returns only the matrix.

  ## Examples

      iex> matrix = AriaMath.Matrix4.Core.identity()
      iex> inverse = AriaMath.Matrix4.Core.inverse(matrix)
      iex> AriaMath.Matrix4.Core.equal?(inverse, AriaMath.Matrix4.Core.identity())
      true
  """
  @spec inverse(matrix4_tensor()) :: matrix4_tensor()
  def inverse(matrix) do
    {inverse_matrix, _is_valid} = invert(matrix)
    inverse_matrix
  end

  @doc """
  Checks if two matrices are approximately equal within a tolerance.

  ## Examples

      iex> a = AriaMath.Matrix4.Core.identity()
      iex> b = AriaMath.Matrix4.Core.identity()
      iex> AriaMath.Matrix4.Core.equal?(a, b)
      true
  """
  @spec equal?(matrix4_tensor(), matrix4_tensor(), float()) :: boolean()
  def equal?(a, b, tolerance \\ 1.0e-6) do
    diff = Nx.subtract(a, b)
    max_diff = Nx.abs(diff) |> Nx.reduce_max() |> Nx.to_number()
    max_diff <= tolerance
  end

  @doc """
  Matrix transpose using Nx operations.

  ## Examples

      iex> m = AriaMath.Matrix4.Core.new([
      ...>   [1.0, 2.0, 3.0, 4.0],
      ...>   [5.0, 6.0, 7.0, 8.0],
      ...>   [9.0, 10.0, 11.0, 12.0],
      ...>   [13.0, 14.0, 15.0, 16.0]
      ...> ])
      iex> transposed = AriaMath.Matrix4.Core.transpose_nx(m)
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

      iex> m = AriaMath.Matrix4.Core.identity()
      iex> inv = AriaMath.Matrix4.Core.inverse_nx(m)
      iex> AriaMath.Matrix4.Core.equal?(m, inv)
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
  Convert a Matrix4 tensor to a list of tuples (row-wise).

  ## Examples

      iex> matrix = AriaMath.Matrix4.Core.identity()
      iex> AriaMath.Matrix4.Core.to_tuple_list(matrix)
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
      iex> matrix = AriaMath.Matrix4.Core.from_tuple_list(tuple_list)
      iex> AriaMath.Matrix4.Core.equal?(matrix, AriaMath.Matrix4.Core.identity())
      true
  """
  @spec from_tuple_list([tuple()]) :: matrix4_tensor()
  def from_tuple_list(tuple_list) do
    tuple_list
    |> Enum.map(&Tuple.to_list/1)
    |> Nx.tensor(type: :f32)
  end
end
