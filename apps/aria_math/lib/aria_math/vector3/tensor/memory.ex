# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaMath.Vector3.Tensor.Memory do
  @moduledoc """
  Memory-optimized Vector3 tensor operations with automatic chunking.

  This module provides memory-safe versions of batch operations that prevent
  CUDA out-of-memory errors through intelligent chunking and automatic CPU
  fallback mechanisms.
  """

  alias AriaMath.Memory
  alias AriaMath.Vector3.Tensor.Batch

  @doc """
  Memory-optimized batch cross product with automatic chunking.

  Safely performs cross product on large batches of vectors while preventing memory overflow.

  ## Examples

      # Large batch that would normally cause OOM
      large_v1 = Nx.random_uniform({100000, 3})
      large_v2 = Nx.random_uniform({100000, 3})
      result = AriaMath.Vector3.Tensor.Memory.cross_batch_safe(large_v1, large_v2)
  """
  @spec cross_batch_safe(Nx.Tensor.t(), Nx.Tensor.t()) :: Nx.Tensor.t()
  def cross_batch_safe(v1_batch, v2_batch) do
    Memory.auto_chunk_process(
      Nx.stack([v1_batch, v2_batch]),
      :vector_compute,
      fn [v1_chunk, v2_chunk] ->
        Batch.cross_batch(v1_chunk, v2_chunk)
      end
    )
  end

  @doc """
  Memory-optimized batch vector normalization with automatic chunking.

  Safely normalizes large batches of vectors with memory monitoring.

  ## Examples

      large_vectors = Nx.random_uniform({1000000, 3})
      {normalized, valid_mask} = AriaMath.Vector3.Tensor.Memory.normalize_batch_safe(large_vectors)
  """
  @spec normalize_batch_safe(Nx.Tensor.t()) :: {Nx.Tensor.t(), Nx.Tensor.t()}
  def normalize_batch_safe(vectors) do
    tensor_shape = Nx.shape(vectors)

    if Memory.will_fit_in_memory?(:vector_compute, tensor_shape) do
      # Direct operation if it fits in memory
      Batch.normalize_batch(vectors)
    else
      # Use chunked processing
      batch_size = Memory.optimal_batch_size(:vector_compute, tensor_shape)

      # Process in chunks and combine results
      normalized_chunks = Memory.process_in_chunks(vectors, batch_size, fn chunk ->
        {norm_chunk, valid_chunk} = Batch.normalize_batch(chunk)
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
      dots = AriaMath.Vector3.Tensor.Memory.dot_batch_safe(large_a, large_b)
  """
  @spec dot_batch_safe(Nx.Tensor.t(), Nx.Tensor.t()) :: Nx.Tensor.t()
  def dot_batch_safe(a_vectors, b_vectors) do
    Memory.auto_chunk_process(
      Nx.stack([a_vectors, b_vectors]),
      :vector_compute,
      fn [a_chunk, b_chunk] ->
        Batch.dot_batch(a_chunk, b_chunk)
      end
    )
  end

  @doc """
  Memory-optimized batch vector addition with automatic chunking.

  Adds large batches of vector pairs while preventing memory overflow.

  ## Examples

      large_a = Nx.random_uniform({1000000, 3})
      large_b = Nx.random_uniform({1000000, 3})
      sums = AriaMath.Vector3.Tensor.Memory.add_batch_safe(large_a, large_b)
  """
  @spec add_batch_safe(Nx.Tensor.t(), Nx.Tensor.t()) :: Nx.Tensor.t()
  def add_batch_safe(vectors_a, vectors_b) do
    Memory.auto_chunk_process(
      Nx.stack([vectors_a, vectors_b]),
      :vector_compute,
      fn [a_chunk, b_chunk] ->
        Batch.add_batch(a_chunk, b_chunk)
      end
    )
  end

  @doc """
  Memory-optimized batch vector scaling with automatic chunking.

  Scales large batches of vectors by a scalar factor safely.

  ## Examples

      large_vectors = Nx.random_uniform({2000000, 3})
      scaled = AriaMath.Vector3.Tensor.Memory.scale_batch_safe(large_vectors, 2.5)
  """
  @spec scale_batch_safe(Nx.Tensor.t(), float()) :: Nx.Tensor.t()
  def scale_batch_safe(vectors, factor) do
    Memory.auto_chunk_process(
      vectors,
      :vector_compute,
      fn chunk -> Batch.scale_batch(chunk, factor) end
    )
  end

  @doc """
  Memory-optimized batch magnitude calculation with automatic chunking.

  Computes magnitudes for large batches of vectors safely.

  ## Examples

      large_vectors = Nx.random_uniform({3000000, 3})
      magnitudes = AriaMath.Vector3.Tensor.Memory.magnitude_batch_safe(large_vectors)
  """
  @spec magnitude_batch_safe(Nx.Tensor.t()) :: Nx.Tensor.t()
  def magnitude_batch_safe(vectors) do
    Memory.auto_chunk_process(
      vectors,
      :vector_compute,
      &Batch.magnitude_batch/1
    )
  end

  @doc """
  Force vector operations to use CPU backend for memory-intensive operations.

  ## Examples

      # Force CPU for very large operations
      result = AriaMath.Vector3.Tensor.Memory.with_cpu_backend(fn ->
        AriaMath.Vector3.Tensor.Batch.cross_batch(huge_a, huge_b)
      end)
  """
  @spec with_cpu_backend(function()) :: any()
  def with_cpu_backend(operation_fn) when is_function(operation_fn, 0) do
    Memory.with_cpu_fallback(operation_fn)
  end
end
