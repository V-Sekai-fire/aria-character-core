# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaMath.Vector3.Tensor do
  @moduledoc """
  Nx tensor-based Vector3 operations.

  This module provides the same API as Vector3.Core but uses Nx tensors
  for optimized numerical computing and potential GPU acceleration.
  """

  import Kernel, except: [length: 1]

  @type vector3_tensor :: Nx.Tensor.t()
  @type vector3_tuple :: {float(), float(), float()}

  @doc """
  Creates a new Vector3 tensor from three float components.

  ## Examples

      iex> AriaMath.Vector3.Tensor.new(1.0, 2.0, 3.0)
      #Nx.Tensor<
        f32[3]
        [1.0, 2.0, 3.0]
      >
  """
  @spec new(float(), float(), float()) :: vector3_tensor()
  def new(x, y, z) when is_number(x) and is_number(y) and is_number(z) do
    Nx.tensor([x / 1, y / 1, z / 1], type: :f32)
  end

  @doc """
  Batch cross product for multiple vector pairs.

  ## Examples

      iex> v1_batch = Nx.stack([AriaMath.Vector3.Tensor.new(1.0, 0.0, 0.0), AriaMath.Vector3.Tensor.new(0.0, 1.0, 0.0)])
      iex> v2_batch = Nx.stack([AriaMath.Vector3.Tensor.new(0.0, 1.0, 0.0), AriaMath.Vector3.Tensor.new(1.0, 0.0, 0.0)])
      iex> cross_results = AriaMath.Vector3.Tensor.cross_batch(v1_batch, v2_batch)
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
  Scale multiple vectors by a scalar factor using batch operations.

  ## Examples

      iex> vectors = Nx.stack([AriaMath.Vector3.Tensor.new(1.0, 2.0, 3.0), AriaMath.Vector3.Tensor.new(4.0, 5.0, 6.0)])
      iex> scaled = AriaMath.Vector3.Tensor.scale_batch(vectors, 2.0)
      iex> Nx.to_list(scaled)
      [[2.0, 4.0, 6.0], [8.0, 10.0, 12.0]]
  """
  @spec scale_batch(Nx.Tensor.t(), float()) :: Nx.Tensor.t()
  def scale_batch(vectors, factor) when is_number(factor) do
    Nx.multiply(vectors, factor)
  end

  @doc """
  Vector length using Nx operations for numerical stability.

  Implements `math/length` operation from KHR Interactivity spec.

  ## Examples

      iex> vec = AriaMath.Vector3.Tensor.new(3.0, 4.0, 0.0)
      iex> AriaMath.Vector3.Tensor.length(vec)
      5.0

      iex> vec = AriaMath.Vector3.Tensor.new(1.0, 1.0, 1.0)
      iex> AriaMath.Vector3.Tensor.length(vec)
      1.7320508075688772
  """
  @spec length(vector3_tensor()) :: float()
  def length(vec) do
    vec
    |> Nx.pow(2)
    |> Nx.sum()
    |> Nx.sqrt()
    |> Nx.to_number()
  end

  @doc """
  Batch vector length calculation for multiple vectors.

  ## Examples

      iex> vecs = Nx.tensor([[3.0, 4.0, 0.0], [1.0, 1.0, 1.0]])
      iex> AriaMath.Vector3.Tensor.length_batch(vecs)
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
  Vector normalization with validity checking using Nx operations.

  Implements `math/normalize` operation from KHR Interactivity spec.

  Returns {normalized_vector, is_valid} where:
  - normalized_vector: unit vector in same direction as input, or zero vector if invalid
  - is_valid: true if output has unit length, false otherwise

  ## Examples

      iex> vec = AriaMath.Vector3.Tensor.new(3.0, 4.0, 0.0)
      iex> {norm_vec, valid} = AriaMath.Vector3.Tensor.normalize(vec)
      iex> valid
      true
      iex> AriaMath.Vector3.Tensor.to_tuple(norm_vec)
      {0.6, 0.8, 0.0}

      iex> zero_vec = AriaMath.Vector3.Tensor.new(0.0, 0.0, 0.0)
      iex> {norm_vec, valid} = AriaMath.Vector3.Tensor.normalize(zero_vec)
      iex> valid
      false
  """
  @spec normalize(vector3_tensor()) :: {vector3_tensor(), boolean()}
  def normalize(vec) do
    len = vec
          |> Nx.pow(2)
          |> Nx.sum()
          |> Nx.sqrt()

    len_scalar = Nx.to_number(len)

    cond do
      # If length is zero, NaN, or positive infinity, return zero vector and false
      len_scalar == 0.0 or not is_finite_float(len_scalar) ->
        {Nx.tensor([0.0, 0.0, 0.0], type: :f32), false}

      # If length is positive finite number, normalize and return true
      len_scalar > 0.0 ->
        normalized = Nx.divide(vec, len)
        {normalized, true}

      # Default case
      true ->
        {Nx.tensor([0.0, 0.0, 0.0], type: :f32), false}
    end
  end

  @doc """
  Batch vector normalization for multiple vectors.

  ## Examples

      iex> vecs = Nx.tensor([[3.0, 4.0, 0.0], [1.0, 1.0, 1.0]])
      iex> {norm_vecs, valid_mask} = AriaMath.Vector3.Tensor.normalize_batch(vecs)
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

    # Normalize vectors
    normalized = Nx.divide(vecs, Nx.new_axis(safe_lengths, -1))

    # Zero out invalid vectors
    zero_vec = Nx.tensor([0.0, 0.0, 0.0])
    final_normalized = Nx.select(
      Nx.new_axis(valid_mask, -1),
      normalized,
      zero_vec
    )

    {final_normalized, valid_mask}
  end

  @doc """
  Component-wise dot product using Nx operations.

  Implements `math/dot` operation from KHR Interactivity spec.

  ## Examples

      iex> a = AriaMath.Vector3.Tensor.new(1.0, 2.0, 3.0)
      iex> b = AriaMath.Vector3.Tensor.new(4.0, 5.0, 6.0)
      iex> AriaMath.Vector3.Tensor.dot(a, b)
      32.0

      iex> a = AriaMath.Vector3.Tensor.new(1.0, 0.0, 0.0)
      iex> b = AriaMath.Vector3.Tensor.new(0.0, 1.0, 0.0)
      iex> AriaMath.Vector3.Tensor.dot(a, b)
      0.0
  """
  @spec dot(vector3_tensor(), vector3_tensor()) :: float()
  def dot(a, b) do
    a
    |> Nx.multiply(b)
    |> Nx.sum()
    |> Nx.to_number()
  end

  @doc """
  Batch dot product for multiple vector pairs.

  ## Examples

      iex> a_vecs = Nx.tensor([[1.0, 2.0, 3.0], [1.0, 0.0, 0.0]])
      iex> b_vecs = Nx.tensor([[4.0, 5.0, 6.0], [0.0, 1.0, 0.0]])
      iex> AriaMath.Vector3.Tensor.dot_batch(a_vecs, b_vecs)
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
  3D cross product using Nx operations.

  Implements `math/cross` operation from KHR Interactivity spec.

  ## Examples

      iex> a = AriaMath.Vector3.Tensor.new(1.0, 0.0, 0.0)
      iex> b = AriaMath.Vector3.Tensor.new(0.0, 1.0, 0.0)
      iex> result = AriaMath.Vector3.Tensor.cross(a, b)
      iex> AriaMath.Vector3.Tensor.to_tuple(result)
      {0.0, 0.0, 1.0}

      iex> a = AriaMath.Vector3.Tensor.new(1.0, 2.0, 3.0)
      iex> b = AriaMath.Vector3.Tensor.new(4.0, 5.0, 6.0)
      iex> result = AriaMath.Vector3.Tensor.cross(a, b)
      iex> AriaMath.Vector3.Tensor.to_tuple(result)
      {-3.0, 6.0, -3.0}
  """
  @spec cross(vector3_tensor(), vector3_tensor()) :: vector3_tensor()
  def cross(a, b) do
    ax = Nx.slice_along_axis(a, 0, 1, axis: 0)
    ay = Nx.slice_along_axis(a, 1, 1, axis: 0)
    az = Nx.slice_along_axis(a, 2, 1, axis: 0)

    bx = Nx.slice_along_axis(b, 0, 1, axis: 0)
    by = Nx.slice_along_axis(b, 1, 1, axis: 0)
    bz = Nx.slice_along_axis(b, 2, 1, axis: 0)

    cx = Nx.subtract(Nx.multiply(ay, bz), Nx.multiply(az, by))
    cy = Nx.subtract(Nx.multiply(az, bx), Nx.multiply(ax, bz))
    cz = Nx.subtract(Nx.multiply(ax, by), Nx.multiply(ay, bx))

    Nx.concatenate([cx, cy, cz], axis: 0)
  end


  @doc """
  Convert a Vector3 tuple to tensor format.

  ## Examples

      iex> AriaMath.Vector3.Tensor.from_tuple({1.0, 2.0, 3.0})
      #Nx.Tensor<
        f32[3]
        [1.0, 2.0, 3.0]
      >
  """
  @spec from_tuple(vector3_tuple()) :: vector3_tensor()
  def from_tuple({x, y, z}) when is_number(x) and is_number(y) and is_number(z) do
    Nx.tensor([x / 1, y / 1, z / 1], type: :f32)
  end

  @doc """
  Convert a Vector3 tensor to tuple format.

  ## Examples

      iex> vec = AriaMath.Vector3.Tensor.new(1.0, 2.0, 3.0)
      iex> AriaMath.Vector3.Tensor.to_tuple(vec)
      {1.0, 2.0, 3.0}
  """
  @spec to_tuple(vector3_tensor()) :: vector3_tuple()
  def to_tuple(vec) when is_struct(vec, Nx.Tensor) do
    [x, y, z] = Nx.to_list(vec)
    {x, y, z}
  end


  # Helper functions

  defp is_finite_float(x) when is_float(x) do
    not (x != x or x == :positive_infinity or x == :negative_infinity)
  end

  defp is_finite_float(_), do: false
end
