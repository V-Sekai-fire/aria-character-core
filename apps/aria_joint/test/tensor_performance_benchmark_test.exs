# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaJoint.TensorPerformanceBenchmarkTest do
  use ExUnit.Case

  alias AriaJoint.Transform.{Tensor, TensorGPU}
  alias AriaMath.Matrix4

  @moduletag :benchmark
  @moduletag timeout: 300_000  # 5 minutes for long benchmarks

  describe "tensor vs scalar performance comparison" do
    test "benchmark: batch transform operations (tensor vs scalar)" do
      # Use GPU-optimized batch sizes based on memory management
      sizes = [1000, 5000, 25000, 50000, 100000]

      for size <- sizes do
        # Use optimal batch size for GPU operations
        optimal_batch = AriaMath.Memory.optimal_batch_size(:hierarchy_propagation, {size, 4, 4})
        actual_size = min(size, optimal_batch)

        IO.puts("\n=== Batch Transform Operations (#{actual_size} bones, optimal batch: #{optimal_batch}) ===")

        # Pre-allocate tensors on GPU to minimize transfers
        {tensor_time_us, _} = :timer.tc(fn ->
          # Keep all operations on GPU
          joints_data = create_gpu_optimized_joint_data(actual_size)
          random_transforms = create_gpu_transforms(actual_size)

          # Single GPU operation with no CPU transfers
          _result = joints_data
          |> Tensor.apply_local_transforms_batch(random_transforms)
          |> Tensor.compute_global_transforms_batch()
        end)

        # Benchmark equivalent scalar operations
        {scalar_time_us, _} = :timer.tc(fn ->
          simulate_scalar_operations(actual_size)
        end)

        speedup = scalar_time_us / tensor_time_us

        IO.puts("Tensor time: #{tensor_time_us / 1000} ms")
        IO.puts("Scalar time: #{scalar_time_us / 1000} ms")
        IO.puts("Speedup: #{Float.round(speedup, 2)}x")
        IO.puts("Memory utilization: #{if actual_size == size, do: "✅ Full", else: "⚠️  Limited by GPU memory"}")

        if speedup > 1.0 do
          IO.puts("✅ Tensor is #{Float.round(speedup, 2)}x faster!")
        else
          IO.puts("❌ Scalar still faster at #{actual_size} bones")
        end
      end
    end

    test "benchmark: hierarchy propagation (tensor batch)" do
      # Use memory-optimized sizes
      sizes = [5000, 25000, 50000, 100000]

      for size <- sizes do
        # Check if size fits in GPU memory
        if AriaMath.Memory.will_fit_in_memory?(:hierarchy_propagation, {size, 4, 4}) do
          joints_data = create_gpu_optimized_hierarchical_data(size)

          {time_us, _} = :timer.tc(fn ->
            Tensor.compute_global_transforms_batch(joints_data)
          end)

          IO.puts("\n=== Hierarchy Propagation Tensor (#{size} bones) ===")
          IO.puts("Time: #{time_us / 1000} ms")
          IO.puts("Bones per second: #{size * 1_000_000 / time_us |> Float.round(2)}")
          IO.puts("Performance: #{if time_us < 5_000, do: "🚀 Excellent", else: "⚡ Good"}")
          IO.puts("GPU Memory: ✅ Optimized")
        else
          # Use chunked processing for oversized operations
          optimal_chunk = AriaMath.Memory.optimal_batch_size(:hierarchy_propagation, {size, 4, 4})

          {time_us, _} = :timer.tc(fn ->
            joints_data = create_hierarchical_tensor_data(optimal_chunk)
            Tensor.compute_global_transforms_batch(joints_data)
          end)

          IO.puts("\n=== Hierarchy Propagation Tensor (#{optimal_chunk}/#{size} bones) ===")
          IO.puts("Time: #{time_us / 1000} ms (chunked)")
          IO.puts("Bones per second: #{optimal_chunk * 1_000_000 / time_us |> Float.round(2)}")
          IO.puts("GPU Memory: ⚠️  Chunked due to size")
        end
      end
    end

    test "benchmark: position extraction from transforms" do
      sizes = [1000, 5000, 10000, 50000]

      for size <- sizes do
        joints_data = create_tensor_joint_data(size)

        {time_us, positions} = :timer.tc(fn ->
          Tensor.extract_positions_batch(joints_data)
        end)

        {shape_bones, _} = Nx.shape(positions)

        IO.puts("\n=== Position Extraction (#{size} bones) ===")
        IO.puts("Time: #{time_us / 1000} ms")
        IO.puts("Positions extracted: #{shape_bones}")
        IO.puts("Extractions per second: #{size * 1_000_000 / time_us |> Float.round(2)}")
      end
    end

    test "benchmark: batch coordinate transformations" do
      sizes = [1000, 5000, 10000]
      points_per_joint = [1, 10, 100]

      for size <- sizes do
        for num_points <- points_per_joint do
          joints_data = create_tensor_joint_data(size)

          # Create local points for each joint with explicit shape {size, num_points, 3}
          local_points =
            1..size
            |> Enum.map(fn _i ->
              1..num_points
              |> Enum.map(fn j ->
                [j * 0.1, j * 0.2, j * 0.3]
              end)
            end)
            |> Nx.tensor(type: :f32)

          # Verify shape before proceeding
          expected_shape = {size, num_points, 3}
          actual_shape = Nx.shape(local_points)

          if actual_shape == expected_shape do
            {time_us, _global_points} = :timer.tc(fn ->
              Tensor.to_global_batch(joints_data, local_points)
            end)

            total_points = size * num_points

            IO.puts("\n=== Coordinate Transform (#{size} bones, #{num_points} points/bone) ===")
            IO.puts("Time: #{time_us / 1000} ms")
            IO.puts("Total points: #{total_points}")
            IO.puts("Points per second: #{total_points * 1_000_000 / time_us |> Float.round(2)}")
          else
            IO.puts("\n❌ Shape mismatch: expected #{inspect expected_shape}, got #{inspect actual_shape}")
          end
        end
      end
    end

    test "benchmark: memory efficiency comparison" do
      sizes = [1000, 10000, 50000]

      for size <- sizes do
        joints_data = create_tensor_joint_data(size)

        # Benchmark multiple operations on the same tensor data (should be more memory efficient)
        {time_us, _} = :timer.tc(fn ->
          joints_data
          |> Tensor.extract_positions_batch()
          |> then(fn _positions ->
            joints_data
            |> Tensor.extract_rotations_batch()
            |> then(fn _rotations ->
              Tensor.compute_global_transforms_batch(joints_data)
            end)
          end)
        end)

        operations_per_sec = 3 * size * 1_000_000 / time_us

        IO.puts("\n=== Memory Efficiency Test (#{size} bones, 3 operations) ===")
        IO.puts("Time: #{time_us / 1000} ms")
        IO.puts("Operations per second: #{Float.round(operations_per_sec, 2)}")
        IO.puts("Memory efficiency: #{if time_us < size * 10, do: "🎯 Excellent", else: "📊 Good"}")
      end
    end

    test "benchmark: GPU-optimized operations (TensorGPU vs Tensor)" do
      # Test larger sizes where GPU should excel
      sizes = [10000, 50000, 100000]

      for size <- sizes do
        # Create GPU-optimized data
        transforms_list = create_transform_matrix_list(size)

        # Test old Tensor implementation
        {tensor_time_us, _} = :timer.tc(fn ->
          joints_data = create_tensor_joint_data(size)
          Tensor.compute_global_transforms_batch(joints_data)
        end)

        # Test new TensorGPU implementation
        {gpu_time_us, _} = :timer.tc(fn ->
          gpu_joint_data = TensorGPU.create_gpu_joint_data(transforms_list)
          TensorGPU.batch_hierarchy_propagation_gpu(
            gpu_joint_data.local_transforms,
            gpu_joint_data.parent_indices
          )
        end)

        speedup = tensor_time_us / gpu_time_us

        IO.puts("\n=== GPU Optimization Test (#{size} bones) ===")
        IO.puts("Old Tensor time: #{tensor_time_us / 1000} ms")
        IO.puts("GPU Tensor time: #{gpu_time_us / 1000} ms")
        IO.puts("GPU Speedup: #{Float.round(speedup, 2)}x")

        if speedup > 1.0 do
          IO.puts("✅ GPU implementation is #{Float.round(speedup, 2)}x faster!")
        else
          IO.puts("⚠️  GPU implementation is slower at #{size} bones")
        end
      end
    end

    test "benchmark: complete GPU pipeline vs CPU pipeline" do
      # Test complete processing pipeline
      sizes = [25000, 50000, 100000]

      for size <- sizes do
        transforms_list = create_transform_matrix_list(size)

        # CPU-based pipeline
        {cpu_time_us, _} = :timer.tc(fn ->
          joints_data = create_tensor_joint_data(size)

          # Complete processing pipeline
          _global_transforms = Tensor.compute_global_transforms_batch(joints_data)
          _positions = Tensor.extract_positions_batch(joints_data)
          _rotations = Tensor.extract_rotations_batch(joints_data)
        end)

        # GPU-based pipeline
        {gpu_time_us, _} = :timer.tc(fn ->
          gpu_joint_data = TensorGPU.create_gpu_joint_data(transforms_list)
          TensorGPU.gpu_joint_pipeline(gpu_joint_data)
        end)

        speedup = cpu_time_us / gpu_time_us

        IO.puts("\n=== Complete Pipeline Test (#{size} bones) ===")
        IO.puts("CPU pipeline time: #{cpu_time_us / 1000} ms")
        IO.puts("GPU pipeline time: #{gpu_time_us / 1000} ms")
        IO.puts("Pipeline speedup: #{Float.round(speedup, 2)}x")
        IO.puts("Bones per second (GPU): #{size * 1_000_000 / gpu_time_us |> Float.round(2)}")

        if speedup > 1.0 do
          IO.puts("🚀 GPU pipeline is #{Float.round(speedup, 2)}x faster!")
        else
          IO.puts("⚠️  GPU pipeline needs optimization")
        end
      end
    end
  end

  # Helper functions for creating test data

  defp create_tensor_joint_data(size) do
    # Create random joint transforms
    local_transforms = create_random_transforms(size)
    global_transforms = local_transforms  # Start with same as local

    # Create simple parent hierarchy (chain)
    parent_indices = Enum.map(0..(size-1), fn
      0 -> -1  # Root has no parent
      i -> i - 1  # Each joint's parent is the previous one
    end)
    |> Nx.tensor(type: :s32)

    # Create dummy dirty flags
    dirty_flags = Nx.broadcast(Nx.tensor(0, type: :u8), {size})

    %{
      local_transforms: local_transforms,
      global_transforms: global_transforms,
      parent_indices: parent_indices,
      dirty_flags: dirty_flags
    }
  end

  defp create_hierarchical_tensor_data(size) do
    # Create more complex hierarchy with branching
    local_transforms = create_random_transforms(size)
    global_transforms = local_transforms

    # Create branching hierarchy
    parent_indices = Enum.map(0..(size-1), fn
      0 -> -1  # Root
      i when i < 10 -> 0  # First 10 children of root
      i -> rem(i, 10)  # Others branch from first 10
    end)
    |> Nx.tensor(type: :s32)

    dirty_flags = Nx.broadcast(Nx.tensor(1, type: :u8), {size})  # Mark as dirty

    %{
      local_transforms: local_transforms,
      global_transforms: global_transforms,
      parent_indices: parent_indices,
      dirty_flags: dirty_flags
    }
  end

  defp create_random_transforms(size) do
    # Create random 4x4 transformation matrices directly as tensors
    Enum.map(1..size, fn i ->
      # Create random translation matrix as list of lists
      x = i * 0.1
      y = :rand.uniform() * 0.5
      z = :rand.uniform() * 0.5

      [
        [1.0, 0.0, 0.0, x],
        [0.0, 1.0, 0.0, y],
        [0.0, 0.0, 1.0, z],
        [0.0, 0.0, 0.0, 1.0]
      ]
    end)
    |> Nx.tensor(type: :f32)
  end

  defp simulate_scalar_operations(size) do
    # Simulate the cost of scalar operations equivalent to tensor batch operations
    # This is a rough approximation of the work done by scalar joint operations
    transforms = Enum.map(1..size, fn i ->
      Matrix4.translation({i * 0.1, 0.0, 0.0})
    end)

    # Simulate setting local transforms and computing global transforms
    Enum.reduce(transforms, [], fn transform, acc ->
      # Simulate the work of setting local transform and computing global
      _result = Matrix4.multiply(transform, Matrix4.identity())
      [transform | acc]
    end)
  end

  # GPU-optimized helper functions for better performance

  defp create_gpu_optimized_joint_data(size) do
    # Pre-allocate tensors directly on GPU with optimal memory layout
    local_transforms = create_gpu_transforms(size)
    global_transforms = local_transforms  # Start with same as local

    # Create parent hierarchy optimized for GPU processing
    parent_indices = Enum.map(0..(size-1), fn
      0 -> -1  # Root has no parent
      i -> i - 1  # Each joint's parent is the previous one
    end)
    |> Nx.tensor(type: :s32)
    |> Nx.backend_copy({Torchx.Backend, device: :cuda})

    # Create dirty flags on GPU
    dirty_flags = Nx.broadcast(Nx.tensor(0, type: :u8), {size})
    |> Nx.backend_copy({Torchx.Backend, device: :cuda})

    %{
      local_transforms: local_transforms,
      global_transforms: global_transforms,
      parent_indices: parent_indices,
      dirty_flags: dirty_flags
    }
  end

  defp create_gpu_optimized_hierarchical_data(size) do
    # Create branching hierarchy optimized for GPU
    local_transforms = create_gpu_transforms(size)
    global_transforms = local_transforms

    # Create more complex branching hierarchy
    parent_indices = Enum.map(0..(size-1), fn
      0 -> -1  # Root
      i when i < 100 -> 0  # First 100 children of root (more GPU-friendly branches)
      i -> rem(i, 100)  # Others branch from first 100
    end)
    |> Nx.tensor(type: :s32)
    |> Nx.backend_copy({Torchx.Backend, device: :cuda})

    dirty_flags = Nx.broadcast(Nx.tensor(1, type: :u8), {size})  # Mark as dirty
    |> Nx.backend_copy({Torchx.Backend, device: :cuda})

    %{
      local_transforms: local_transforms,
      global_transforms: global_transforms,
      parent_indices: parent_indices,
      dirty_flags: dirty_flags
    }
  end

  defp create_gpu_transforms(size) do
    # Create optimized transforms directly on GPU
    # Use more GPU-friendly generation pattern
    transforms_data = for i <- 1..size do
      # Create translation matrix with better GPU memory access patterns
      x = i * 0.001  # Smaller increments for better precision
      y = :rand.uniform() * 0.001
      z = :rand.uniform() * 0.001

      [
        [1.0, 0.0, 0.0, x],
        [0.0, 1.0, 0.0, y],
        [0.0, 0.0, 1.0, z],
        [0.0, 0.0, 0.0, 1.0]
      ]
    end

    transforms_data
    |> Nx.tensor(type: :f32)
    |> Nx.backend_copy({Torchx.Backend, device: :cuda})
  end

  defp create_transform_matrix_list(size) do
    # Create list of 4x4 transformation matrices for TensorGPU
    for i <- 1..size do
      x = i * 0.001
      y = :rand.uniform() * 0.001
      z = :rand.uniform() * 0.001

      [
        [1.0, 0.0, 0.0, x],
        [0.0, 1.0, 0.0, y],
        [0.0, 0.0, 1.0, z],
        [0.0, 0.0, 0.0, 1.0]
      ]
    end
  end
end
