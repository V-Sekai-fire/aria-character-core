# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaMath.Vector3.Tensor.Batch do
  @moduledoc """
  Batch processing operations for Vector3 tensors.

  This module provides efficient batch operations for processing multiple
  vectors simultaneously, including batch cross product, addition, scaling,
  and normalization operations.
  """

  @doc """
  Batch cross product for multiple vector pairs.

  ## Examples

      iex> v1_batch = Nx.stack([AriaMath.Vector3.Tensor.Core.new(1.0, 0.0, 0.0), AriaMath.Vector3.Tensor.Core.new(0.0, 1.0, 0.0)])
      iex> v2_batch = Nx.stack([AriaMath.Vector3.Tensor.Core.new(0.0, 1.0, 0.0), AriaMath.Vector3.Tensor.Core.new(1.0, 0.0, 0.0)])
      iex> cross_results = AriaMath.Vector3.Tensor.Batch.cross_batch(v1_batch, v2_batch)
      iex> Nx.shape(cross_results)
      {2, 3}
  """
  @spec cross_batch(Nx.Tensor.t(), Nx.Tensor.t()) :: Nx.Tensor.t()
  def cross_batch(v1_batch, v2_batch) do
    # Extract components for batch operation
    x1 = Nx.slice_along_axis(v1_batch, 0, 1, axis: 1) |> Nx.squeeze(axes: [1])
    y1 = Nx.slice_along_axis(v1_batch, 1, 1, axis: 1) |> Nx.squeeze(axes: [1])
    z1 = Nx.slice_along_axis(v1_batch, 2, 1, axis: 1) |> Nx.squeeze(axes: [1])

    x2 = Nx.slice_along_axis(v2_batch, 0, 1, axis: 1) |> Nx.squeeze(axes: [1])
    y2 = Nx.slice_along_axis(v2_batch, 1, 1, axis: 1) |> Nx.squeeze(axes: [1])
    z2 = Nx.slice_along_axis(v2_batch, 2, 1, axis: 1) |> Nx.squeeze(axes: [1])

    # Cross product formula: (a2*b3 - a3*b2, a3*b1 - a1*b3, a1*b2 - a2*b1)
    cross_x = Nx.subtract(Nx.multiply(y1, z2), Nx.multiply(z1, y2))
    cross_y = Nx.subtract(Nx.multiply(z1, x2), Nx.multiply(x1, z2))
    cross_z = Nx.subtract(Nx.multiply(x1, y2), Nx.multiply(y1, x2))

    # Stack components back into vectors
    Nx.stack([cross_x, cross_y, cross_z], axis: 1)
  end

  @doc """
  Batch vector addition for multiple vector pairs.

  ## Examples

      iex> vectors_a = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
      iex> vectors_b = Nx.tensor([[1.0, 1.0, 1.0], [2.0, 2.0, 2.0]])
      iex> result = AriaMath.Vector3.Tensor.Batch.add_batch(vectors_a, vectors_b)
      iex> Nx.to_list(result)
      [[2.0, 3.0, 4.0], [6.0, 7.0, 8.0]]
  """
  @spec add_batch(Nx.Tensor.t(), Nx.Tensor.t()) :: Nx.Tensor.t()
  def add_batch(vectors_a, vectors_b) do
    Nx.add(vectors_a, vectors_b)
  end

  @doc """
  Scale multiple vectors by a scalar factor using batch operations.

  ## Examples

      iex> vectors = Nx.stack([AriaMath.Vector3.Tensor.Core.new(1.0, 2.0, 3.0), AriaMath.Vector3.Tensor.Core.new(4.0, 5.0, 6.0)])
      iex> scaled = AriaMath.Vector3.Tensor.Batch.scale_batch(vectors, 2.0)
      iex> Nx.to_list(scaled)
      [[2.0, 4.0, 6.0], [8.0, 10.0, 12.0]]
  """
  @spec scale_batch(Nx.Tensor.t(), float()) :: Nx.Tensor.t()
  def scale_batch(vectors, factor) when is_number(factor) do
    Nx.multiply(vectors, factor)
  end

  @doc """
  Batch vector length calculation for multiple vectors.

  ## Examples

      iex> vecs = Nx.tensor([[3.0, 4.0, 0.0], [1.0, 1.0, 1.0]])
      iex> AriaMath.Vector3.Tensor.Batch.length_batch(vecs)
      #Nx.Tensor<
        f32[2]
        [5.0, 1.7320508075688772]
      >
  """
  @spec length_batch(Nx.Tensor.t()) :: Nx.Tensor.t()
  def length_batch(vecs) do
    vecs
    |> Nx.pow(2)
    |> Nx.sum(axes: [-1])
    |> Nx.sqrt()
  end

  @doc """
  Batch vector normalization for multiple vectors.

  ## Examples

      iex> vecs = Nx.tensor([[3.0, 4.0, 0.0], [1.0, 1.0, 1.0]])
      iex> {norm_vecs, valid_mask} = AriaMath.Vector3.Tensor.Batch.normalize_batch(vecs)
      iex> Nx.to_list(valid_mask)
      [1, 1]  # Both vectors are valid
  """
  @spec normalize_batch(Nx.Tensor.t()) :: {Nx.Tensor.t(), Nx.Tensor.t()}
  def normalize_batch(vecs) do
    lengths = length_batch(vecs)

    # Create validity mask (1 for valid, 0 for invalid)
    valid_mask = Nx.greater(lengths, 0.0)

    # Avoid division by zero by replacing zero lengths with 1
    safe_lengths = Nx.select(valid_mask, lengths, 1.0)

    # Normalize vectors - reshape safe_lengths to broadcast correctly
    safe_lengths_reshaped = Nx.reshape(safe_lengths, {:auto, 1})
    normalized = Nx.divide(vecs, safe_lengths_reshaped)

    # Zero out invalid vectors using where instead of select
    valid_mask_reshaped = Nx.reshape(valid_mask, {:auto, 1})
    final_normalized = Nx.multiply(normalized, valid_mask_reshaped)

    {final_normalized, valid_mask}
  end

  @doc """
  Batch dot product for multiple vector pairs.

  ## Examples

      iex> a_vecs = Nx.tensor([[1.0, 2.0, 3.0], [1.0, 0.0, 0.0]])
      iex> b_vecs = Nx.tensor([[4.0, 5.0, 6.0], [0.0, 1.0, 0.0]])
      iex> AriaMath.Vector3.Tensor.Batch.dot_batch(a_vecs, b_vecs)
      #Nx.Tensor<
        f32[2]
        [32.0, 0.0]
      >
  """
  @spec dot_batch(Nx.Tensor.t(), Nx.Tensor.t()) :: Nx.Tensor.t()
  def dot_batch(a_vecs, b_vecs) do
    a_vecs
    |> Nx.multiply(b_vecs)
    |> Nx.sum(axes: [-1])
  end

  @doc """
  Batch vector magnitude calculation for multiple vectors.

  ## Examples

      iex> vectors = Nx.tensor([[3.0, 4.0, 0.0], [1.0, 0.0, 0.0]], type: :f32)
      iex> magnitudes = AriaMath.Vector3.Tensor.Batch.magnitude_batch(vectors)
      iex> Nx.to_list(magnitudes)
      [5.0, 1.0]
  """
  @spec magnitude_batch(Nx.Tensor.t()) :: Nx.Tensor.t()
  def magnitude_batch(vectors) do
    vectors
    |> Nx.pow(2)
    |> Nx.sum(axes: [-1])
    |> Nx.sqrt()
  end
end
