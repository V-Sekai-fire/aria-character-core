#!/usr/bin/env elixir

# Quick GPU optimization test script
Mix.install([
  {:nx, "~> 0.10"},
  {:torchx, "~> 0.10"}
])

defmodule GPUOptimizationTest do
  def run do
    IO.puts("=== GPU Optimization Test ===")

    # Check backend configuration
    backend = Nx.default_backend()
    IO.puts("Default backend: #{inspect(backend)}")

    # Test basic GPU operations
    test_basic_gpu_operations()

    # Test memory allocation
    test_gpu_memory_allocation()

    # Test batch operations
    test_batch_matrix_operations()
  end

  defp test_basic_gpu_operations do
    IO.puts("\n--- Basic GPU Operations ---")

    try do
      # Simple tensor creation
      a = Nx.tensor([[1.0, 2.0], [3.0, 4.0]], type: :f32)
      b = Nx.tensor([[5.0, 6.0], [7.0, 8.0]], type: :f32)

      # Test if tensors are on GPU
      IO.puts("Tensor A backend: #{inspect(a.__struct__)}")

      # Basic operations
      {time_us, result} = :timer.tc(fn ->
        Nx.dot(a, b)
      end)

      IO.puts("Matrix multiplication: #{time_us / 1000} ms")
      IO.puts("Result: #{inspect(Nx.to_list(result))}")

    rescue
      error ->
        IO.puts("❌ GPU operations failed: #{inspect(error)}")
    end
  end

  defp test_gpu_memory_allocation do
    IO.puts("\n--- GPU Memory Allocation ---")

    try do
      # Test different sizes
      sizes = [100, 1000, 10000]

      for size <- sizes do
        {time_us, _tensor} = :timer.tc(fn ->
          Nx.random_uniform({size, size}, type: :f32)
        end)

        memory_mb = size * size * 4 / 1024 / 1024
        IO.puts("Size #{size}x#{size} (#{Float.round(memory_mb, 2)} MB): #{time_us / 1000} ms")
      end

    rescue
      error ->
        IO.puts("❌ Memory allocation failed: #{inspect(error)}")
    end
  end

  defp test_batch_matrix_operations do
    IO.puts("\n--- Batch Matrix Operations ---")

    try do
      batch_sizes = [10, 100, 1000]

      for batch_size <- batch_sizes do
        # Create batch of 4x4 matrices
        matrices_a = Nx.random_uniform({batch_size, 4, 4}, type: :f32)
        matrices_b = Nx.random_uniform({batch_size, 4, 4}, type: :f32)

        {time_us, _result} = :timer.tc(fn ->
          # Test batched matrix multiplication
          Nx.dot(matrices_a, [3], [0], matrices_b, [2], [0])
        end)

        operations_per_sec = batch_size * 1_000_000 / time_us
        IO.puts("Batch size #{batch_size}: #{time_us / 1000} ms (#{Float.round(operations_per_sec, 2)} ops/sec)")
      end

    rescue
      error ->
        IO.puts("❌ Batch operations failed: #{inspect(error)}")
    end
  end
end

GPUOptimizationTest.run()
