# Quick benchmark to verify Nx is working and show performance difference

defmodule NxBenchmark do
  def test_nx_available do
    IO.puts("Testing Nx availability...")

    # Test basic Nx operation
    tensor = Nx.tensor([1, 2, 3, 4, 5])
    result = Nx.add(tensor, 1)
    IO.puts("Nx.add result: #{inspect(Nx.to_list(result))}")

    # Test matrix operations
    matrix = Nx.tensor([[1, 2], [3, 4]])
    transposed = Nx.transpose(matrix)
    IO.puts("Matrix transpose result: #{inspect(Nx.to_list(transposed))}")

    IO.puts("✅ Nx is working!")
  end

  def compare_vector_operations do
    IO.puts("\n=== Vector Operations Comparison ===")

    # Test multiple sizes to show where Nx becomes beneficial
    sizes = [1_000, 10_000, 100_000, 1_000_000]

    Enum.each(sizes, fn size ->
      IO.puts("\n--- Testing with #{size} vectors ---")

      # Create test data
      vectors_a = for _ <- 1..size, do: [1.0, 2.0, 3.0]
      vectors_b = for _ <- 1..size, do: [4.0, 5.0, 6.0]

      # Scalar implementation (using tuples)
      tuples_a = for v <- vectors_a, do: List.to_tuple(v)
      tuples_b = for v <- vectors_b, do: List.to_tuple(v)

      scalar_time = :timer.tc(fn ->
        Enum.zip(tuples_a, tuples_b)
        |> Enum.map(fn {{x1, y1, z1}, {x2, y2, z2}} ->
          {x1 + x2, y1 + y2, z1 + z2}
        end)
      end)

      # Tensor implementation with pre-created tensors
      tensor_a = Nx.tensor(vectors_a)
      tensor_b = Nx.tensor(vectors_b)

      tensor_time = :timer.tc(fn ->
        Nx.add(tensor_a, tensor_b)
      end)

      scalar_ms = elem(scalar_time, 0) / 1000
      tensor_ms = elem(tensor_time, 0) / 1000
      speedup = scalar_ms / tensor_ms

      IO.puts("Scalar time: #{scalar_ms} ms")
      IO.puts("Tensor time: #{tensor_ms} ms")
      IO.puts("Speedup: #{speedup}x")

      if speedup > 1.0 do
        IO.puts("✅ Nx is faster!")
      else
        IO.puts("❌ Scalar is faster (expected for small datasets)")
      end
    end)
  end

  def test_aria_math_tensor do
    IO.puts("\n=== Testing AriaMath Tensor Module ===")

    try do
      # Test if our tensor module loads
      Code.ensure_loaded(AriaMath.Vector3.Tensor)

      # Create test tensors
      vectors = Nx.tensor([[1.0, 2.0, 3.0], [4.0, 5.0, 6.0], [7.0, 8.0, 9.0]])

      # Test our tensor operations
      result = AriaMath.Vector3.Tensor.add_batch(vectors, vectors)
      IO.puts("AriaMath tensor add result: #{inspect(Nx.to_list(result))}")

      IO.puts("✅ AriaMath tensor operations working!")
    rescue
      e -> IO.puts("❌ Error testing AriaMath tensor: #{inspect(e)}")
    end
  end
end

# Run the benchmark
NxBenchmark.test_nx_available()
NxBenchmark.compare_vector_operations()
NxBenchmark.test_aria_math_tensor()
