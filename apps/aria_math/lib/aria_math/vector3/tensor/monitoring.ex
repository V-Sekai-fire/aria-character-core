# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaMath.Vector3.Tensor.Monitoring do
  @moduledoc """
  Memory monitoring and optimization utilities for Vector3 tensor operations.

  This module provides tools for monitoring memory usage, calculating optimal
  batch sizes, and debugging memory-related issues during vector operations.
  """

  alias AriaMath.Memory

  @doc """
  Monitor memory usage during vector operations.

  Wraps any vector operation with memory monitoring for debugging and optimization.

  ## Examples

      {result, memory_stats} = AriaMath.Vector3.Tensor.Monitoring.with_memory_monitoring(fn ->
        AriaMath.Vector3.Tensor.Batch.cross_batch(large_a, large_b)
      end)

      Logger.debug("Memory used: \#{memory_stats.memory_used} bytes")
  """
  @spec with_memory_monitoring(function()) :: {any(), map()}
  def with_memory_monitoring(operation_fn) when is_function(operation_fn, 0) do
    Memory.monitor_memory(operation_fn)
  end

  @doc """
  Get optimal batch size for vector operations based on current memory availability.

  ## Examples

      batch_size = AriaMath.Vector3.Tensor.Monitoring.optimal_batch_size({100000, 3})
      Logger.debug("Process \#{batch_size} vectors at a time for optimal memory usage")
  """
  @spec optimal_batch_size(tuple()) :: integer()
  def optimal_batch_size(tensor_shape) do
    Memory.optimal_batch_size(:vector_compute, tensor_shape)
  end

  @doc """
  Check if a tensor operation will fit in available memory.

  ## Examples

      if AriaMath.Vector3.Tensor.Monitoring.will_fit_in_memory?({1000000, 3}) do
        # Safe to process directly
        result = AriaMath.Vector3.Tensor.Batch.normalize_batch(large_vectors)
      else
        # Use chunked processing
        result = AriaMath.Vector3.Tensor.Memory.normalize_batch_safe(large_vectors)
      end
  """
  @spec will_fit_in_memory?(tuple()) :: boolean()
  def will_fit_in_memory?(tensor_shape) do
    Memory.will_fit_in_memory?(:vector_compute, tensor_shape)
  end

  @doc """
  Get current memory usage statistics for debugging.

  ## Examples

      stats = AriaMath.Vector3.Tensor.Monitoring.memory_stats()
      Logger.debug("Available memory: \#{stats.available_memory} bytes")
      Logger.debug("Memory pressure: \#{stats.memory_pressure}")
  """
  @spec memory_stats() :: map()
  def memory_stats do
    Memory.get_memory_info()
  end

  @doc """
  Estimate memory requirements for a vector operation.

  ## Examples

      memory_needed = AriaMath.Vector3.Tensor.Monitoring.estimate_memory_usage(:cross_batch, {100000, 3})
      Logger.debug("Cross product will need approximately \#{memory_needed} bytes")
  """
  @spec estimate_memory_usage(atom(), tuple()) :: integer()
  def estimate_memory_usage(operation, tensor_shape) do
    Memory.estimate_memory_usage(operation, tensor_shape)
  end
end
