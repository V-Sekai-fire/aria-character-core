# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaStorage.TestFixtures.CasyncFixtures do
  @moduledoc """
  Test fixtures for generating ARCANA format test data.

  Provides utilities for creating synthetic ARCANA index (.arcx),
  archive (.arca), and chunk (.arcc) files for testing.
  Compatible with casync/desync (.caibx/.caidx/.catar/.cacnk) formats.
  """

  # Constants from desync source (matching parser)
  @ca_format_index 0x96824D9C7B129FF9
  @ca_format_table 0xE75B9E112F17417D
  @ca_format_table_tail_marker 0x4B4F050E5549ECD1
  @ca_format_sha512_256 0x2000000000000000
  @ca_format_entry 0x1396FABCEA5BBB51

  @doc """
  Creates a synthetic multi-chunk ARCX (caibx-compatible) file with the specified number of chunks.
  Generates proper desync FormatIndex/FormatTable structure.
  """
  def create_multi_chunk_caibx(chunk_count, feature_flags \\ @ca_format_sha512_256)
      when is_integer(chunk_count) and chunk_count > 0 do
    # Create desync-compatible binary format
    # FormatIndex (48 bytes): 8-byte size + 8-byte type + 32 bytes of fields
    format_index = <<
      # Size of FormatIndex
      48::little-64,
      # Magic for FormatIndex
      @ca_format_index::little-64,
      # Feature flags (SHA512-256 for blobs)
      feature_flags::little-64,
      # chunk_size_min
      1024::little-64,
      # chunk_size_avg
      1024::little-64,
      # chunk_size_max
      1024::little-64
    >>

    # FormatTable header (16 bytes)
    table_header = <<
      # Table marker
      0xFFFFFFFFFFFFFFFF::little-64,
      # Table type
      @ca_format_table::little-64
    >>

    # Create table items (40 bytes each: 8-byte offset + 32-byte chunk_id)
    table_items =
      for i <- 1..chunk_count do
        chunk_id = :crypto.hash(:sha256, "test_chunk_#{i}")
        # Each chunk ends at 1KB intervals (cumulative offsets)
        offset = i * 1024
        <<offset::little-64, chunk_id::binary-size(32)>>
      end

    table_items_binary = Enum.join(table_items)
    # 16 bytes header + 40 bytes tail
    table_size = byte_size(table_items_binary) + 48

    # Table tail marker (40 bytes)
    table_tail = <<
      # Zero offset
      0::little-64,
      # Zero pad
      0::little-64,
      # Size field
      48::little-64,
      # Table size
      table_size::little-64,
      # Tail marker
      @ca_format_table_tail_marker::little-64
    >>

    # Combine all parts
    format_index <> table_header <> table_items_binary <> table_tail
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
    # CATAR files start directly with entry data, no magic bytes
    # Create a simple directory entry using proper CATAR format constants
    # size
    # type (CaFormatEntry)
    # feature_flags
    # mode (directory permissions)
    # field5 (unknown, set to 0)
    # gid
    # uid
    # mtime
    entry_header =
      <<64::little-64>> <>
        <<@ca_format_entry::little-64>> <>
        <<0::little-64>> <>
        <<0o755::little-64>> <>
        <<0::little-64>> <>
        <<1000::little-64>> <>
        <<1000::little-64>> <>
        <<1_640_995_200::little-64>>

    entry_header
  end

  @doc """
  Creates a catar entry with specified parameters.
  """
  def create_catar_entry(feature_flags, mode, uid, gid, mtime) do
    cond do
      # CaFormatWith16BitUIDs
      Bitwise.band(feature_flags, 0x1) != 0 ->
        # Size for 16-bit UIDs/GIDs
        size = 52

        <<
          size::little-64,
          @ca_format_entry::little-64,
          feature_flags::little-64,
          mode::little-64,
          # field5 (unknown, set to 0)
          0::little-64,
          gid::little-16,
          uid::little-16,
          mtime::little-64
        >>

      # CaFormatWith32BitUIDs
      Bitwise.band(feature_flags, 0x2) != 0 ->
        # Size for 32-bit UIDs/GIDs
        size = 56

        <<
          size::little-64,
          @ca_format_entry::little-64,
          feature_flags::little-64,
          mode::little-64,
          # field5 (unknown, set to 0)
          0::little-64,
          gid::little-32,
          uid::little-32,
          mtime::little-64
        >>

      true ->
        # Size for 64-bit UIDs/GIDs (default)
        size = 64

        <<
          size::little-64,
          @ca_format_entry::little-64,
          feature_flags::little-64,
          mode::little-64,
          # field5 (unknown, set to 0)
          0::little-64,
          gid::little-64,
          uid::little-64,
          mtime::little-64
        >>
    end
  end

  @doc """
  Validates the structure of a parsed index file.
  """
  def validate_index_structure(parsed_result) do
    case parsed_result do
      %{chunks: chunks, header: header} when is_list(chunks) and is_map(header) ->
        # Validate that all chunks have required fields and header is present
        has_valid_chunks =
          Enum.all?(chunks, fn chunk ->
            is_map(chunk) and
              Map.has_key?(chunk, :chunk_id) and
              Map.has_key?(chunk, :size) and
              Map.has_key?(chunk, :offset)
          end)

        has_valid_header =
          Map.has_key?(header, :chunk_count) and
            Map.has_key?(header, :total_size)

        has_valid_chunks and has_valid_header

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
      :xlarge -> create_multi_chunk_caibx(10_000)
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
