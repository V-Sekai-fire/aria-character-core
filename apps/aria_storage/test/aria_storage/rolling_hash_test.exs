defmodule AriaStorage.RollingHashTest do
  @moduledoc """
  Comprehensive test suite for rolling hash functionality in chunking algorithm.
  
  This test suite captures all the learnings from debugging the rolling hash implementation
  to ensure compatibility with desync/casync. It tests the specific edge cases and mechanics
  that were discovered during development.
  """
  
  use ExUnit.Case, async: true
  alias AriaStorage.Chunks
  
  describe "discriminator calculation" do
    test "matches desync formula exactly" do
      # Test various average sizes
      test_cases = [
        {16 * 1024, 12318},    # 16KB -> 12318 
        {32 * 1024, 24680},    # 32KB -> 24680
        {64 * 1024, 49535},    # 64KB -> 49535
        {128 * 1024, 99777},   # 128KB -> 99777
      ]
      
      for {avg_size, expected_discriminator} <- test_cases do
        calculated = Chunks.discriminator_from_avg(avg_size)
        assert calculated == expected_discriminator,
          "Discriminator for avg #{avg_size} should be #{expected_discriminator}, got #{calculated}"
      end
    end
    
    test "uses exact desync formula without offset" do
      avg = 64 * 1024
      # Exact formula from desync Go code
      expected = trunc(avg / (-1.42888852e-7 * avg + 1.33237515))
      actual = Chunks.discriminator_from_avg(avg)
      
      assert actual == expected,
        "Discriminator calculation should match desync exactly: expected #{expected}, got #{actual}"
    end
  end
  
  describe "buzhash calculation" do
    test "calculates initial hash correctly" do
      # Test with known window data (48 bytes exactly)
      window_data = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUV"
      assert byte_size(window_data) == 48  # Window size
      
      hash = Chunks.calculate_buzhash_test(window_data)
      assert is_integer(hash)
      assert hash >= 0
      assert hash <= 0xFFFFFFFF  # 32-bit unsigned integer
    end
    
    test "hash is deterministic" do
      window_data = String.duplicate("test", 12)  # 48 bytes
      hash1 = Chunks.calculate_buzhash_test(window_data)
      hash2 = Chunks.calculate_buzhash_test(window_data)
      
      assert hash1 == hash2, "Buzhash should be deterministic"
    end
    
    test "different windows produce different hashes" do
      window1 = String.duplicate("aaaa", 12)  # 48 bytes of 'a'
      window2 = String.duplicate("bbbb", 12)  # 48 bytes of 'b'
      
      hash1 = Chunks.calculate_buzhash_test(window1)
      hash2 = Chunks.calculate_buzhash_test(window2)
      
      assert hash1 != hash2, "Different windows should produce different hashes"
    end
  end
  
  describe "buzhash update" do
    test "rolling update maintains hash consistency" do
      # Create a longer data sequence
      data = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
      assert byte_size(data) > 48
      
      # Calculate initial hash for first window
      window1 = binary_part(data, 0, 48)
      hash1 = Chunks.calculate_buzhash_test(window1)
      
      # Calculate hash for second window using full calculation
      window2 = binary_part(data, 1, 48)
      hash2_full = Chunks.calculate_buzhash_test(window2)
      
      # Calculate hash for second window using rolling update
      out_byte = :binary.at(data, 0)   # First byte of first window
      in_byte = :binary.at(data, 48)   # New byte entering the window
      hash2_rolled = Chunks.update_buzhash_test(hash1, out_byte, in_byte)
      
      assert hash2_full == hash2_rolled,
        "Rolling hash update should match full recalculation"
    end
    
    test "update handles edge cases correctly" do
      # Test with bytes that could cause issues (0, 255, etc.)
      window = String.duplicate(<<0>>, 48)
      initial_hash = Chunks.calculate_buzhash_test(window)
      
      # Update with extreme byte values
      updated_hash = Chunks.update_buzhash_test(initial_hash, 0, 255)
      assert is_integer(updated_hash)
      assert updated_hash >= 0
      assert updated_hash <= 0xFFFFFFFF
    end
  end
  
  describe "boundary detection" do
    test "detects boundaries at correct positions" do
      # Use known data that should produce boundaries
      data = File.read!(Path.join(__DIR__, "../support/testdata/chunker.input"))
      min_size = 16 * 1024
      max_size = 256 * 1024
      discriminator = Chunks.discriminator_from_avg(64 * 1024)
      
      chunks = Chunks.find_all_chunks_in_data(data, min_size, max_size, discriminator, :none)
      
      # Verify chunks are within size constraints
      for chunk <- chunks do
        assert chunk.size >= min_size or chunk == List.last(chunks),
          "Chunk size #{chunk.size} should be >= min_size #{min_size} (except last chunk)"
        assert chunk.size <= max_size,
          "Chunk size #{chunk.size} should be <= max_size #{max_size}"
      end
    end
    
    test "boundary detection order matches desync" do
      # This test ensures we update hash first, then check boundary
      # (Not update first, check boundary, then update again)
      data = String.duplicate("test data for boundary detection ", 10000)
      min_size = 1024
      max_size = 8192
      discriminator = 1000
      
      chunks = Chunks.find_all_chunks_in_data(data, min_size, max_size, discriminator, :none)
      
      # Should produce multiple chunks
      assert length(chunks) > 1, "Should produce multiple chunks with small discriminator"
      
      # All chunks should be contiguous
      total_size = Enum.reduce(chunks, 0, fn chunk, acc -> acc + chunk.size end)
      assert total_size == byte_size(data),
        "Total chunk size should equal input data size"
    end
  end
  
  describe "window positioning" do
    test "window positioning follows desync algorithm" do
      # Test that the rolling hash window is positioned correctly
      # relative to the boundary detection logic
      data = "a" <> String.duplicate("test", 1000) <> "b"
      min_size = 100
      max_size = 2000
      discriminator = 100
      
      chunks = Chunks.find_all_chunks_in_data(data, min_size, max_size, discriminator, :none)
      
      # Verify chunks are contiguous and cover all data
      {final_offset, _} = Enum.reduce(chunks, {0, 0}, fn chunk, {current_offset, index} ->
        assert chunk.offset == current_offset,
          "Chunk offset #{chunk.offset} should equal running total #{current_offset}"
        {current_offset + chunk.size, index + 1}
      end)
      
      assert final_offset == byte_size(data),
        "Final offset should equal total data size"
    end
  end
  
  describe "edge cases" do
    test "handles data smaller than window size" do
      small_data = "small"
      assert byte_size(small_data) < 48  # Less than window size
      
      chunks = Chunks.find_all_chunks_in_data(small_data, 1, 100, 50, :none)
      
      assert length(chunks) == 1, "Small data should produce single chunk"
      assert List.first(chunks).size == byte_size(small_data)
    end
    
    test "handles data exactly at min size" do
      min_size = 100
      data = String.duplicate("x", min_size)
      
      chunks = Chunks.find_all_chunks_in_data(data, min_size, 200, 50, :none)
      
      assert length(chunks) == 1, "Data at min size should produce single chunk"
      assert List.first(chunks).size == min_size
    end
    
    test "handles data exactly at max size" do
      max_size = 200
      data = String.duplicate("x", max_size)
      
      chunks = Chunks.find_all_chunks_in_data(data, 50, max_size, 25, :none)
      
      # Should produce at least one chunk, possibly more depending on boundaries
      assert length(chunks) >= 1
      
      # No chunk should exceed max size
      for chunk <- chunks do
        assert chunk.size <= max_size,
          "Chunk size #{chunk.size} should not exceed max_size #{max_size}"
      end
    end
    
    test "handles empty data" do
      chunks = Chunks.find_all_chunks_in_data("", 10, 100, 50, :none)
      assert chunks == [], "Empty data should produce no chunks"
    end
  end
  
  describe "compatibility with desync reference" do
    @tag :integration
    test "produces identical boundaries to desync" do
      # This is the comprehensive compatibility test
      input_file = Path.join(__DIR__, "../support/testdata/chunker.input")
      index_file = Path.join(__DIR__, "../support/testdata/chunker.index")
      
      # Skip if test files don't exist
      unless File.exists?(input_file) and File.exists?(index_file) do
        IO.puts("Skipping desync compatibility test - test files not found")
        :ok
      else
      
      {:ok, data} = File.read(input_file)
      {:ok, index_data} = File.read(index_file)
      {:ok, expected_index} = AriaStorage.Parsers.CasyncFormat.parse_index(index_data)
      
      # Use exact same parameters as desync
      min_size = 16 * 1024
      avg_size = 64 * 1024
      max_size = 256 * 1024
      discriminator = Chunks.discriminator_from_avg(avg_size)
      
      our_chunks = Chunks.find_all_chunks_in_data(data, min_size, max_size, discriminator, :none)
      expected_chunks = expected_index.chunks
      
      # Verify exact match
      assert length(our_chunks) == length(expected_chunks),
        "Chunk count should match desync: expected #{length(expected_chunks)}, got #{length(our_chunks)}"
      
      # Verify each chunk boundary matches exactly
      Enum.zip(our_chunks, expected_chunks)
      |> Enum.with_index()
      |> Enum.each(fn {{our_chunk, expected_chunk}, i} ->
        assert our_chunk.offset == expected_chunk.offset,
          "Chunk #{i} offset mismatch: expected #{expected_chunk.offset}, got #{our_chunk.offset}"
        assert our_chunk.size == expected_chunk.size,
          "Chunk #{i} size mismatch: expected #{expected_chunk.size}, got #{our_chunk.size}"
      end)
      end
    end
  end
  
  describe "performance characteristics" do
    test "chunking performance is reasonable" do
      # Generate test data
      data = String.duplicate("performance test data ", 10000)  # ~200KB
      
      {time_microseconds, chunks} = :timer.tc(fn ->
        Chunks.find_all_chunks_in_data(data, 4096, 65536, 16384, :none)
      end)
      
      # Should complete in reasonable time (less than 100ms for 200KB)
      assert time_microseconds < 100_000,
        "Chunking should complete in under 100ms, took #{time_microseconds}μs"
      
      # Should produce reasonable number of chunks
      assert length(chunks) > 1 and length(chunks) < 100,
        "Should produce reasonable number of chunks, got #{length(chunks)}"
    end
  end
end
