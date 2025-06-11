# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaStorage.TestFixtures.CasyncFixtures do
  @moduledoc """
  Test fixtures for generating ARCANA format test data.

  Provides utilities for creating synthetic ARCANA index (.arcx),
  archive (.arca), and chunk (.arcc) files for testing.
  Compatible with casync/desync (.caibx/.caidx/.catar/.cacnk) formats.
  """

  # Constants from desync source (matching parser)
  @ca_format_index 0x96824d9c7b129ff9
  @ca_format_table 0xe75b9e112f17417d
  @ca_format_table_tail_marker 0x4b4f050e5549ecd1
  @ca_format_sha512_256 0x2000000000000000

  @doc """
  Creates a synthetic multi-chunk ARCX (caibx-compatible) file with the specified number of chunks.
  Generates proper desync FormatIndex/FormatTable structure.
  """
  def create_multi_chunk_caibx(chunk_count) when is_integer(chunk_count) and chunk_count > 0 do
    # Create desync-compatible binary format
    # FormatIndex (48 bytes): 8-byte size + 8-byte type + 32 bytes of fields
    format_index = <<
      48::little-64,                    # Size of FormatIndex
      @ca_format_index::little-64,      # Magic for FormatIndex
      @ca_format_sha512_256::little-64, # Feature flags (SHA512-256 for blobs)
      1024::little-64,                  # chunk_size_min
      1024::little-64,                  # chunk_size_avg
      1024::little-64                   # chunk_size_max
    >>

    # FormatTable header (16 bytes)
    table_header = <<
      0xFFFFFFFFFFFFFFFF::little-64,    # Table marker
      @ca_format_table::little-64       # Table type
    >>

    # Create table items (40 bytes each: 8-byte offset + 32-byte chunk_id)
    table_items = for i <- 1..chunk_count do
      chunk_id = :crypto.hash(:sha256, "test_chunk_#{i}")
      offset = (i - 1) * 1024  # Each chunk starts at 1KB intervals
      <<offset::little-64, chunk_id::binary-size(32)>>
    end

    # Table tail marker (40 bytes)
    table_tail = <<
      0::little-64,                     # Zero offset
      0::little-64,                     # Zero pad
      48::little-64,                    # Size field
      0::little-64,                     # Table size (simplified)
      @ca_format_table_tail_marker::little-64 # Tail marker
    >>

    # Combine all parts
    format_index <> table_header <> Enum.join(table_items) <> table_tail
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
        # Invalid magic header - corrupt the FormatIndex magic
        <<48::little-64, 0xFFFFFFFFFFFFFFFF::little-64>> <> :crypto.strong_rand_bytes(32)

      :truncated ->
        # Truncated file - cut off in the middle of FormatIndex
        create_multi_chunk_caibx(5) |> binary_part(0, 20)

      :corrupted_header ->
        # Valid size but corrupted FormatIndex magic
        <<48::little-64, 0xDEADBEEFDEADBEEF::little-64>> <> :crypto.strong_rand_bytes(32)

      _ ->
        # Default to random binary data
        :crypto.strong_rand_bytes(100)
    end
  end

  @doc """
  Creates a complex catar (Casync archive) file for testing.
  """
  def create_complex_catar do
    # CATAR file format starts with magic bytes
    # Magic: 0xCA, 0x1A, 0x52 (from parser detection)
    magic = <<0xCA, 0x1A, 0x52>>

    # Add minimal content to make it look like a real archive
    # This is a simplified version for testing format detection
    dummy_content = :crypto.strong_rand_bytes(100)

    magic <> dummy_content
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
