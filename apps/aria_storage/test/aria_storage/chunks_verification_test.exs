# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaStorage.ChunksVerificationTest do
  @moduledoc """
  Integration test for verifying our chunking implementation matches desync/casync exactly.
  """
  use ExUnit.Case, async: false

  alias AriaStorage.Chunks
  alias AriaStorage.Parsers.CasyncFormat

  @describetag :integration
  @describetag timeout: 30_000
  describe "chunking verification against desync/casync" do
    test "chunks match desync reference implementation exactly" do
      # Configure paths
      input_path = Path.join(__DIR__, "../support/testdata/chunker.input")
      index_path = Path.join(__DIR__, "../support/testdata/chunker.index")

      # Verify test files exist
      assert File.exists?(input_path), "Test input file not found: #{input_path}"
      assert File.exists?(index_path), "Test index file not found: #{index_path}"

      # Parse the expected index file to get chunk info
      {:ok, expected_index} = File.read(index_path)
      {:ok, index_info} = CasyncFormat.parse_index(expected_index)
      expected_chunks = index_info.chunks

      # Load input data
      {:ok, data} = File.read(input_path)

      # Use the same parameters as desync/casync
      min_size = 16 * 1024       # 16KB
      avg_size = 64 * 1024       # 64KB
      max_size = 256 * 1024      # 256KB
      discriminator = Chunks.discriminator_from_avg(avg_size)

      # Create chunks using our algorithm
      our_chunks = Chunks.find_all_chunks_in_data(data, min_size, max_size, discriminator, :none)

      # Verify chunk count matches
      assert length(our_chunks) == length(expected_chunks),
        "Chunk count mismatch: expected #{length(expected_chunks)}, got #{length(our_chunks)}"

      # Verify chunk boundaries are contiguous
      Enum.with_index(our_chunks) 
      |> Enum.reduce(0, fn {chunk, i}, prev_offset ->
        expected_chunk = Enum.at(expected_chunks, i)

        # Check chunk is contiguous with previous
        assert chunk.offset == prev_offset,
          "Chunk #{i + 1} offset #{chunk.offset} doesn't follow previous chunk end #{prev_offset}"

        # Check offset matches expected
        assert chunk.offset == expected_chunk.offset,
          "Chunk #{i + 1} offset #{chunk.offset} doesn't match expected #{expected_chunk.offset}"

        # Check size matches expected
        assert chunk.size == expected_chunk.size,
          "Chunk #{i + 1} size #{chunk.size} doesn't match expected #{expected_chunk.size}"

        prev_offset + chunk.size
      end)

      # Verify total size matches input
      total_size = Enum.sum(Enum.map(our_chunks, & &1.size))
      assert total_size == byte_size(data),
        "Total chunk size #{total_size} doesn't match input size #{byte_size(data)}"

      # Verify first chunk has expected characteristics
      our_first_chunk = List.first(our_chunks)
      expected_first_chunk = List.first(expected_chunks)

      assert our_first_chunk.size == expected_first_chunk.size,
        "First chunk size mismatch: expected #{expected_first_chunk.size}, got #{our_first_chunk.size}"

      # Log success details
      first_chunk_id_hex = Base.encode16(our_first_chunk.id, case: :lower)
      IO.puts("\n✅ CHUNKING VERIFICATION SUCCESS:")
      IO.puts("  - Created #{length(our_chunks)} chunks matching desync exactly")
      IO.puts("  - First chunk: size=#{our_first_chunk.size}, id=#{String.slice(first_chunk_id_hex, 0, 16)}...")
      IO.puts("  - Total size: #{total_size} bytes")
      IO.puts("  - Parameters: min=#{min_size}, avg=#{avg_size}, max=#{max_size}, discriminator=#{discriminator}")
    end

    test "chunk IDs use SHA512/256 hash correctly" do
      # Test that our chunk ID calculation matches expected format
      test_data = "Hello, World!"
      chunk_id = Chunks.calculate_chunk_id(test_data)

      # Should be 32 bytes (256 bits)
      assert byte_size(chunk_id) == 32, "Chunk ID should be 32 bytes, got #{byte_size(chunk_id)}"

      # Should be deterministic
      chunk_id2 = Chunks.calculate_chunk_id(test_data)
      assert chunk_id == chunk_id2, "Chunk ID calculation should be deterministic"

      # Should match SHA512/256 format (first 32 bytes of SHA512)
      expected_id = :crypto.hash(:sha512, test_data) |> binary_part(0, 32)
      assert chunk_id == expected_id, "Chunk ID should match SHA512/256 format"
    end

    test "chunk compression works correctly" do
      test_data = String.duplicate("Hello, World! ", 1000)  # Make it compressible

      # Test zstd compression
      {:ok, compressed} = Chunks.compress_chunk(test_data, :zstd)
      assert byte_size(compressed) < byte_size(test_data), "Compressed data should be smaller"

      {:ok, decompressed} = Chunks.decompress_chunk(compressed, :zstd)
      assert decompressed == test_data, "Decompressed data should match original"

      {:ok, uncompressed} = Chunks.compress_chunk(test_data, :none)
      assert uncompressed == test_data, "No compression should return original data"

      {:ok, decompressed_none} = Chunks.decompress_chunk(uncompressed, :none)
      assert decompressed_none == test_data, "Decompressed uncompressed data should match original"
    end
  end
end
