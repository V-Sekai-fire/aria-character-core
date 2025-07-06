# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaMath.Matrix4.Batch do
  @moduledoc """
  Batch Matrix4 operations using Nx tensors.

  This module provides batch processing operations for multiple matrices,
  including batch multiplication, inversion, and transformations.
  """

  alias AriaMath.Matrix4.Core

  @doc """
  Batch matrix multiplication for multiple matrix pairs.

  ## Examples

      iex> a_matrices = Nx.stack([AriaMath.Matrix4.Core.identity(), AriaMath.Matrix4.Core.identity()])
      iex> b_matrices = Nx.stack([AriaMath.Matrix4.Core.identity(), AriaMath.Matrix4.Core.identity()])
      iex> results = AriaMath.Matrix4.Batch.multiply_batch(a_matrices, b_matrices)
      iex> Nx.shape(results)
      {2, 4, 4}
  """
  @spec multiply_batch(Nx.Tensor.t(), Nx.Tensor.t()) :: Nx.Tensor.t()
  def multiply_batch(a_matrices, b_matrices) do
    # For batch matrix multiplication of {batch, 4, 4} tensors
    # Nx.dot automatically handles batch dimensions correctly
    # a_matrices: {batch, 4, 4}, b_matrices: {batch, 4, 4}
    # Result: {batch, 4, 4}
    Nx.dot(a_matrices, b_matrices)
  end

  @doc """
  Batch matrix transpose for multiple matrices.

  ## Examples

      iex> matrices = Nx.stack([AriaMath.Matrix4.Core.identity(), AriaMath.Matrix4.Core.identity()])
      iex> transposed = AriaMath.Matrix4.Batch.transpose_batch(matrices)
      iex> Nx.shape(transposed)
      {2, 4, 4}
  """
  @spec transpose_batch(Nx.Tensor.t()) :: Nx.Tensor.t()
  def transpose_batch(matrices) do
    Nx.transpose(matrices, axes: [0, 2, 1])
  end

  @doc """
  Batch matrix determinant for multiple matrices.

  ## Examples

      iex> matrices = Nx.stack([AriaMath.Matrix4.Core.identity(), AriaMath.Matrix4.Core.identity()])
      iex> dets = AriaMath.Matrix4.Batch.determinant_batch(matrices)
      iex> Nx.to_list(dets)
      [1.0, 1.0]
  """
  @spec determinant_batch(Nx.Tensor.t()) :: Nx.Tensor.t()
  def determinant_batch(matrices) do
    Nx.LinAlg.determinant(matrices)
  end

  @doc """
  Batch matrix inversion for multiple matrices.

  ## Examples

      iex> matrices = Nx.stack([AriaMath.Matrix4.Core.identity(), AriaMath.Matrix4.Core.identity()])
      iex> {inverses, valid_mask} = AriaMath.Matrix4.Batch.invert_batch(matrices)
      iex> Nx.to_list(valid_mask)
      [1, 1]  # Both matrices are invertible
  """
  @spec invert_batch(Nx.Tensor.t()) :: {Nx.Tensor.t(), Nx.Tensor.t()}
  def invert_batch(matrices) do
    dets = Nx.LinAlg.determinant(matrices)
    valid_mask = Nx.greater(Nx.abs(dets), 1.0e-10)

    # For invalid matrices, we'll replace with identity
    identity_batch = Nx.broadcast(Core.identity(), Nx.shape(matrices))

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
  Batch matrix equality check for multiple matrix pairs.

  ## Examples

      iex> m1_batch = Nx.stack([AriaMath.Matrix4.Core.identity(), AriaMath.Matrix4.Core.identity()])
      iex> m2_batch = Nx.stack([AriaMath.Matrix4.Core.identity(), AriaMath.Matrix4.Core.identity()])
      iex> results = AriaMath.Matrix4.Batch.equal_batch?(m1_batch, m2_batch)
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
  Batch matrix inversion using Nx operations.

  ## Examples

      iex> matrices = Nx.stack([AriaMath.Matrix4.Core.identity(), AriaMath.Matrix4.Core.identity()])
      iex> inverses = AriaMath.Matrix4.Batch.inverse_batch(matrices)
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
      iex> matrices = AriaMath.Matrix4.Batch.scaling_batch(scales)
      iex> Nx.shape(matrices)
      {2, 4, 4}
  """
  @spec scaling_batch(Nx.Tensor.t()) :: Nx.Tensor.t()
  def scaling_batch(scale_vectors) do
    batch_size = Nx.axis_size(scale_vectors, 0)

    # Create identity matrices for the batch
    identities = Nx.broadcast(Core.identity(), {batch_size, 4, 4})

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

      iex> m1_batch = Nx.stack([AriaMath.Matrix4.Core.identity(), AriaMath.Matrix4.Core.identity()])
      iex> m2_batch = Nx.stack([AriaMath.Matrix4.Core.scale(2.0), AriaMath.Matrix4.Core.scale(3.0)])
      iex> t_values = Nx.tensor([0.5, 0.5])
      iex> interpolated = AriaMath.Matrix4.Batch.lerp_batch(m1_batch, m2_batch, t_values)
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
  Extract translation vectors from batch of transformation matrices.

  ## Examples

      iex> trans_vec = AriaMath.Vector3.Tensor.new(1.0, 2.0, 3.0)
      iex> matrix = AriaMath.Matrix4.Tensor.translation(trans_vec)
      iex> matrices = Nx.stack([matrix, matrix])
      iex> translations = AriaMath.Matrix4.Batch.extract_translations_batch(matrices)
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

      iex> matrices = Nx.stack([AriaMath.Matrix4.Core.identity(), AriaMath.Matrix4.Core.identity()])
      iex> rotations = AriaMath.Matrix4.Batch.extract_rotations_batch(matrices)
      iex> Nx.shape(rotations)
      {2, 3, 3}
  """
  @spec extract_rotations_batch(Nx.Tensor.t()) :: Nx.Tensor.t()
  def extract_rotations_batch(matrices) do
    # Extract the upper-left 3x3 rotation part
    matrices[[.., 0..2, 0..2]]
  end
end
