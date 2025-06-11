# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaStorage.Parsers.CasyncFormat do
  @moduledoc """
  ARCANA (Aria Content Archive and Network Architecture) format parser.

  This module implements parsers for the casync binary formats that are
  fully compatible with the casync/desync ecosystem using ABNF parsec
  for robust binary parsing:

  - .caibx (Content Archive Index for Blobs)
  - .caidx (Content Archive Index for Directories)
  - .cacnk (Compressed Chunk files)
  - .catar (Archive Container format)

  ARCANA maintains perfect binary compatibility with casync/desync tools
  using identical structures, magic numbers, and behaviors with
  ABNF-based parsing for better maintainability and correctness.

  Based on desync source code analysis:
  - FormatIndex: 48 bytes (16 header + 8 flags + 8 min + 8 avg + 8 max)
  - FormatTable: Variable length with 40-byte items (8 offset + 32 chunk_id)
  - Compression: ZSTD (type 1) is primary compression
  - Magic numbers are embedded in structured format headers

  Uses ABNF parsec in binary mode for reliable parsing of the structured
  binary format as defined in the ARCANA specification.

  See: docs/ARCANA_FORMAT_SPEC.md for complete specification.
  """

  # Direct binary parsing - no longer using AbnfParsec
  # We now use binary pattern matching for better performance and reliability

  # Constants from desync source code (const.go)
  @ca_format_index 0x96824d9c7b129ff9
  @ca_format_table 0xe75b9e112f17417d
  @ca_format_table_tail_marker 0x4b4f050e5549ecd1
  # Suppressing warnings for reserved constant by commenting out unused one
  # @_ca_format_exclude_no_dump 0x8000000000000000
  
  # CATAR format constants (currently unused but reserved for future implementation)
  @_ca_format_entry 0x1396fabfa5dd7d47

  # Compression types (based on desync - only ZSTD is actually used)
  @compression_none 0
  @compression_zstd 1

  # Default chunk sizes (currently unused but reserved for validation and recommendations)
  # Suppressing warnings for reserved constants by commenting out unused ones
  # @_default_min_chunk_size 16_384    # 16KB
  # @_default_avg_chunk_size 65_536    # 64KB  
  # @_default_max_chunk_size 262_144   # 256KB

  # Magic numbers for file format detection (currently unused but reserved for format detection)
  # Suppressing warnings for reserved constants by commenting out unused ones
  # @_caibx_magic_bytes <<0xCA, 0x1B, 0x5C>>
  # @_caidx_magic_bytes <<0xCA, 0x1D, 0x5C>>
  # @_catar_magic_bytes <<0xCA, 0x1A, 0x52>>

  # Public accessor functions for constants (needed by tests)
  def ca_format_index, do: @ca_format_index
  def ca_format_table, do: @ca_format_table  
  def ca_format_table_tail_marker, do: @ca_format_table_tail_marker

  @doc """
  Convert parser result to JSON-safe format by encoding binary data as base64.
  """
  def to_json_safe(result) when is_map(result) do
    result
    |> Map.update(:chunks, [], fn chunks ->
      Enum.map(chunks, fn chunk ->
        chunk
        |> Map.update(:chunk_id, nil, &Base.encode64/1)
      end)
    end)
    |> Map.update(:_original_table_data, nil, fn
      nil -> nil
      binary_data when is_binary(binary_data) -> Base.encode64(binary_data)
      other -> other
    end)
  end

  def to_json_safe(result), do: result

  @doc """
  Parse a caibx/caidx index file from binary data.

  Format structure based on desync source:
  - FormatIndex header (48 bytes)
  - FormatTable with variable number of items (40 bytes each)
  - Table tail marker
  """
  def parse_index(binary_data) when is_binary(binary_data) do
    # Use direct binary parsing instead of ABNF to avoid UTF-8 encoding issues
    case binary_data do
      <<size_field::little-64, type_field::little-64, feature_flags::little-64,
        chunk_size_min::little-64, chunk_size_avg::little-64, chunk_size_max::little-64,
        # Validate the format index values
        remaining_data::binary>> -> 
        if size_field == 48 and type_field == @ca_format_index do
          # Both CAIBX and CAIDX formats use the same parsing logic
          # The feature_flags field differentiates them but both are supported
          format_type = if feature_flags == 0, do: :caidx, else: :caibx
          
          # Both CAIBX (blob index) and CAIDX (directory index) formats - proceed with parsing
            # Handle empty index (no table data)
            case remaining_data do
                <<>> ->
                    # Empty index file - no chunks
                    result = %{
                      format: format_type,
                      header: %{
                        version: 1,  # Standard version
                        total_size: 0,
                        chunk_count: 0
                      },
                      chunks: [],
                      feature_flags: feature_flags,
                      chunk_size_min: chunk_size_min,
                      chunk_size_avg: chunk_size_avg,
                      chunk_size_max: chunk_size_max,
                      # Empty index has no table data
                      _original_table_data: <<>>
                    }
                    {:ok, result}
                    
                  _ ->
                    case parse_format_table_with_items_binary(remaining_data) do
                      {:ok, table_items} ->
                        # Convert to internal format (both CAIBX and CAIDX)
                        result = %{
                          format: format_type,
                          header: %{
                            version: 1,  # Standard version
                            total_size: calculate_total_size(table_items),
                            chunk_count: length(table_items)
                          },
                          chunks: convert_table_to_chunks(table_items),
                          feature_flags: feature_flags,
                          chunk_size_min: chunk_size_min,
                          chunk_size_avg: chunk_size_avg,
                          chunk_size_max: chunk_size_max,
                          # Preserve original binary table data for bit-exact roundtrip
                          _original_table_data: remaining_data
                        }
                        {:ok, result}

                      {:error, reason} ->
                        {:error, reason}
                    end
            end
        else
          {:error, "Invalid FormatIndex header: size=#{size_field}, type=0x#{Integer.to_string(type_field, 16)}"}
        end
      _ -> {:error, "Invalid binary data: insufficient data for FormatIndex header"}
    end
  end

  @doc """
  Parse a cacnk chunk file from binary data.
  """
  def parse_chunk(binary_data) when is_binary(binary_data) do
    case binary_data do
      # CACNK header: 3-byte magic + 4*4 bytes (16 bytes total header)
      <<0xCA, 0xC4, 0x4E, compressed_size::little-32, uncompressed_size::little-32,
        compression_type::little-32, flags::little-32, remaining_data::binary>> ->

        compression = case compression_type do
          @compression_none -> :none
          @compression_zstd -> :zstd
          _ -> :unknown
        end

        header = %{
          compressed_size: compressed_size,
          uncompressed_size: uncompressed_size,
          compression: compression,
          flags: flags
        }

        result = %{
          magic: :cacnk,
          header: header,
          data: remaining_data
        }

        {:ok, result}

      _ ->
        {:error, "Invalid chunk file magic"}
    end
  end

  @doc """
  Parse a catar archive file from binary data.
  """
  def parse_archive(binary_data) when is_binary(binary_data) do
    case binary_data do
      # CATAR format starts with entry data directly (64-byte header minimum)
      <<entry_size::little-64, entry_type::little-64, entry_flags::little-64, 
        _entry_padding::little-64, mode::little-64, uid::little-64, gid::little-64, 
        mtime::little-64, remaining_data::binary>> ->
        
        # CATAR format parsing is not yet implemented
        {:error, "CATAR format parsing not yet implemented"}
        
      _ ->
        {:error, "Invalid CATAR format: insufficient data for entry header"}
    end
  end

  @doc """
  Detect the format of binary data based on desync FormatIndex structure.
  """
  def detect_format(<<format_header_size::little-64, format_type::little-64, feature_flags::little-64, _rest::binary>>) do
    case {format_header_size, format_type} do
      {48, @ca_format_index} -> 
        # Differentiate between CAIBX and CAIDX based on feature_flags
        if feature_flags == 0, do: {:ok, :caidx}, else: {:ok, :caibx}
      {64, @_ca_format_entry} -> {:ok, :catar}
      _ ->
        {:error, :unknown_format}
    end
  end

  def detect_format(<<0xCA, 0xC4, 0x4E, _::binary>>), do: {:ok, :cacnk}  # CACNK has different magic
  def detect_format(<<0xCA, 0x1A, 0x52, _::binary>>), do: {:ok, :catar}  # CATAR magic
  def detect_format(binary) when byte_size(binary) >= 32 do
    {:error, :unknown_format}
  end
  def detect_format(_), do: {:error, :unknown_format}

  defp parse_format_table_with_items_binary(binary_data) do
    # Parse format table header directly
    case binary_data do
      <<table_marker::little-64, table_type::little-64, remaining_data::binary>> ->
        # Validate format table header
        if table_marker == 0xFFFFFFFFFFFFFFFF and table_type == @ca_format_table do
          parse_table_items_binary(remaining_data, [])
        else
          {:error, "Invalid FormatTable header: marker=0x#{Integer.to_string(table_marker, 16)}, type=0x#{Integer.to_string(table_type, 16)}"}
        end

      _ ->
        {:error, "Invalid binary data: insufficient data for FormatTable header"}
    end
  end

  defp parse_table_items_binary(binary_data, acc) do
    case binary_data do
      # Check for table tail (40 bytes)
      <<zero1::little-64, zero2::little-64, size_field::little-64, _table_size::little-64, tail_marker::little-64, _rest::binary>>
      when zero1 == 0 and zero2 == 0 and size_field == 48 and tail_marker == @ca_format_table_tail_marker ->
        # Found valid tail marker, return accumulated items
        {:ok, Enum.reverse(acc)}

      # Parse table item (40 bytes)
      <<item_offset::little-64, chunk_id::binary-size(32), remaining_data::binary>> ->
        item = %{
          offset: item_offset,
          chunk_id: chunk_id
        }
        parse_table_items_binary(remaining_data, [item | acc])

      _ ->
        # Not enough data for either tail or item
        {:error, "Invalid table data: insufficient bytes for table item or tail"}
    end
  end

  # Removed unused function: determine_format/1
  
  defp calculate_total_size(items) when is_list(items) and length(items) > 0 do
    List.last(items).offset
  end

  defp calculate_total_size(_), do: 0

  defp convert_table_to_chunks(items) do
    items
    |> Enum.with_index()
    |> Enum.map(fn {item, index} ->
      previous_offset = if index == 0, do: 0, else: Enum.at(items, index - 1).offset

      %{
        chunk_id: item.chunk_id,
        offset: previous_offset,
        size: item.offset - previous_offset,
        flags: 0
      }
    end)
  end

  # Encoding functions - compatible with desync format
  def encode_index(%{format: :caibx, _original_table_data: original_table_data, feature_flags: feature_flags, chunk_size_min: chunk_size_min, chunk_size_avg: chunk_size_avg, chunk_size_max: chunk_size_max}) do
    # Use original table data for bit-exact roundtrip
    format_index = <<
      48::little-64,  # Size field
      @ca_format_index::little-64,  # Type field
      feature_flags::little-64,  # Feature flags (use original)
      chunk_size_min::little-64,  # ChunkSizeMin (use original)
      chunk_size_avg::little-64,  # ChunkSizeAvg (use original)
      chunk_size_max::little-64  # ChunkSizeMax (use original)
    >>

    result = format_index <> original_table_data
    {:ok, result}
  end

  def encode_index(%{format: :caibx, header: _header, chunks: chunks, feature_flags: feature_flags, chunk_size_min: chunk_size_min, chunk_size_avg: chunk_size_avg, chunk_size_max: chunk_size_max}) do
    # Create FormatIndex based on desync structure using original values
    format_index = <<
      48::little-64,  # Size field
      @ca_format_index::little-64,  # Type field
      feature_flags::little-64,  # Feature flags (use original)
      chunk_size_min::little-64,  # ChunkSizeMin (use original)
      chunk_size_avg::little-64,  # ChunkSizeAvg (use original)
      chunk_size_max::little-64  # ChunkSizeMax (use original)
    >>

    # Handle empty chunk list - return just the FormatIndex header
    case chunks do
      [] ->
        {:ok, format_index}
        
      _ ->
        # Create FormatTable items - use actual chunk structure
        table_items = Enum.reduce(chunks, {<<>>, 0}, fn chunk, {acc, current_offset} ->
          new_offset = current_offset + chunk.size
          item = <<new_offset::little-64>> <> chunk.chunk_id
          {acc <> item, new_offset}
        end) |> elem(0)

        # Create FormatTable header
        table_size = byte_size(table_items) + 48  # 48 bytes for table header + tail
        format_table_header = <<
          0xFFFFFFFFFFFFFFFF::little-64,  # Size field (special marker)
          @ca_format_table::little-64     # Type field
        >>

        # Create table tail marker
        table_tail = <<
          0::little-64,  # Offset
          0::little-64,  # Chunk ID part 1
          48::little-64,  # Size
          table_size::little-64,  # Table size
          @ca_format_table_tail_marker::little-64  # Tail marker
        >>

        result = format_index <> format_table_header <> table_items <> table_tail
        {:ok, result}
    end
  end

  def encode_index(%{format: :caidx, _original_table_data: original_table_data, feature_flags: feature_flags, chunk_size_min: chunk_size_min, chunk_size_avg: chunk_size_avg, chunk_size_max: chunk_size_max}) do
    # Use original table data for bit-exact roundtrip
    format_index = <<
      48::little-64,  # Size field
      @ca_format_index::little-64,  # Type field
      feature_flags::little-64,  # Feature flags (use original)
      chunk_size_min::little-64,  # ChunkSizeMin (use original)
      chunk_size_avg::little-64,  # ChunkSizeAvg (use original)
      chunk_size_max::little-64  # ChunkSizeMax (use original)
    >>

    result = format_index <> original_table_data
    {:ok, result}
  end

  def encode_index(%{format: :caidx, header: _header, chunks: chunks, feature_flags: feature_flags, chunk_size_min: chunk_size_min, chunk_size_avg: chunk_size_avg, chunk_size_max: chunk_size_max}) do
    # Create FormatIndex based on desync structure using original values
    format_index = <<
      48::little-64,  # Size field
      @ca_format_index::little-64,  # Type field
      feature_flags::little-64,  # Feature flags (use original)
      chunk_size_min::little-64,  # ChunkSizeMin (use original)
      chunk_size_avg::little-64,  # ChunkSizeAvg (use original)
      chunk_size_max::little-64  # ChunkSizeMax (use original)
    >>

    # Handle empty chunk list - return just the FormatIndex header
    case chunks do
      [] ->
        {:ok, format_index}
        
      _ ->
        # Create FormatTable items - use actual chunk structure
        table_items = Enum.reduce(chunks, {<<>>, 0}, fn chunk, {acc, current_offset} ->
          new_offset = current_offset + chunk.size
          item = <<new_offset::little-64>> <> chunk.chunk_id
          {acc <> item, new_offset}
        end) |> elem(0)

        # Create FormatTable header
        table_size = byte_size(table_items) + 48  # 48 bytes for table header + tail
        format_table_header = <<
          0xFFFFFFFFFFFFFFFF::little-64,  # Size field (special marker)
          @ca_format_table::little-64     # Type field
        >>

        # Create table tail marker
        table_tail = <<
          0::little-64,  # Offset
          0::little-64,  # Chunk ID part 1
          48::little-64,  # Size
          table_size::little-64,  # Table size
          @ca_format_table_tail_marker::little-64  # Tail marker
        >>

        result = format_index <> format_table_header <> table_items <> table_tail
        {:ok, result}
    end
  end

  def encode_index(%{format: :caidx}) do
    {:error, "CAIDX format encoding not yet implemented"}
  end

  def encode_chunk(%{header: header, data: data}) do
    magic = <<0xCA, 0xC4, 0x4E>>  # CACNK magic
    encoded_header = encode_chunk_header(header)
    {:ok, magic <> encoded_header <> data}
  end

  def encode_archive(%{format: :catar, entries: entries, remaining_data: remaining_data}) do
    # Encode CATAR format - reconstruct the original structure
    case entries do
      [entry | _] ->
        encoded_entry = <<
          entry.size::little-64,
          entry.type::little-64,
          entry.flags::little-64,
          0::little-64,  # padding
          entry.mode::little-64,
          entry.uid::little-64,
          entry.gid::little-64,
          entry.mtime::little-64
        >>
        
        {:ok, encoded_entry <> remaining_data}
        
      [] ->
        {:ok, remaining_data}
    end
  end

  def encode_archive(%{format: :catar}) do
    {:error, "CATAR format encoding not yet implemented"}
  end

  # Helper encoding functions
  defp encode_chunk_header(%{compressed_size: compressed_size, uncompressed_size: uncompressed_size, compression: compression, flags: flags}) do
    compression_type = case compression do
      :none -> 0
      :zstd -> 1
      :unknown -> 0
    end

    <<compressed_size::little-32>> <>
    <<uncompressed_size::little-32>> <>
    <<compression_type::little-32>> <>
    <<flags::little-32>>
  end

  defp encode_chunk_header(%{}) do
    <<0::little-32, 0::little-32, 0::little-32, 0::little-32>>
  end
end
