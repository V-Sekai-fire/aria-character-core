# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaStorage.TestFixtures.CasyncFixtures do
  @moduledoc """
  Test fixtures for generating Casync format test data.

  Provides utilities for creating synthetic Casync index (.caibx),
  archive (.catar), and chunk (.cacnk) files for testing.
  """

  @doc """
  Creates a synthetic multi-chunk caibx (Casync index) file with the specified number of chunks.
  """
  def create_multi_chunk_caibx(chunk_count) when is_integer(chunk_count) and chunk_count > 0 do
    # Create a synthetic caibx file with specified chunk count
    # This is a minimal implementation that creates binary data
    # that looks like a valid caibx file structure

    # CAIBX file format:
    # - Magic: "CAIBX\0\0\0" (8 bytes)
    # - Header with chunk count and other metadata
    # - Chunk entries (32 bytes each: 32-byte hash)

    magic = "CAIBX\0\0\0"
    _header_size = 64
    chunk_entry_size = 32

    # Create header with chunk count
    header = <<
      chunk_count::little-32,  # Number of chunks
      chunk_entry_size::little-32,  # Size of each chunk entry
      0::little-32,  # Reserved
      0::little-32,  # Reserved
      # Pad to 64 bytes
      0::size(384)
    >>

    # Create chunk entries (fake SHA256 hashes)
    chunks = for i <- 1..chunk_count do
      # Generate a fake but consistent hash for chunk i
      hash_data = "chunk_#{i}" |> String.pad_trailing(32, "\0")
      hash_data
    end

    # Combine all parts
    magic <> header <> Enum.join(chunks)
  end

  @doc """
  Creates a minimal caibx file with a single chunk.
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
        # Invalid magic header
        "WRONG\0\0\0" <> create_multi_chunk_caibx(1) |> binary_part(8, 100)

      :truncated ->
        # Truncated file
        create_multi_chunk_caibx(5) |> binary_part(0, 20)

      :corrupted_header ->
        # Valid magic but corrupted header
        magic = "CAIBX\0\0\0"
        corrupted_header = <<255, 255, 255, 255>> <> :crypto.strong_rand_bytes(60)
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

    # CATAR magic: "CATAR\0\0\0" (8 bytes)
    magic = "CATAR\0\0\0"

    # Create a simple directory entry
    entry_header = <<
      1::little-32,  # Entry type (directory)
      64::little-32,  # Entry size
      0::little-64,  # Offset
      0::little-64,  # Size
      # Pad to 64 bytes
      0::size(256)
    >>

    # Create file entries
    file_entries = for i <- 1..3 do
      filename = "file_#{i}.txt"
      content = "This is test file #{i} content."

      file_header = <<
        2::little-32,  # Entry type (file)
        (64 + byte_size(filename) + byte_size(content))::little-32,  # Total entry size
        0::little-64,  # Offset
        byte_size(content)::little-64,  # File size
        # Filename length and content
        byte_size(filename)::little-32
      >>

      file_header <> filename <> content
    end

    magic <> entry_header <> Enum.join(file_entries)
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
