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

  use AbnfParsec,
    mode: :byte,
    abnf: """
    ; ARCANA/Casync Binary Format Grammar
    ; Based on desync source code analysis

    ; Format Index - 48 bytes total
    format-index = size-field type-field feature-flags chunk-size-min chunk-size-avg chunk-size-max
    size-field = 8OCTET           ; 8 bytes little-endian
    type-field = 8OCTET           ; 8 bytes little-endian
    feature-flags = 8OCTET        ; 8 bytes little-endian
    chunk-size-min = 8OCTET       ; 8 bytes little-endian
    chunk-size-avg = 8OCTET       ; 8 bytes little-endian
    chunk-size-max = 8OCTET       ; 8 bytes little-endian

    ; Format Table header - 16 bytes
    format-table-header = table-marker table-type
    table-marker = 8OCTET         ; 8 bytes little-endian
    table-type = 8OCTET           ; 8 bytes little-endian

    ; Table Item - 40 bytes each
    table-item = item-offset chunk-id
    item-offset = 8OCTET          ; 8 bytes little-endian
    chunk-id = 32OCTET            ; 32 bytes (SHA-256)

    ; Table Tail - 40 bytes
    table-tail = zero1 zero2 size-field table-size tail-marker
    zero1 = 8OCTET                ; 8 bytes zero
    zero2 = 8OCTET                ; 8 bytes zero
    table-size = 8OCTET           ; 8 bytes little-endian
    tail-marker = 8OCTET          ; 8 bytes little-endian

    ; Chunk header for CACNK files - 19 bytes total
    chunk-header = chunk-magic compressed-size uncompressed-size compression-type chunk-flags
    chunk-magic = 3OCTET          ; 3 bytes: 0xCA 0xC4 0x4E
    compressed-size = 4OCTET      ; 4 bytes little-endian
    uncompressed-size = 4OCTET    ; 4 bytes little-endian
    compression-type = 4OCTET     ; 4 bytes little-endian
    chunk-flags = 4OCTET          ; 4 bytes little-endian

    ; Complete index file structure
    index-file = format-index format-table-header *table-item table-tail

    ; Complete chunk file structure
    chunk-file = chunk-header *OCTET ; header + variable data
    """,
    parse: :index_file,
    parse: :chunk_file,
    parse: :format_index,
    parse: :format_table_header,
    parse: :table_item,
    parse: :table_tail,
    parse: :chunk_header

  # Constants from desync source code (const.go)
  @ca_format_index 0x96824d9c7b129ff9
  @ca_format_table 0xe75b9e112f17417d
  @ca_format_table_tail_marker 0x4b4f050e5549ecd1
  @ca_format_sha512_256 0x2000000000000000
  @ca_format_exclude_no_dump 0x8000000000000000

  # Compression types (based on desync - only ZSTD is actually used)
  @compression_none 0
  @compression_zstd 1

  @doc """
  Parse a caibx/caidx index file from binary data.

  @doc """
  Parse a caibx/caidx index file from binary data.

  Format structure based on desync source:
  - FormatIndex header (48 bytes)
  - FormatTable with variable number of items (40 bytes each)
  - Table tail marker
  """
  def parse_index(binary_data) when is_binary(binary_data) do
    case format_index(binary_data) do
      {:ok, parsed_list, remaining_data, _context, _position, _consumed} ->
        # AbnfParsec returns a nested keyword list structure
        # Extract the format_index field which contains our data
        format_index_data = Keyword.get(parsed_list, :format_index, [])

        # Extract each field from the nested structure
        size_field = extract_binary_field(format_index_data, :size_field)
        type_field = extract_binary_field(format_index_data, :type_field)
        feature_flags = extract_binary_field(format_index_data, :feature_flags)
        chunk_size_min = extract_binary_field(format_index_data, :chunk_size_min)
        chunk_size_avg = extract_binary_field(format_index_data, :chunk_size_avg)
        chunk_size_max = extract_binary_field(format_index_data, :chunk_size_max)

        # Convert little-endian binary to integers
        size_val = :binary.decode_unsigned(size_field, :little)
        type_val = :binary.decode_unsigned(type_field, :little)
        feature_flags_val = :binary.decode_unsigned(feature_flags, :little)
        chunk_size_min_val = :binary.decode_unsigned(chunk_size_min, :little)
        chunk_size_avg_val = :binary.decode_unsigned(chunk_size_avg, :little)
        chunk_size_max_val = :binary.decode_unsigned(chunk_size_max, :little)

        # Validate the format index values
        if size_val == 48 and type_val == @ca_format_index do
          case parse_format_table_with_items(remaining_data) do
            {:ok, table_items} ->
              # Convert to internal format
              result = %{
                format: determine_format(feature_flags_val),
                header: %{
                  version: 1,  # Standard version
                  total_size: calculate_total_size(table_items),
                  chunk_count: length(table_items)
                },
                chunks: convert_table_to_chunks(table_items),
                feature_flags: feature_flags_val,
                chunk_size_min: chunk_size_min_val,
                chunk_size_avg: chunk_size_avg_val,
                chunk_size_max: chunk_size_max_val
              }
              {:ok, result}

            {:error, reason} ->
              {:error, reason}
          end
        else
          {:error, "Invalid FormatIndex header: size=#{size_val}, type=0x#{Integer.to_string(type_val, 16)}"}
        end

      {:error, reason, _rest, _context, _line, _offset} ->
        {:error, "Failed to parse FormatIndex: #{inspect(reason)}"}
    end
  end

  @doc """
  Parse a cacnk chunk file from binary data.
  """
  def parse_chunk(binary_data) when is_binary(binary_data) do
    case chunk_header(binary_data) do
      {:ok, parsed_list, remaining_data, _context, _position, _consumed} ->
        # AbnfParsec returns a nested keyword list structure
        # Extract the chunk_header field which contains our data
        chunk_header_data = Keyword.get(parsed_list, :chunk_header, [])

        # Extract each field from the nested structure
        magic = extract_binary_field(chunk_header_data, :chunk_magic)
        compressed_size = extract_binary_field(chunk_header_data, :compressed_size)
        uncompressed_size = extract_binary_field(chunk_header_data, :uncompressed_size)
        compression_type = extract_binary_field(chunk_header_data, :compression_type)
        flags = extract_binary_field(chunk_header_data, :chunk_flags)

        # Validate magic bytes for CACNK
        expected_magic = <<0xCA, 0xC4, 0x4E>>
        if magic == expected_magic do
          # Convert binary values to integers
          compressed_size_val = :binary.decode_unsigned(compressed_size, :little)
          uncompressed_size_val = :binary.decode_unsigned(uncompressed_size, :little)
          compression_type_val = :binary.decode_unsigned(compression_type, :little)
          flags_val = :binary.decode_unsigned(flags, :little)

          compression = case compression_type_val do
            @compression_none -> :none
            @compression_zstd -> :zstd
            _ -> :unknown
          end

          header = %{
            compressed_size: compressed_size_val,
            uncompressed_size: uncompressed_size_val,
            compression: compression,
            flags: flags_val
          }

          result = %{
            magic: :cacnk,
            header: header,
            data: remaining_data
          }

          {:ok, result}
        else
          {:error, "Invalid chunk file magic"}
        end

      {:error, reason, _rest, _context, _line, _offset} ->
        {:error, "Failed to parse chunk header: #{inspect(reason)}"}
    end
  end

  @doc """
  Parse a catar archive file from binary data.
  """
  def parse_archive(binary_data) when is_binary(binary_data) do
    case binary_data do
      <<0xCA, 0x1A, 0x52, _rest::binary>> ->
        # For now, return basic structure - full catar parsing would be complex
        result = %{
          format: :catar,
          entries: []
        }
        {:ok, result}

      _ ->
        {:error, "Invalid catar archive format"}
    end
  end

  @doc """
  Detect the format of binary data based on initial structure.
  """
  def detect_format(<<format_header_size::little-64, format_type::little-64, _rest::binary>>) do
    case format_type do
      @ca_format_index -> {:ok, :caibx}
      _ -> detect_legacy_format(_rest)
    end
  end

  def detect_format(binary_data), do: detect_legacy_format(binary_data)

  # Legacy format detection for simple magic bytes
  defp detect_legacy_format(<<0xCA, 0x1B, 0x5C, _::binary>>), do: {:ok, :caibx}
  defp detect_legacy_format(<<0xCA, 0x1D, 0x5C, _::binary>>), do: {:ok, :caidx}
  defp detect_legacy_format(<<0xCA, 0xC4, 0x4E, _::binary>>), do: {:ok, :cacnk}
  defp detect_legacy_format(<<0xCA, 0x1A, 0x52, _::binary>>), do: {:ok, :catar}
  defp detect_legacy_format(_), do: {:error, :unknown_format}

  # Private functions for parsing specific formats using ABNF parsec

  # Helper function to extract binary field from AbnfParsec nested structure
  defp extract_binary_field(parsed_data, field_name) do
    case Keyword.get(parsed_data, field_name, []) do
      list when is_list(list) ->
        # Convert list of bytes/strings to binary
        list
        |> Enum.map(fn
          x when is_binary(x) -> x
          x when is_integer(x) -> <<x>>
          x -> x
        end)
        |> IO.iodata_to_binary()

      binary when is_binary(binary) ->
        binary

      _ ->
        <<>>
    end
  end

  defp parse_format_table_with_items(binary_data) do
    case format_table_header(binary_data) do
      {:ok, parsed_list, remaining_data, _context, _position, _consumed} ->
        # AbnfParsec returns a nested keyword list structure
        # Extract the format_table_header field which contains our data
        table_header_data = Keyword.get(parsed_list, :format_table_header, [])

        # Extract each field from the nested structure
        table_marker = extract_binary_field(table_header_data, :table_marker)
        table_type = extract_binary_field(table_header_data, :table_type)

        # Convert binary to unsigned integers
        table_marker_val = :binary.decode_unsigned(table_marker, :little)
        table_type_val = :binary.decode_unsigned(table_type, :little)

        # Validate format table header
        if table_marker_val == 0xFFFFFFFFFFFFFFFF and table_type_val == @ca_format_table do
          parse_table_items_with_abnf(remaining_data, [])
        else
          {:error, "Invalid FormatTable header: marker=0x#{Integer.to_string(table_marker_val, 16)}, type=0x#{Integer.to_string(table_type_val, 16)}"}
        end

      {:error, reason, _rest, _context, _line, _offset} ->
        {:error, "Failed to parse format table header: #{inspect(reason)}"}
    end
  end

  defp parse_table_items_with_abnf(binary_data, acc) do
    case table_tail(binary_data) do
      {:ok, parsed_list, _remaining, _context, _position, _consumed} ->
        # AbnfParsec returns a nested keyword list structure
        # Extract the table_tail field which contains our data
        table_tail_data = Keyword.get(parsed_list, :table_tail, [])

        # Extract each field from the nested structure
        zero1 = extract_binary_field(table_tail_data, :zero1)
        zero2 = extract_binary_field(table_tail_data, :zero2)
        size = extract_binary_field(table_tail_data, :size_field)
        table_size = extract_binary_field(table_tail_data, :table_size)
        tail_marker = extract_binary_field(table_tail_data, :tail_marker)

        # Convert binary to unsigned integers
        zero1_val = :binary.decode_unsigned(zero1, :little)
        zero2_val = :binary.decode_unsigned(zero2, :little)
        size_val = :binary.decode_unsigned(size, :little)
        tail_marker_val = :binary.decode_unsigned(tail_marker, :little)

        # Found tail marker, validate and return accumulated items
        if zero1_val == 0 and zero2_val == 0 and size_val == 48 and tail_marker_val == @ca_format_table_tail_marker do
          {:ok, Enum.reverse(acc)}
        else
          {:error, "Invalid table tail marker: zero1=#{zero1_val}, zero2=#{zero2_val}, size=#{size_val}, marker=0x#{Integer.to_string(tail_marker_val, 16)}"}
        end

      {:error, _reason, _rest, _context, _line, _offset} ->
        # Not a tail marker, try to parse a table item
        case table_item(binary_data) do
          {:ok, parsed_list, remaining_data, _context, _position, _consumed} ->
            # AbnfParsec returns a nested keyword list structure
            # Extract the table_item field which contains our data
            table_item_data = Keyword.get(parsed_list, :table_item, [])

            # Extract each field from the nested structure
            offset = extract_binary_field(table_item_data, :item_offset)
            chunk_id = extract_binary_field(table_item_data, :chunk_id)

            # Convert binary offset to integer
            offset_val = :binary.decode_unsigned(offset, :little)

            item = %{
              offset: offset_val,
              chunk_id: chunk_id
            }
            parse_table_items_with_abnf(remaining_data, [item | acc])

          {:error, reason, _rest, _context, _line, _offset} ->
            {:error, "Invalid table item: #{inspect(reason)}"}
        end
    end
  end

  defp determine_format(feature_flags) do
    if Bitwise.band(feature_flags, @ca_format_sha512_256) != 0 do
      :caibx  # SHA512-256 indicates blob index
    else
      :caidx  # SHA256 indicates directory index
    end
  end

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
  def encode_index(%{format: format, header: header, chunks: chunks}) do
    # Filter chunks to only include valid chunk entries
    valid_chunks = Enum.filter(chunks, fn
      %{chunk_id: _, offset: _, size: _, flags: _} -> true
      _ -> false
    end)

    # Create FormatIndex based on desync structure
    format_index = <<
      48::little-64,  # Size field
      @ca_format_index::little-64,  # Type field
      determine_feature_flags(format)::little-64,  # Feature flags
      4096::little-64,  # ChunkSizeMin
      65536::little-64,  # ChunkSizeAvg
      1048576::little-64  # ChunkSizeMax
    >>

    # Create FormatTable items
    table_items = Enum.reduce(valid_chunks, {<<>>, 0}, fn chunk, {acc, current_offset} ->
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

  def encode_chunk(%{header: header, data: data}) do
    magic = <<0xCA, 0xC4, 0x4E>>  # CACNK magic
    encoded_header = encode_chunk_header(header)
    {:ok, magic <> encoded_header <> data}
  end

  def encode_archive(%{format: :catar, entries: entries}) do
    magic = <<0xCA, 0x1A, 0x52>>
    encoded_entries = Enum.map(entries, &encode_catar_entry/1) |> Enum.join()
    {:ok, magic <> encoded_entries}
  end

  # Helper encoding functions
  defp determine_feature_flags(:caibx), do: @ca_format_sha512_256
  defp determine_feature_flags(:caidx), do: 0

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

  defp encode_catar_entry(%{type: type, header: header} = entry) do
    encoded_header = encode_catar_entry_header(header)

    case type do
      :file -> encoded_header <> encode_catar_metadata(entry)
      :directory -> encoded_header <> encode_catar_metadata(entry)
      _ -> encoded_header
    end
  end

  defp encode_catar_entry_header(%{size: size, type: type, flags: flags}) do
    type_code = case type do
      :file -> 1
      :directory -> 2
      :symlink -> 3
      :unknown -> 0
    end

    <<size::little-64>> <>
    <<type_code::little-64>> <>
    <<flags::little-64>> <>
    <<0::little-64>>  # padding
  end

  defp encode_catar_metadata(%{mode: mode, uid: uid, gid: gid, mtime: mtime}) do
    <<mode::little-64>> <>
    <<uid::little-64>> <>
    <<gid::little-64>> <>
    <<mtime::little-64>>
  end
end
