# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaStorage.TestFixtures.CasyncFixtures do
  @moduledoc """
  Test fixtures and helpers for casync/desync format testing.

  This module provides utilities for:
  - Generating test data in casync formats
  - Creating mock chunk files
  - Validating parser output
  - Comparing with reference implementations
  """

  alias AriaStorage.Parsers.CasyncFormat

  @doc """
  Creates a minimal valid .caibx index file for testing.
  """
  def create_minimal_caibx do
    # Magic header for .caibx
    magic = <<0xCA, 0x1B, 0x5C>>

    # Header: version(4) + total_size(8) + chunk_count(4) + reserved(4)
    version = <<1::little-32>>
    total_size = <<1024::little-64>>
    chunk_count = <<1::little-32>>
    reserved = <<0::little-32>>
    header = version <> total_size <> chunk_count <> reserved

    # Single chunk entry: chunk_id(32) + offset(8) + size(4) + flags(4)
    chunk_id = :crypto.strong_rand_bytes(32)  # Random SHA512/256
    offset = <<0::little-64>>
    size = <<1024::little-32>>
    flags = <<0::little-32>>
    chunk_entry = chunk_id <> offset <> size <> flags

    magic <> header <> chunk_entry
  end

  @doc """
  Creates a minimal valid .catar archive file for testing.
  """
  def create_minimal_catar do
    # Magic header for .catar
    magic = <<0xCA, 0x1A, 0x52>>

    # Single file entry header: size(8) + type(8) + flags(8) + padding(8)
    entry_size = <<64::little-64>>  # Size of the entry itself
    entry_type = <<1::little-64>>   # File type
    entry_flags = <<0::little-64>>  # No flags
    padding = <<0::little-64>>      # Padding
    entry_header = entry_size <> entry_type <> entry_flags <> padding

    # File metadata: mode(8) + uid(8) + gid(8) + mtime(8)
    mode = <<0o644::little-64>>     # Regular file permissions
    uid = <<1000::little-64>>       # User ID
    gid = <<1000::little-64>>       # Group ID
    mtime = <<1234567890::little-64>>  # Modification time
    file_metadata = mode <> uid <> gid <> mtime

    magic <> entry_header <> file_metadata
  end

  @doc """
  Creates a minimal valid .cacnk chunk file for testing.
  """
  def create_minimal_cacnk(data \\ "Hello, World!") do
    compressed_data = data  # For simplicity, not actually compressing

    # Chunk header: compressed_size(4) + uncompressed_size(4) + compression_type(4) + flags(4)
    compressed_size = <<byte_size(compressed_data)::little-32>>
    uncompressed_size = <<byte_size(data)::little-32>>
    compression_type = <<0::little-32>>  # No compression
    flags = <<0::little-32>>
    header = compressed_size <> uncompressed_size <> compression_type <> flags

    header <> compressed_data
  end

  @doc """
  Creates test data with multiple chunks for comprehensive testing.
  """
  def create_multi_chunk_caibx(chunk_count \\ 5) do
    # Magic header
    magic = <<0xCA, 0x1B, 0x5C>>

    # Calculate total size (sum of all chunk sizes)
    chunk_size = 1024
    total_size = chunk_count * chunk_size

    # Header
    version = <<1::little-32>>
    total_size_bytes = <<total_size::little-64>>
    chunk_count_bytes = <<chunk_count::little-32>>
    reserved = <<0::little-32>>
    header = version <> total_size_bytes <> chunk_count_bytes <> reserved

    # Generate chunks
    chunks = for i <- 0..(chunk_count - 1) do
      chunk_id = :crypto.hash(:sha256, "chunk_#{i}") <> :crypto.strong_rand_bytes(0)  # 32 bytes
      offset = <<i * chunk_size::little-64>>
      size = <<chunk_size::little-32>>
      flags = <<0::little-32>>
      chunk_id <> offset <> size <> flags
    end

    magic <> header <> Enum.join(chunks)
  end

  @doc """
  Creates a complex .catar archive with multiple entry types.
  """
  def create_complex_catar do
    # Magic header
    magic = <<0xCA, 0x1A, 0x52>>

    # Helper function to create an entry
    create_entry = fn type, mode, extra_data \\ "" ->
      entry_size = <<(64 + byte_size(extra_data))::little-64>>
      entry_type = <<type::little-64>>
      entry_flags = <<0::little-64>>
      padding = <<0::little-64>>
      entry_header = entry_size <> entry_type <> entry_flags <> padding

      mode_bytes = <<mode::little-64>>
      uid = <<1000::little-64>>
      gid = <<1000::little-64>>
      mtime = <<1234567890::little-64>>
      metadata = mode_bytes <> uid <> gid <> mtime

      entry_header <> metadata <> extra_data
    end

    # Create different entry types
    file_entry = create_entry.(1, 0o644)      # Regular file
    dir_entry = create_entry.(2, 0o755)       # Directory
    symlink_entry = create_entry.(3, 0o777)   # Symlink

    magic <> file_entry <> dir_entry <> symlink_entry
  end

  @doc """
  Validates that parsed output matches expected structure.
  """
  def validate_index_structure(parsed_result) do
    case parsed_result do
      %{format: format, header: header, chunks: chunks} when format in [:caibx, :caidx] ->
        validate_header_structure(header) and validate_chunks_structure(chunks)
      _ ->
        false
    end
  end

  @doc """
  Validates that parsed archive output matches expected structure.
  """
  def validate_archive_structure(parsed_result) do
    case parsed_result do
      %{format: :catar, entries: entries} ->
        validate_entries_structure(entries)
      _ ->
        false
    end
  end

  @doc """
  Generates test data that should fail parsing (for negative testing).
  """
  def create_invalid_data(type \\ :random) do
    case type do
      :random ->
        :crypto.strong_rand_bytes(100)

      :wrong_magic ->
        <<0xFF, 0xFF, 0xFF>> <> :crypto.strong_rand_bytes(100)

      :truncated_header ->
        <<0xCA, 0x1B, 0x5C, 1, 2>>  # Valid magic but truncated

      :empty ->
        ""

      :invalid_utf8 ->
        <<0xCA, 0x1B, 0x5C, 0xFF, 0xFE, 0xFD>>
    end
  end

  @doc """
  Compares parser output with reference data for regression testing.
  """
  def compare_with_reference(parsed_data, reference_file) do
    case File.read(reference_file) do
      {:ok, reference_json} ->
        reference_data = Jason.decode!(reference_json)
        normalize_for_comparison(parsed_data) == normalize_for_comparison(reference_data)

      {:error, _} ->
        # Reference file doesn't exist, create it
        File.write!(reference_file, Jason.encode!(parsed_data, pretty: true))
        true
    end
  end

  @doc """
  Creates a benchmark dataset for performance testing.
  """
  def create_benchmark_dataset do
    %{
      small_index: create_minimal_caibx(),
      medium_index: create_multi_chunk_caibx(100),
      large_index: create_multi_chunk_caibx(1000),
      small_archive: create_minimal_catar(),
      complex_archive: create_complex_catar(),
      invalid_data: create_invalid_data(:wrong_magic)
    }
  end

  @doc """
  Utility to hexdump binary data for debugging.
  """
  def hexdump(binary, bytes_per_line \\ 16) do
    binary
    |> :binary.bin_to_list()
    |> Enum.chunk_every(bytes_per_line)
    |> Enum.with_index()
    |> Enum.map(fn {chunk, index} ->
      offset = Integer.to_string(index * bytes_per_line, 16) |> String.pad_leading(8, "0")
      hex = chunk |> Enum.map(&Integer.to_string(&1, 16) |> String.pad_leading(2, "0")) |> Enum.join(" ")
      ascii = chunk |> Enum.map(&if(&1 >= 32 and &1 <= 126, do: <<&1>>, else: ".")) |> Enum.join("")

      "#{offset}: #{String.pad_trailing(hex, bytes_per_line * 3 - 1)} |#{ascii}|"
    end)
    |> Enum.join("\n")
  end

  # Private helper functions

  defp validate_header_structure(%{version: version, total_size: total_size, chunk_count: chunk_count}) do
    is_integer(version) and is_integer(total_size) and is_integer(chunk_count) and
    version >= 0 and total_size >= 0 and chunk_count >= 0
  end
  defp validate_header_structure(_), do: false

  defp validate_chunks_structure(chunks) when is_list(chunks) do
    Enum.all?(chunks, &validate_chunk_structure/1)
  end
  defp validate_chunks_structure(_), do: false

  defp validate_chunk_structure(%{chunk_id: id, offset: offset, size: size, flags: flags}) do
    is_binary(id) and byte_size(id) == 32 and
    is_integer(offset) and is_integer(size) and is_integer(flags) and
    offset >= 0 and size > 0 and flags >= 0
  end
  defp validate_chunk_structure(_), do: false

  defp validate_entries_structure(entries) when is_list(entries) do
    Enum.all?(entries, &validate_entry_structure/1)
  end
  defp validate_entries_structure(_), do: false

  defp validate_entry_structure(%{type: type, header: header}) do
    type in [:file, :directory, :symlink, :device, :fifo, :socket, :unknown] and
    is_map(header) and Map.has_key?(header, :size) and Map.has_key?(header, :flags)
  end
  defp validate_entry_structure(_), do: false

  defp normalize_for_comparison(data) when is_map(data) do
    data
    |> Enum.map(fn {k, v} -> {to_string(k), normalize_for_comparison(v)} end)
    |> Enum.sort()
    |> Map.new()
  end
  defp normalize_for_comparison(data) when is_list(data) do
    Enum.map(data, &normalize_for_comparison/1)
  end
  defp normalize_for_comparison(data) when is_binary(data) do
    Base.encode64(data)
  end
  defp normalize_for_comparison(data), do: data
end
