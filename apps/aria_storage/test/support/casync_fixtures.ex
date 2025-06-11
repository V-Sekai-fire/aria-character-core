# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaStorage.TestFixtures.CasyncFixtures do
  @moduledoc """
  Test fixtures for generating ARCANA format test data.

  Provides utilities for creating synthetic ARCANA index (.arcx),
  archive (.arca), and chunk (.arcc) files for testing.
  Compatible with casync/desync (.caibx/.caidx/.catar/.cacnk) formats.
  """

  @doc """
  Creates a synthetic multi-chunk ARCX (caibx-compatible) file with the specified number of chunks.
  """
  def create_multi_chunk_caibx(chunk_count) when is_integer(chunk_count) and chunk_count > 0 do
    # Create a synthetic ARCX file with specified chunk count
    # ARCX file format:
    # - Magic: 3 bytes (0xCA, 0x1B, 0x5C)
    # - Header: version (4), total_size (8), chunk_count (4), reserved (4)
    # - Chunk entries: each 48 bytes (32-byte ID + 8-byte offset + 4-byte size + 4-byte flags)

    magic = <<0xCA, 0x1B, 0x5C>>  # ARCX magic bytes

    # Calculate total size based on chunk count
    chunk_entry_size = 48  # 32 + 8 + 4 + 4
    total_data_size = chunk_count * 1024  # Assume 1KB per chunk
    
    # Create header
    header = <<
      1::little-32,                    # version
      total_data_size::little-64,      # total_size
      chunk_count::little-32,          # chunk_count
      0::little-32                     # reserved
    >>

    # Create chunk entries (each is 48 bytes)
    chunks = for i <- 1..chunk_count do
      # Generate a consistent 32-byte chunk ID
      chunk_id = :crypto.hash(:sha256, "test_chunk_#{i}")
      offset = (i - 1) * 1024  # Each chunk starts at 1KB intervals
      size = 1024             # Each chunk is 1KB
      flags = 0               # No special flags
      
      <<chunk_id::binary-size(32), offset::little-64, size::little-32, flags::little-32>>
    end

    # Combine all parts
    magic <> header <> Enum.join(chunks)
  end

  @doc """
  Creates a minimal ARCX file with a single chunk.
  """
  def create_minimal_caibx do
    create_multi_chunk_caibx(1)
  end

  @doc """
  Creates invalid test data with various corruption types.
  """
  def create_invalid_data(corruption_type) do
    case corruption_type do
      :wrong_magic ->
        # Invalid magic header - use incorrect bytes
        <<0xFF, 0xFF, 0xFF>> <> (create_multi_chunk_caibx(1) |> binary_part(3, 50))

      :truncated ->
        # Truncated file
        create_multi_chunk_caibx(5) |> binary_part(0, 10)

      :corrupted_header ->
        # Valid magic but corrupted header
        magic = <<0xCA, 0x1B, 0x5C>>
        corrupted_header = <<255, 255, 255, 255>> <> :crypto.strong_rand_bytes(16)
        magic <> corrupted_header

      _ ->
        # Default to random binary data
        :crypto.strong_rand_bytes(100)
    end
  end

  @doc """
  Creates a complex catar (Casync archive) file for testing.
  """
  def create_complex_catar do
    # CATAR file format is more complex, containing file system metadata
    # This is a simplified version for testing

    # CATAR magic: 3 bytes (0xCA, 0x1A, 0x52)
    magic = <<0xCA, 0x1A, 0x52>>

    # Since the current parser is basic and just returns empty entries,
    # we only need the magic bytes for format detection
    magic
  end

  @doc """
  Validates the structure of a parsed index file.
  """
  def validate_index_structure(parsed_result) do
    case parsed_result do
      {:ok, %{chunks: chunks, metadata: _metadata}} when is_list(chunks) ->
        # Validate that all chunks have required fields
        Enum.all?(chunks, fn chunk ->
          is_map(chunk) and
          Map.has_key?(chunk, :id) and
          Map.has_key?(chunk, :size) and
          Map.has_key?(chunk, :offset)
        end)

      _ ->
        false
    end
  end

  @doc """
  Validates the structure of a parsed archive file.
  """
  def validate_archive_structure(parsed_result) do
    case parsed_result do
      {:ok, %{entries: entries, metadata: _metadata}} when is_list(entries) ->
        # Validate that all entries have required fields
        Enum.all?(entries, fn entry ->
          is_map(entry) and
          Map.has_key?(entry, :type) and
          Map.has_key?(entry, :name)
        end)

      _ ->
        false
    end
  end

  @doc """
  Creates test data for performance benchmarking.
  """
  def create_benchmark_data(size_category) do
    case size_category do
      :small -> create_multi_chunk_caibx(10)
      :medium -> create_multi_chunk_caibx(100)
      :large -> create_multi_chunk_caibx(1000)
      :xlarge -> create_multi_chunk_caibx(10000)
      _ -> create_minimal_caibx()
    end
  end

  @doc """
  Generates consistent test chunk IDs for deterministic testing.
  """
  def generate_test_chunk_id(index) do
    # Generate a 32-byte chunk ID that's deterministic but looks realistic
    base = "test_chunk_#{index}"
    :crypto.hash(:sha256, base)
  end

  @doc """
  Creates chunk metadata for testing chunk operations.
  """
  def create_chunk_metadata(chunk_id, size \\ 1024) do
    %{
      id: chunk_id,
      size: size,
      offset: 0,
      checksum: :crypto.hash(:sha256, "test_data_#{chunk_id}"),
      compressed: false
    }
  end
end
