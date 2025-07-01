# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaMath.Vector3.Tensor do
  @moduledoc """
  Nx tensor-based Vector3 operations.

  This module provides the same API as Vector3.Core but uses Nx tensors
  for optimized numerical computing and potential GPU acceleration.

  Includes memory-optimized operations that prevent CUDA out-of-memory errors
  through intelligent chunking and automatic CPU fallback mechanisms.
  """

  import Kernel, except: [length: 1]

  alias AriaMath.Memory

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
  Batch vector addition for multiple vector pairs.

  ## Examples

      iex> vectors_a = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]])
      iex> vectors_b = Nx.tensor([[1.0, 1.0, 1.0], [2.0, 2.0, 2.0]])
      iex> result = AriaMath.Vector3.Tensor.add_batch(vectors_a, vectors_b)
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

    # Normalize vectors - reshape safe_lengths to broadcast correctly
    safe_lengths_reshaped = Nx.reshape(safe_lengths, {:auto, 1})
    normalized = Nx.divide(vecs, safe_lengths_reshaped)

    # Zero out invalid vectors using where instead of select
    valid_mask_reshaped = Nx.reshape(valid_mask, {:auto, 1})
    final_normalized = Nx.multiply(normalized, valid_mask_reshaped)

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


  @doc """
  Batch vector magnitude calculation for multiple vectors.

  ## Examples

      iex> vectors = Nx.tensor([[3.0, 4.0, 0.0], [1.0, 0.0, 0.0]], type: :f32)
      iex> magnitudes = AriaMath.Vector3.Tensor.magnitude_batch(vectors)
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

  @doc """
  Single vector magnitude calculation.

  ## Examples

      iex> vector = AriaMath.Vector3.Tensor.new(3.0, 4.0, 0.0)
      iex> AriaMath.Vector3.Tensor.magnitude(vector)
      5.0
  """
  @spec magnitude(vector3_tensor()) :: float()
  def magnitude(vector) do
    vector
    |> Nx.pow(2)
    |> Nx.sum()
    |> Nx.sqrt()
    |> Nx.to_number()
  end

  # Memory-optimized operations

  @doc """
  Memory-optimized batch cross product with automatic chunking.

  Safely performs cross product on large batches of vectors while preventing memory overflow.

  ## Examples

      # Large batch that would normally cause OOM
      large_v1 = Nx.random_uniform({100000, 3})
      large_v2 = Nx.random_uniform({100000, 3})
      result = AriaMath.Vector3.Tensor.cross_batch_safe(large_v1, large_v2)
  """
  @spec cross_batch_safe(Nx.Tensor.t(), Nx.Tensor.t()) :: Nx.Tensor.t()
  def cross_batch_safe(v1_batch, v2_batch) do
    Memory.auto_chunk_process(
      Nx.stack([v1_batch, v2_batch]),
      :vector_compute,
      fn [v1_chunk, v2_chunk] ->
        cross_batch(v1_chunk, v2_chunk)
      end
    )
  end

  @doc """
  Memory-optimized batch vector normalization with automatic chunking.

  Safely normalizes large batches of vectors with memory monitoring.

  ## Examples

      large_vectors = Nx.random_uniform({1000000, 3})
      {normalized, valid_mask} = AriaMath.Vector3.Tensor.normalize_batch_safe(large_vectors)
  """
  @spec normalize_batch_safe(Nx.Tensor.t()) :: {Nx.Tensor.t(), Nx.Tensor.t()}
  def normalize_batch_safe(vectors) do
    tensor_shape = Nx.shape(vectors)

    if Memory.will_fit_in_memory?(:vector_compute, tensor_shape) do
      # Direct operation if it fits in memory
      normalize_batch(vectors)
    else
      # Use chunked processing
      batch_size = Memory.optimal_batch_size(:vector_compute, tensor_shape)

      # Process in chunks and combine results
      normalized_chunks = Memory.process_in_chunks(vectors, batch_size, fn chunk ->
        {norm_chunk, valid_chunk} = normalize_batch(chunk)
        {norm_chunk, valid_chunk}
      end)

      # Split the tuples and concatenate each part
      {normalized_results, valid_results} = Enum.unzip(normalized_chunks)

      normalized_final = Nx.concatenate(normalized_results, axis: 0)
      valid_final = Nx.concatenate(valid_results, axis: 0)

      {normalized_final, valid_final}
    end
  end

  @doc """
  Memory-optimized batch dot product with automatic chunking.

  Computes dot products for large batches of vector pairs safely.

  ## Examples

      large_a = Nx.random_uniform({500000, 3})
      large_b = Nx.random_uniform({500000, 3})
      dots = AriaMath.Vector3.Tensor.dot_batch_safe(large_a, large_b)
  """
  @spec dot_batch_safe(Nx.Tensor.t(), Nx.Tensor.t()) :: Nx.Tensor.t()
  def dot_batch_safe(a_vectors, b_vectors) do
    Memory.auto_chunk_process(
      Nx.stack([a_vectors, b_vectors]),
      :vector_compute,
      fn [a_chunk, b_chunk] ->
        dot_batch(a_chunk, b_chunk)
      end
    )
  end

  @doc """
  Memory-optimized batch vector addition with automatic chunking.

  Adds large batches of vector pairs while preventing memory overflow.

  ## Examples

      large_a = Nx.random_uniform({1000000, 3})
      large_b = Nx.random_uniform({1000000, 3})
      sums = AriaMath.Vector3.Tensor.add_batch_safe(large_a, large_b)
  """
  @spec add_batch_safe(Nx.Tensor.t(), Nx.Tensor.t()) :: Nx.Tensor.t()
  def add_batch_safe(vectors_a, vectors_b) do
    Memory.auto_chunk_process(
      Nx.stack([vectors_a, vectors_b]),
      :vector_compute,
      fn [a_chunk, b_chunk] ->
        add_batch(a_chunk, b_chunk)
      end
    )
  end

  @doc """
  Memory-optimized batch vector scaling with automatic chunking.

  Scales large batches of vectors by a scalar factor safely.

  ## Examples

      large_vectors = Nx.random_uniform({2000000, 3})
      scaled = AriaMath.Vector3.Tensor.scale_batch_safe(large_vectors, 2.5)
  """
  @spec scale_batch_safe(Nx.Tensor.t(), float()) :: Nx.Tensor.t()
  def scale_batch_safe(vectors, factor) do
    Memory.auto_chunk_process(
      vectors,
      :vector_compute,
      fn chunk -> scale_batch(chunk, factor) end
    )
  end

  @doc """
  Memory-optimized batch magnitude calculation with automatic chunking.

  Computes magnitudes for large batches of vectors safely.

  ## Examples

      large_vectors = Nx.random_uniform({3000000, 3})
      magnitudes = AriaMath.Vector3.Tensor.magnitude_batch_safe(large_vectors)
  """
  @spec magnitude_batch_safe(Nx.Tensor.t()) :: Nx.Tensor.t()
  def magnitude_batch_safe(vectors) do
    Memory.auto_chunk_process(
      vectors,
      :vector_compute,
      &magnitude_batch/1
    )
  end

  @doc """
  Monitor memory usage during vector operations.

  Wraps any vector operation with memory monitoring for debugging and optimization.

  ## Examples

      {result, memory_stats} = AriaMath.Vector3.Tensor.with_memory_monitoring(fn ->
        AriaMath.Vector3.Tensor.cross_batch(large_a, large_b)
      end)

      IO.puts("Memory used: \#{memory_stats.memory_used} bytes")
  """
  @spec with_memory_monitoring(function()) :: {any(), map()}
  def with_memory_monitoring(operation_fn) when is_function(operation_fn, 0) do
    Memory.monitor_memory(operation_fn)
  end

  @doc """
  Get optimal batch size for vector operations based on current memory availability.

  ## Examples

      batch_size = AriaMath.Vector3.Tensor.optimal_batch_size({100000, 3})
      IO.puts("Process \#{batch_size} vectors at a time for optimal memory usage")
  """
  @spec optimal_batch_size(tuple()) :: integer()
  def optimal_batch_size(tensor_shape) do
    Memory.optimal_batch_size(:vector_compute, tensor_shape)
  end

  @doc """
  Force vector operations to use CPU backend for memory-intensive operations.

  ## Examples

      # Force CPU for very large operations
      result = AriaMath.Vector3.Tensor.with_cpu_backend(fn ->
        AriaMath.Vector3.Tensor.cross_batch(huge_a, huge_b)
      end)
  """
  @spec with_cpu_backend(function()) :: any()
  def with_cpu_backend(operation_fn) when is_function(operation_fn, 0) do
    Memory.with_cpu_fallback(operation_fn)
  end

  # Helper functions

  defp is_finite_float(x) when is_float(x) do
    not (x != x or x == :positive_infinity or x == :negative_infinity)
  end

  defp is_finite_float(_), do: false
end
