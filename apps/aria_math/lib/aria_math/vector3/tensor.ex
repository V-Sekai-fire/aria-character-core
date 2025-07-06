# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaMath.Vector3.Tensor do
  @moduledoc """
  Nx tensor-based Vector3 operations.

  This module provides the same API as Vector3.Core but uses Nx tensors
  for optimized numerical computing and potential GPU acceleration.

  Includes memory-optimized operations that prevent CUDA out-of-memory errors
  through intelligent chunking and automatic CPU fallback mechanisms.

  ## Architecture

  This module delegates to specialized submodules for focused functionality:

  - `AriaMath.Vector3.Tensor.Core` - Basic vector creation and conversion
  - `AriaMath.Vector3.Tensor.Math` - Mathematical operations (dot, cross, normalize)
  - `AriaMath.Vector3.Tensor.Batch` - Batch processing for multiple vectors
  - `AriaMath.Vector3.Tensor.Memory` - Memory-optimized operations with chunking
  - `AriaMath.Vector3.Tensor.Monitoring` - Memory monitoring and optimization utilities
  """

  import Kernel, except: [length: 1]

  alias AriaMath.Vector3.Tensor.{Core, Math, Batch, Memory, Monitoring}

  @type vector3_tensor :: Nx.Tensor.t()
  @type vector3_tuple :: {float(), float(), float()}

  # Core operations - delegate to Core module
  defdelegate new(x, y, z), to: Core
  defdelegate from_tuple(tuple), to: Core
  defdelegate to_tuple(vec), to: Core
  defdelegate length(vec), to: Core
  defdelegate magnitude(vector), to: Core

  # Mathematical operations - delegate to Math module
  defdelegate normalize(vec), to: Math
  defdelegate dot(a, b), to: Math
  defdelegate cross(a, b), to: Math
  defdelegate subtract(a, b), to: Math

  # Batch operations - delegate to Batch module
  defdelegate cross_batch(v1_batch, v2_batch), to: Batch
  defdelegate add_batch(vectors_a, vectors_b), to: Batch
  defdelegate scale_batch(vectors, factor), to: Batch
  defdelegate length_batch(vecs), to: Batch
  defdelegate normalize_batch(vecs), to: Batch
  defdelegate dot_batch(a_vecs, b_vecs), to: Batch
  defdelegate magnitude_batch(vectors), to: Batch

  # Memory-optimized operations - delegate to Memory module
  defdelegate cross_batch_safe(v1_batch, v2_batch), to: Memory
  defdelegate normalize_batch_safe(vectors), to: Memory
  defdelegate dot_batch_safe(a_vectors, b_vectors), to: Memory
  defdelegate add_batch_safe(vectors_a, vectors_b), to: Memory
  defdelegate scale_batch_safe(vectors, factor), to: Memory
  defdelegate magnitude_batch_safe(vectors), to: Memory
  defdelegate with_cpu_backend(operation_fn), to: Memory

  # Memory monitoring and optimization - delegate to Monitoring module
  defdelegate with_memory_monitoring(operation_fn), to: Monitoring
  defdelegate optimal_batch_size(tensor_shape), to: Monitoring
  defdelegate will_fit_in_memory?(tensor_shape), to: Monitoring
  defdelegate memory_stats(), to: Monitoring
  defdelegate estimate_memory_usage(operation, tensor_shape), to: Monitoring
end
