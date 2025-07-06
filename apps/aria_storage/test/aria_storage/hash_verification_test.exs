# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaStorage.HashVerificationTest do
  @moduledoc "Comprehensive test suite for hash verification functionality.\n\nThis test suite validates the hash verification mechanisms discovered during\nour analysis, ensuring that SHA512/256 is used consistently throughout the\nsystem and that all verification components work correctly.\n"
  use ExUnit.Case, async: true
  alias AriaStorage.Chunks
  alias AriaStorage.CasyncDecoder
  @ca_format_sha512_256 2_305_843_009_213_693_952
  describe("SHA512/256 hash consistency") do
    test "chunk ID calculation uses SHA512/256" do
      test_data = "Test data for hash verification"
      chunk_id = Chunks.calculate_chunk_id(test_data)
      expected_id = :crypto.hash(:sha512, test_data) |> binary_part(0, 32)
      assert chunk_id == expected_id, "Chunk ID should use SHA512/256"
      assert byte_size(chunk_id) == 32, "Chunk ID should be 32 bytes"
    end

    test "SHA512/256 differs from SHA256" do
      test_data = "Comparison test data"
      sha256_hash = :crypto.hash(:sha256, test_data)
      sha512_256_hash = :crypto.hash(:sha512, test_data) |> binary_part(0, 32)
      chunk_id = Chunks.calculate_chunk_id(test_data)
      refute sha256_hash == sha512_256_hash, "SHA256 and SHA512/256 should differ"
      assert chunk_id == sha512_256_hash, "Chunk ID should use SHA512/256, not SHA256"
    end

    test "hash calculation is deterministic" do
      test_data = "Deterministic test"
      hash1 = Chunks.calculate_chunk_id(test_data)
      hash2 = Chunks.calculate_chunk_id(test_data)
      assert hash1 == hash2, "Hash calculation should be deterministic"
    end

    test "different data produces different hashes" do
      data1 = "First test data"
      data2 = "Second test data"
      hash1 = Chunks.calculate_chunk_id(data1)
      hash2 = Chunks.calculate_chunk_id(data2)
      refute hash1 == hash2, "Different data should produce different hashes"
    end

    test "empty data has valid hash" do
      empty_hash = Chunks.calculate_chunk_id("")
      assert byte_size(empty_hash) == 32, "Empty data hash should still be 32 bytes"
      assert is_binary(empty_hash), "Hash should be binary"
    end
  end

  describe("CasyncDecoder hash verification") do
    test "verifies correct hash successfully" do
      test_data = "Verification test data"
      expected_hash = Chunks.calculate_chunk_id(test_data)

      assert {:ok, ^test_data} =
               CasyncDecoder.verify_chunk(test_data, expected_hash, @ca_format_sha512_256)
    end

    test "rejects incorrect hash" do
      test_data = "Test data"
      wrong_hash = Chunks.calculate_chunk_id("Different data")

      assert {:error, {:hash_mismatch, _}} =
               CasyncDecoder.verify_chunk(test_data, wrong_hash, @ca_format_sha512_256)
    end

    test "verification is consistent with chunk ID calculation" do
      test_data = "Consistency verification test"
      chunk_id = Chunks.calculate_chunk_id(test_data)

      assert {:ok, ^test_data} =
               CasyncDecoder.verify_chunk(test_data, chunk_id, @ca_format_sha512_256)
    end

    test "handles binary data correctly" do
      binary_data = <<0, 1, 2, 3, 255, 254, 253, 252>>
      expected_hash = Chunks.calculate_chunk_id(binary_data)

      assert {:ok, ^binary_data} =
               CasyncDecoder.verify_chunk(binary_data, expected_hash, @ca_format_sha512_256)
    end

    test "handles large data efficiently" do
      large_data = String.duplicate("Large test data ", 10000)
      expected_hash = Chunks.calculate_chunk_id(large_data)

      {time_microseconds, result} =
        :timer.tc(fn ->
          CasyncDecoder.verify_chunk(large_data, expected_hash, @ca_format_sha512_256)
        end)

      assert {:ok, ^large_data} = result

      assert time_microseconds < 80000,
             "Hash verification should be fast, took #{time_microseconds}μs"
    end
  end

  describe("chunk creation with verification") do
    test "created chunks have correct hash IDs" do
      test_data = "Chunk creation test"
      chunks = Chunks.find_all_chunks_in_data(test_data, 1, 1000, 100, :none)
      assert length(chunks) == 1, "Should create single chunk for small data"
      chunk = List.first(chunks)
      expected_id = Chunks.calculate_chunk_id(test_data)
      assert chunk.id == expected_id, "Chunk ID should match calculated hash"
      assert chunk.data == test_data, "Chunk data should match input"
    end

    test "chunk has additional SHA256 checksum" do
      test_data = "Checksum test data"
      chunks = Chunks.find_all_chunks_in_data(test_data, 1, 1000, 100, :none)
      chunk = List.first(chunks)
      expected_checksum = :crypto.hash(:sha256, test_data)
      assert chunk.checksum == expected_checksum, "Additional checksum should be SHA256"
      refute chunk.checksum == chunk.id, "Checksum and ID should use different algorithms"
    end
  end

  describe("hash verification error handling") do
    test "handles malformed hash gracefully" do
      test_data = "Error handling test"
      malformed_hash = "not a valid hash"

      assert {:error, {:hash_mismatch, _}} =
               CasyncDecoder.verify_chunk(test_data, malformed_hash, @ca_format_sha512_256)
    end

    test "handles wrong hash length" do
      test_data = "Wrong length test"
      short_hash = <<1, 2, 3, 4>>

      assert {:error, {:hash_mismatch, _}} =
               CasyncDecoder.verify_chunk(test_data, short_hash, @ca_format_sha512_256)
    end

    test "handles nil data" do
      valid_hash = Chunks.calculate_chunk_id("test")

      assert_raise ArgumentError, fn ->
        CasyncDecoder.verify_chunk(nil, valid_hash, @ca_format_sha512_256)
      end
    end
  end

  describe("cross-component verification consistency") do
    test "all verification components use same hash algorithm" do
      test_data = "Cross-component consistency test"
      chunk_id = Chunks.calculate_chunk_id(test_data)

      assert {:ok, ^test_data} =
               CasyncDecoder.verify_chunk(test_data, chunk_id, @ca_format_sha512_256)

      chunks = Chunks.find_all_chunks_in_data(test_data, 1, 1000, 100, :none)
      chunk = List.first(chunks)
      assert chunk.id == chunk_id, "Chunk creation should use same hash function"

      assert {:ok, ^test_data} =
               CasyncDecoder.verify_chunk(chunk.data, chunk.id, @ca_format_sha512_256)
    end

    test "compression doesn't affect hash calculation" do
      test_data = String.duplicate("Compressible test data ", 100)
      uncompressed_chunks = Chunks.find_all_chunks_in_data(test_data, 1, 10000, 1000, :none)
      compressed_chunks = Chunks.find_all_chunks_in_data(test_data, 1, 10000, 1000, :zstd)
      assert length(uncompressed_chunks) == length(compressed_chunks)

      Enum.zip(uncompressed_chunks, compressed_chunks)
      |> Enum.each(fn {uncompressed, compressed} ->
        assert uncompressed.id == compressed.id, "Compression should not affect chunk ID"
        assert uncompressed.data == compressed.data, "Original data should be the same"
        refute uncompressed.compressed == compressed.compressed, "Compressed data should differ"
      end)
    end
  end

  describe("hash algorithm security properties") do
    test "SHA512/256 provides good distribution" do
      test_cases =
        for i <- 1..100 do
          "Test data #{i}"
        end

      hashes = Enum.map(test_cases, &Chunks.calculate_chunk_id/1)
      unique_hashes = Enum.uniq(hashes)
      assert length(unique_hashes) == length(hashes), "All hashes should be unique"
      first_bytes = Enum.map(hashes, fn hash -> :binary.at(hash, 0) end)
      unique_first_bytes = Enum.uniq(first_bytes)
      assert length(unique_first_bytes) > 50, "Should have good hash distribution"
    end

    test "small input changes produce very different hashes" do
      base_data = "Hash sensitivity test"
      modified_data = "Hash sensitivity tast"
      hash1 = Chunks.calculate_chunk_id(base_data)
      hash2 = Chunks.calculate_chunk_id(modified_data)
      refute hash1 == hash2, "Small changes should produce different hashes"

      different_bytes =
        Enum.zip(:binary.bin_to_list(hash1), :binary.bin_to_list(hash2))
        |> Enum.count(fn {a, b} -> a != b end)

      assert different_bytes > 10, "Small input changes should cause large hash changes"
    end
  end
end
