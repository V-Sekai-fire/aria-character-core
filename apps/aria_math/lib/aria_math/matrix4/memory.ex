# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaMath.Matrix4.Memory do
  @moduledoc """
  Memory-optimized Matrix4 operations using Nx tensors.

  This module provides memory-safe operations with automatic chunking
  and CPU fallback mechanisms to prevent CUDA out-of-memory errors.
  """

  alias AriaMath.Memory
  alias AriaMath.Matrix4.Batch

  @doc """
  Memory-optimized batch matrix multiplication with automatic chunking.

  Safely multiplies large batches of matrices while preventing memory overflow.

  ## Examples

      large_a = Nx.random_uniform({50000, 4, 4})
      large_b = Nx.random_uniform({50000, 4, 4})
      result = AriaMath.Matrix4.Memory.multiply_batch_safe(large_a, large_b)
  """
  @spec multiply_batch_safe(Nx.Tensor.t(), Nx.Tensor.t()) :: Nx.Tensor.t()
  def multiply_batch_safe(matrices_a, matrices_b) do
    Memory.auto_chunk_process(
      Nx.stack([matrices_a, matrices_b]),
      :matrix_multiply,
      fn [a_chunk, b_chunk] ->
        Batch.multiply_batch(a_chunk, b_chunk)
      end
    )
  end

  @doc """
  Memory-optimized batch point transformation for multiple transform matrices.

  Transforms points using multiple different transformation matrices safely,
  preventing CUDA out-of-memory errors through intelligent chunking.

  ## Examples

      # transforms: {num_joints, 4, 4}
      # points: {num_joints, num_points, 3}
      global_points = AriaMath.Matrix4.Memory.transform_points_batch_multi_safe(transforms, points)
  """
  @spec transform_points_batch_multi_safe(Nx.Tensor.t(), Nx.Tensor.t()) :: Nx.Tensor.t()
  def transform_points_batch_multi_safe(transforms, points) do
    {num_joints, num_points, _} = Nx.shape(points)

    # Be much more conservative with memory usage to prevent CUDA OOM
    # The matrix operations can create large intermediate tensors
    total_elements = num_joints * num_points

    # Use aggressive chunking for any reasonably large operation
    if total_elements > 50_000 do  # Much lower threshold
      # Use small chunk sizes to prevent memory explosions
      # Base chunk size on both total elements and available memory
      base_chunk_size = cond do
        total_elements > 1_000_000 -> 64   # Very large: tiny chunks
        total_elements > 500_000 -> 128    # Large: small chunks
        total_elements > 100_000 -> 256    # Medium: modest chunks
        true -> 512                        # Smaller: reasonable chunks
      end

      # Further reduce chunk size if we have many points per joint
      chunk_size = if num_points > 50 do
        max(32, div(base_chunk_size, 2))
      else
        base_chunk_size
      end

      # Process in chunks with conservative memory usage
      0..(num_joints - 1)
      |> Enum.chunk_every(chunk_size)
      |> Enum.map(fn chunk_indices ->
        start_idx = hd(chunk_indices)
        actual_chunk_size = length(chunk_indices)

        # Extract chunk of transforms and points
        transforms_chunk = Nx.slice_along_axis(transforms, start_idx, actual_chunk_size, axis: 0)
        points_chunk = Nx.slice_along_axis(points, start_idx, actual_chunk_size, axis: 0)

        # Transform this chunk with memory monitoring
        try do
          transform_points_batch_multi(transforms_chunk, points_chunk)
        catch
          :error, %RuntimeError{message: message} = error ->
            if String.contains?(message, "out of memory") do
              # Fallback to CPU for this chunk
              Memory.with_cpu_fallback(fn ->
                transform_points_batch_multi(transforms_chunk, points_chunk)
              end)
            else
              reraise error, __STACKTRACE__
            end
        end
      end)
      |> Nx.concatenate(axis: 0)
    else
      # Even for smaller operations, wrap in error handling
      try do
        transform_points_batch_multi(transforms, points)
      catch
        :error, %RuntimeError{message: message} = error ->
          if String.contains?(message, "out of memory") do
            # Fallback to chunked processing
            transform_points_batch_multi_safe_chunked(transforms, points, 128)
          else
            reraise error, __STACKTRACE__
          end
      end
    end
  end

  # Helper function for emergency chunked processing
  @spec transform_points_batch_multi_safe_chunked(Nx.Tensor.t(), Nx.Tensor.t(), integer()) :: Nx.Tensor.t()
  defp transform_points_batch_multi_safe_chunked(transforms, points, chunk_size) do
    {num_joints, _, _} = Nx.shape(points)

    0..(num_joints - 1)
    |> Enum.chunk_every(chunk_size)
    |> Enum.map(fn chunk_indices ->
      start_idx = hd(chunk_indices)
      actual_chunk_size = length(chunk_indices)

      # Extract chunk of transforms and points
      transforms_chunk = Nx.slice_along_axis(transforms, start_idx, actual_chunk_size, axis: 0)
      points_chunk = Nx.slice_along_axis(points, start_idx, actual_chunk_size, axis: 0)

      # Use CPU fallback for safety
      Memory.with_cpu_fallback(fn ->
        transform_points_batch_multi(transforms_chunk, points_chunk)
      end)
    end)
    |> Nx.concatenate(axis: 0)
  end

  @doc """
  Transform multiple point sets using multiple matrices with batch operations.

  Each matrix transforms its corresponding set of points. This is different from
  transform_points_batch which uses a single matrix for all points.

  ## Examples

      iex> matrices = Nx.stack([AriaMath.Matrix4.Core.identity(), AriaMath.Matrix4.Core.translation_nx({1.0, 0.0, 0.0})])
      iex> points = Nx.tensor([[[0.0, 0.0, 0.0], [1.0, 1.0, 1.0]], [[2.0, 2.0, 2.0], [3.0, 3.0, 3.0]]], type: :f32)
      iex> transformed = AriaMath.Matrix4.Memory.transform_points_batch_multi(matrices, points)
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

    # Reshape for batch matrix multiplication
    # homogeneous_points: {num_matrices, num_points, 4}
    # matrices: {num_matrices, 4, 4}

    # We want to multiply each matrix with its corresponding points
    # Use Nx.dot with proper batching - contract the inner dimensions
    transformed_homo = Nx.dot(homogeneous_points, [2], matrices, [1])

    # Extract x, y, z components (drop w component)
    Nx.slice_along_axis(transformed_homo, 0, 3, axis: 2)
  end

  @doc """
  Memory-optimized point transformation with automatic chunking.

  Transforms large numbers of points while preventing memory overflow.

  ## Examples

      # Transform 1 million points safely
      large_matrices = Nx.random_uniform({10000, 4, 4})
      large_points = Nx.random_uniform({10000, 100, 3})
      result = AriaMath.Matrix4.Memory.transform_points_batch_safe(large_matrices, large_points)
  """
  @spec transform_points_batch_safe(Nx.Tensor.t(), Nx.Tensor.t()) :: Nx.Tensor.t()
  def transform_points_batch_safe(matrices, points) do
    tensor_shape = Nx.shape(points)

    if Memory.will_fit_in_memory?(:coordinate_transform, tensor_shape) do
      # Direct operation if it fits in memory
      transform_points_batch_multi(matrices, points)
    else
      # Use chunked processing
      batch_size = Memory.optimal_batch_size(:coordinate_transform, tensor_shape)

      # Chunk both matrices and points together
      matrices_chunks = Memory.process_in_chunks(matrices, batch_size, fn chunk -> chunk end)
      points_chunks = Memory.process_in_chunks(points, batch_size, fn chunk -> chunk end)

      # Process each chunk pair and concatenate results
      Enum.zip(matrices_chunks, points_chunks)
      |> Enum.map(fn {matrix_chunk, point_chunk} ->
        transform_points_batch_multi(matrix_chunk, point_chunk)
      end)
      |> Nx.concatenate(axis: 0)
    end
  end

  @doc """
  Memory-optimized batch inversion with automatic fallback.

  Safely inverts large batches of matrices with memory monitoring and CPU fallback.

  ## Examples

      large_matrices = Nx.random_uniform({50000, 4, 4})
      {inverses, valid_mask} = AriaMath.Matrix4.Memory.invert_batch_safe(large_matrices)
  """
  @spec invert_batch_safe(Nx.Tensor.t()) :: {Nx.Tensor.t(), Nx.Tensor.t()}
  def invert_batch_safe(matrices) do
    tensor_shape = Nx.shape(matrices)

    if Memory.will_fit_in_memory?(:matrix_multiply, tensor_shape) do
      # Direct operation if it fits in memory
      Batch.invert_batch(matrices)
    else
      # Use CPU fallback for very large operations
      Memory.with_cpu_fallback(fn ->
        Batch.invert_batch(matrices)
      end)
    end
  end

  @doc """
  Memory-optimized batch scaling matrix creation.

  Creates scaling matrices from large batches of scale vectors with memory safety.

  ## Examples

      large_scales = Nx.random_uniform({100000, 3})
      matrices = AriaMath.Matrix4.Memory.scaling_batch_safe(large_scales)
  """
  @spec scaling_batch_safe(Nx.Tensor.t()) :: Nx.Tensor.t()
  def scaling_batch_safe(scale_vectors) do
    Memory.auto_chunk_process(
      scale_vectors,
      :matrix_multiply,
      &Batch.scaling_batch/1
    )
  end

  @doc """
  Memory-optimized matrix interpolation with chunked processing.

  Performs linear interpolation between large batches of matrices safely.

  ## Examples

      large_m1 = Nx.random_uniform({100000, 4, 4})
      large_m2 = Nx.random_uniform({100000, 4, 4})
      t_values = Nx.random_uniform({100000})
      result = AriaMath.Matrix4.Memory.lerp_batch_safe(large_m1, large_m2, t_values)
  """
  @spec lerp_batch_safe(Nx.Tensor.t(), Nx.Tensor.t(), Nx.Tensor.t()) :: Nx.Tensor.t()
  def lerp_batch_safe(m1_batch, m2_batch, t_batch) do
    # Stack all inputs for coordinated chunking
    stacked_inputs = Nx.stack([m1_batch, m2_batch])

    Memory.auto_chunk_process(
      stacked_inputs,
      :matrix_multiply,
      fn [m1_chunk, m2_chunk] ->
        # Get corresponding t values for this chunk
        chunk_size = Nx.axis_size(m1_chunk, 0)
        t_chunk = Nx.slice_along_axis(t_batch, 0, chunk_size, axis: 0)
        Batch.lerp_batch(m1_chunk, m2_chunk, t_chunk)
      end
    )
  end

  @doc """
  Monitor memory usage during matrix operations.

  Wraps any matrix operation with memory monitoring for debugging and optimization.

  ## Examples

      {result, memory_stats} = AriaMath.Matrix4.Memory.with_memory_monitoring(fn ->
        AriaMath.Matrix4.Batch.multiply_batch(large_a, large_b)
      end)

      Logger.debug("Memory used: \#{memory_stats.memory_used} bytes")
  """
  @spec with_memory_monitoring(function()) :: {any(), map()}
  def with_memory_monitoring(operation_fn) when is_function(operation_fn, 0) do
    Memory.monitor_memory(operation_fn)
  end

  @doc """
  Get optimal batch size for matrix operations based on current memory availability.

  ## Examples

      batch_size = AriaMath.Matrix4.Memory.optimal_batch_size({10000, 4, 4})
      Logger.debug("Process \#{batch_size} matrices at a time for optimal memory usage")
  """
  @spec optimal_batch_size(tuple()) :: integer()
  def optimal_batch_size(tensor_shape) do
    Memory.optimal_batch_size(:matrix_multiply, tensor_shape)
  end

  @doc """
  Force matrix operations to use CPU backend for memory-intensive operations.

  ## Examples

      # Force CPU for very large operations
      result = AriaMath.Matrix4.Memory.with_cpu_backend(fn ->
        AriaMath.Matrix4.Batch.multiply_batch(huge_a, huge_b)
      end)
  """
  @spec with_cpu_backend(function()) :: any()
  def with_cpu_backend(operation_fn) when is_function(operation_fn, 0) do
    Memory.with_cpu_fallback(operation_fn)
  end
end
