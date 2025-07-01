# Comprehensive Nx performance analysis to find when tensors beat scalars

defmodule NxPerformanceAnalysis do
  def run_full_analysis do
    IO.puts("=== Nx Performance Analysis ===\n")

    test_backend_availability()
    test_operation_types()
    test_batch_vs_individual_operations()
    test_complex_mathematical_operations()
    test_memory_efficiency()
  end

  def test_backend_availability do
    IO.puts("=== Backend Availability ===")

    # Test default backend
    IO.puts("Default backend: #{inspect(Nx.default_backend())}")

    # Try to detect available backends
    backends = []

    # Check if EXLA is available
    backends = try do
      Code.ensure_loaded(EXLA.Backend)
      if function_exported?(EXLA.Backend, :__struct__, 0) do
        backends ++ [:exla]
      else
        backends
      end
    rescue
      _ -> backends
    end

    # Check if Torchx is available
    backends = try do
      Code.ensure_loaded(Torchx.Backend)
      if function_exported?(Torchx.Backend, :__struct__, 0) do
        backends ++ [:torchx]
      else
        backends
      end
    rescue
      _ -> backends
    end

    IO.puts("Available backends: #{inspect([:cpu | backends])}")

    # Test TorchX specifically
    if :torchx in backends do
      IO.puts("\n--- TorchX Backend Testing ---")

      try do
        # Test device availability
        devices = Torchx.Backend.list_devices()
        IO.puts("Available devices: #{inspect(devices)}")

        # Test CUDA availability
        cuda_available = Enum.any?(devices, &String.contains?(to_string(&1), "cuda"))
        IO.puts("CUDA available: #{cuda_available}")

        if cuda_available do
          IO.puts("✅ RTX 4090 GPU acceleration ready!")
        else
          IO.puts("⚠️  CUDA not detected, falling back to CPU")
        end
      rescue
        e -> IO.puts("Error testing TorchX: #{inspect(e)}")
      end
    end

    IO.puts("")
  end

  def test_operation_types do
    IO.puts("=== Operation Type Performance ===")

    size = 100_000
    vectors_a = for _ <- 1..size, do: [1.0, 2.0, 3.0]
    vectors_b = for _ <- 1..size, do: [4.0, 5.0, 6.0]

    # Pre-create tensors once
    tensor_a = Nx.tensor(vectors_a)
    tensor_b = Nx.tensor(vectors_b)

    operations = [
      {"Simple Addition",
       fn ->
         Enum.zip(vectors_a, vectors_b)
         |> Enum.map(fn {[x1, y1, z1], [x2, y2, z2]} -> [x1 + x2, y1 + y2, z1 + z2] end)
       end,
       fn -> Nx.add(tensor_a, tensor_b) end},

      {"Dot Product",
       fn ->
         Enum.zip(vectors_a, vectors_b)
         |> Enum.map(fn {[x1, y1, z1], [x2, y2, z2]} -> x1 * x2 + y1 * y2 + z1 * z2 end)
       end,
       fn -> AriaMath.Vector3.Tensor.dot_batch(tensor_a, tensor_b) end},

      {"Vector Normalization",
       fn ->
         Enum.map(vectors_a, fn [x, y, z] ->
           len = :math.sqrt(x * x + y * y + z * z)
           if len > 0, do: [x / len, y / len, z / len], else: [0.0, 0.0, 0.0]
         end)
       end,
       fn ->
         {norm, _valid} = AriaMath.Vector3.Tensor.normalize_batch(tensor_a)
         norm
       end},

      {"Cross Product",
       fn ->
         Enum.zip(vectors_a, vectors_b)
         |> Enum.map(fn {[x1, y1, z1], [x2, y2, z2]} ->
           [y1 * z2 - z1 * y2, z1 * x2 - x1 * z2, x1 * y2 - y1 * x2]
         end)
       end,
       fn -> AriaMath.Vector3.Tensor.cross_batch(tensor_a, tensor_b) end}
    ]

    Enum.each(operations, fn {name, scalar_fn, tensor_fn} ->
      IO.puts("--- #{name} ---")

      # Warm up
      scalar_fn.()
      tensor_fn.()

      scalar_time = measure_time(scalar_fn)
      tensor_time = measure_time(tensor_fn)

      speedup = scalar_time / tensor_time

      IO.puts("Scalar: #{scalar_time} ms")
      IO.puts("Tensor: #{tensor_time} ms")
      IO.puts("Speedup: #{speedup}x")

      if speedup > 1.0 do
        IO.puts("✅ Tensor is #{speedup}x faster!")
      else
        IO.puts("❌ Scalar is #{1/speedup}x faster")
      end

      IO.puts("")
    end)
  end

  def test_batch_vs_individual_operations do
    IO.puts("=== Batch vs Individual Operations ===")

    # Test different batch sizes
    batch_sizes = [100, 1_000, 10_000, 100_000]

    Enum.each(batch_sizes, fn batch_size ->
      IO.puts("--- Batch Size: #{batch_size} ---")

      # Create data
      vectors = for _ <- 1..batch_size, do: [
        :rand.uniform() * 10.0,
        :rand.uniform() * 10.0,
        :rand.uniform() * 10.0
      ]

      # Individual scalar operations
      scalar_time = measure_time(fn ->
        Enum.map(vectors, fn [x, y, z] ->
          len = :math.sqrt(x * x + y * y + z * z)
          if len > 0, do: [x / len, y / len, z / len], else: [0.0, 0.0, 0.0]
        end)
      end)

      # Batch tensor operations
      tensor_vectors = Nx.tensor(vectors)
      tensor_time = measure_time(fn ->
        {normalized, _valid} = AriaMath.Vector3.Tensor.normalize_batch(tensor_vectors)
        normalized
      end)

      speedup = scalar_time / tensor_time

      IO.puts("Scalar: #{scalar_time} ms")
      IO.puts("Tensor: #{tensor_time} ms")
      IO.puts("Speedup: #{speedup}x")

      if speedup > 1.0 do
        IO.puts("✅ Tensor wins at #{batch_size} vectors!")
      else
        IO.puts("❌ Scalar still faster")
      end

      IO.puts("")
    end)
  end

  def test_complex_mathematical_operations do
    IO.puts("=== Complex Mathematical Operations ===")

    size = 10_000

    # Matrix multiplication test
    matrices_a = for _ <- 1..size do
      for i <- 0..3, j <- 0..3, do: i * 4 + j + 1.0
    end

    matrices_b = for _ <- 1..size do
      for i <- 0..3, j <- 0..3, do: (i + j + 1.0) / 16.0
    end

    IO.puts("--- 4x4 Matrix Multiplication (#{size} matrices) ---")

    # Scalar matrix multiplication
    scalar_time = measure_time(fn ->
      Enum.zip(matrices_a, matrices_b)
      |> Enum.map(fn {a, b} ->
        multiply_4x4_matrices(a, b)
      end)
    end)

    # Tensor matrix multiplication - reshape correctly for 4x4 matrices
    tensor_a = matrices_a |> Enum.map(&(Enum.chunk_every(&1, 4) |> Nx.tensor())) |> Nx.stack()
    tensor_b = matrices_b |> Enum.map(&(Enum.chunk_every(&1, 4) |> Nx.tensor())) |> Nx.stack()

    tensor_time = measure_time(fn ->
      Nx.dot(tensor_a, tensor_b)
    end)

    speedup = scalar_time / tensor_time

    IO.puts("Scalar: #{scalar_time} ms")
    IO.puts("Tensor: #{tensor_time} ms")
    IO.puts("Speedup: #{speedup}x")

    if speedup > 1.0 do
      IO.puts("✅ Tensor matrix multiplication is faster!")
    else
      IO.puts("❌ Scalar matrix multiplication still faster")
    end

    IO.puts("")
  end

  def test_memory_efficiency do
    IO.puts("=== Memory Efficiency Test ===")

    size = 50_000

    IO.puts("--- Multiple Operations on Same Data ---")

    vectors = for _ <- 1..size, do: [
      :rand.uniform() * 10.0,
      :rand.uniform() * 10.0,
      :rand.uniform() * 10.0
    ]

    # Scalar: multiple passes through data
    scalar_time = measure_time(fn ->
      # Step 1: Normalize
      normalized = Enum.map(vectors, fn [x, y, z] ->
        len = :math.sqrt(x * x + y * y + z * z)
        if len > 0, do: [x / len, y / len, z / len], else: [0.0, 0.0, 0.0]
      end)

      # Step 2: Scale by 2
      scaled = Enum.map(normalized, fn [x, y, z] -> [x * 2.0, y * 2.0, z * 2.0] end)

      # Step 3: Calculate magnitude
      Enum.map(scaled, fn [x, y, z] -> :math.sqrt(x * x + y * y + z * z) end)
    end)

    # Tensor: operations stay in tensor space
    tensor_vectors = Nx.tensor(vectors)
    tensor_time = measure_time(fn ->
      tensor_vectors
      |> then(fn t -> elem(AriaMath.Vector3.Tensor.normalize_batch(t), 0) end)
      |> Nx.multiply(2.0)
      |> AriaMath.Vector3.Tensor.magnitude_batch()
    end)

    speedup = scalar_time / tensor_time

    IO.puts("Scalar (3 passes): #{scalar_time} ms")
    IO.puts("Tensor (chained ops): #{tensor_time} ms")
    IO.puts("Speedup: #{speedup}x")

    if speedup > 1.0 do
      IO.puts("✅ Tensor chaining is faster!")
    else
      IO.puts("❌ Scalar still faster even with multiple passes")
    end
  end

  # Helper functions
  defp measure_time(fun) do
    {time, _result} = :timer.tc(fun)
    time / 1000  # Convert to milliseconds
  end

  defp multiply_4x4_matrices(a, b) do
    # Simple 4x4 matrix multiplication
    for i <- 0..3, j <- 0..3 do
      Enum.sum(for k <- 0..3, do: Enum.at(a, i * 4 + k) * Enum.at(b, k * 4 + j))
    end
  end
end

# Run the analysis
NxPerformanceAnalysis.run_full_analysis()
