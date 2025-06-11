# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaStorage.Parsers.CasyncFormat do
  @moduledoc """
  NimbleParsec parser for casync/desync binary formats.

  This module implements parsers for:
  - .caibx (chunk index for blobs)
  - .caidx (chunk index for catar archives)
  - .cacnk (compressed chunk files)
  - .catar (archive format)

  Based on the casync/desync format specifications.
  """

  import NimbleParsec

  # Decoder functions - handle both NimbleParsec callbacks and direct calls

  def decode_uint32le([a, b, c, d]) do
    <<value::little-32>> = <<a, b, c, d>>
    value
  end

  def decode_uint64le([a, b, c, d, e, f, g, h]) do
    <<value::little-64>> = <<a, b, c, d, e, f, g, h>>
    value
  end

  # Helper functions
  defp decode_compression_type(0), do: :none
  defp decode_compression_type(1), do: :zstd
  defp decode_compression_type(2), do: :xz
  defp decode_compression_type(3), do: :gzip
  defp decode_compression_type(_), do: :unknown

  # NimbleParsec map callback functions (called with individual parsed arguments)
  def decode_index_header(version, total_size, chunk_count, _reserved) do
    %{
      version: version,
      total_size: total_size,
      chunk_count: chunk_count
    }
  end

  def decode_chunk_entry([chunk_id_bytes, offset, size, flags]) when is_list(chunk_id_bytes) do
    %{
      chunk_id: :erlang.list_to_binary(chunk_id_bytes),
      offset: offset,
      size: size,
      flags: flags
    }
  end

  def decode_chunk_entry(chunk_data) do
    # Fallback for unexpected structure
    %{
      chunk_id: <<>>,
      offset: 0,
      size: 0,
      flags: 0
    }
  end

  def decode_index_file(format, header, chunks) do
    %{
      format: format,
      header: header,
      chunks: chunks
    }
  end

  def decode_chunk_header(compressed_size, uncompressed_size, compression_type, flags) do
    compression = case compression_type do
      0 -> :none
      1 -> :zstd
      _ -> :unknown
    end

    %{
      compressed_size: compressed_size,
      uncompressed_size: uncompressed_size,
      compression: compression,
      flags: flags
    }
  end

  def decode_chunk_file(header, data) do
    %{
      header: header,
      data: :erlang.list_to_binary(data)
    }
  end

  def decode_catar_entry_header(size, type, flags, _padding) do
    entry_type = case type do
      1 -> :file
      2 -> :directory
      3 -> :symlink
      4 -> :device
      5 -> :fifo
      6 -> :socket
      _ -> :unknown
    end

    %{
      size: size,
      type: entry_type,
      flags: flags
    }
  end

  def decode_catar_file_entry(header, mode, uid, gid, mtime) do
    %{
      type: :file,
      header: header,
      mode: mode,
      uid: uid,
      gid: gid,
      mtime: mtime
    }
  end

  def decode_catar_dir_entry(header, mode, uid, gid, mtime) do
    %{
      type: :directory,
      header: header,
      mode: mode,
      uid: uid,
      gid: gid,
      mtime: mtime
    }
  end

  def decode_catar_symlink_entry(header, mode, uid, gid, mtime) do
    %{
      type: :symlink,
      header: header,
      mode: mode,
      uid: uid,
      gid: gid,
      mtime: mtime
    }
  end

  def decode_catar_file(_magic, entries) do
    %{
      format: :catar,
      entries: entries
    }
  end

  # Single argument versions for compatibility when called directly
  def decode_index_header(single_arg) when is_integer(single_arg) do
    %{
      version: single_arg,
      total_size: 0,
      chunk_count: 0
    }
  end

  def decode_chunk_entry(single_arg) when is_integer(single_arg) do
    %{
      chunk_id: <<single_arg::32>>,
      offset: 0,
      size: single_arg,
      flags: 0
    }
  end

  def decode_index_file([format, version, total_size, chunk_count, _reserved | chunks]) when is_list(chunks) do
    # Build header
    header = %{
      version: version,
      total_size: total_size,
      chunk_count: chunk_count
    }

    %{
      format: format,
      header: header,
      chunks: chunks
    }
  end

  def decode_index_file(format_atom) when is_atom(format_atom) do
    # Handle case where we get just the format atom
    %{
      format: format_atom,
      header: %{},
      chunks: []
    }
  end

  def decode_index_file(single_value) when is_integer(single_value) do
    # Handle case where we get individual integer values
    %{
      format: :unknown,
      header: %{version: single_value, total_size: 0, chunk_count: 0},
      chunks: []
    }
  end

  # Helper function to parse raw chunk data
  defp parse_raw_chunks([], acc), do: Enum.reverse(acc)
  defp parse_raw_chunks(raw_chunks, acc) when length(raw_chunks) < 48 do
    # Not enough data for a complete chunk, stop
    Enum.reverse(acc)
  end
  defp parse_raw_chunks(raw_chunks, acc) do
    {chunk_id_bytes, rest1} = Enum.split(raw_chunks, 32)
    {offset_bytes, rest2} = Enum.split(rest1, 8)
    {size_bytes, rest3} = Enum.split(rest2, 4)
    {flags_bytes, remaining} = Enum.split(rest3, 4)

    chunk = %{
      chunk_id: :erlang.list_to_binary(chunk_id_bytes),
      offset: decode_uint64le(offset_bytes),
      size: decode_uint32le(size_bytes),
      flags: decode_uint32le(flags_bytes)
    }

    parse_raw_chunks(remaining, [chunk | acc])
  end

  def decode_chunk_header([compressed_size, uncompressed_size, compression_type, flags]) do
    %{
      compressed_size: compressed_size,
      uncompressed_size: uncompressed_size,
      compression: decode_compression_type(compression_type),
      flags: flags
    }
  end

  def decode_chunk_file([magic, header | data_bytes]) do
    %{
      magic: magic,
      header: header,
      data: :erlang.list_to_binary(data_bytes)
    }
  end

  def decode_catar_entry_header([size, type, flags, _padding]) do
    entry_type = case type do
      1 -> :file
      2 -> :directory
      3 -> :symlink
      4 -> :device
      5 -> :fifo
      6 -> :socket
      _ -> :unknown
    end

    %{
      size: size,
      type: entry_type,
      flags: flags
    }
  end

  def decode_catar_entry_header(single_value) when is_integer(single_value) do
    %{
      size: single_value,
      type: :unknown,
      flags: 0
    }
  end

  def decode_catar_file_entry([size, type, flags, _padding | rest]) do
    %{
      type: :file,
      header: %{size: size, type: type, flags: flags},
      mode: 0,
      uid: 0,
      gid: 0,
      mtime: 0,
      content: rest
    }
  end

  def decode_catar_file_entry(single_value) when is_integer(single_value) do
    %{
      type: :file,
      header: %{size: single_value, type: :unknown, flags: 0},
      mode: 0,
      uid: 0,
      gid: 0,
      mtime: single_value,
      content: []
    }
  end

  def decode_catar_file_entry(map_result) when is_map(map_result) do
    %{
      type: :file,
      header: map_result,
      mode: 0,
      uid: 0,
      gid: 0,
      mtime: 0,
      content: []
    }
  end

  def decode_catar_dir_entry(single_arg) when is_map(single_arg) do
    %{
      type: :directory,
      header: single_arg,
      mode: 0,
      uid: 0,
      gid: 0,
      mtime: 0
    }
  end

  def decode_catar_symlink_entry(single_arg) when is_map(single_arg) do
    %{
      type: :symlink,
      header: single_arg,
      mode: 0,
      uid: 0,
      gid: 0,
      mtime: 0
    }
  end

  def decode_catar_file(single_arg) when is_atom(single_arg) do
    %{
      format: :catar,
      entries: []
    }
  end

  def decode_catar_file(map_entry) when is_map(map_entry) do
    %{
      format: :catar,
      entries: [map_entry]
    }
  end

  # NimbleParsec combinators

  # Basic data types
  uint32le = times(ascii_char([0..255]), 4) |> reduce({__MODULE__, :decode_uint32le, []})
  uint64le = times(ascii_char([0..255]), 8) |> reduce({__MODULE__, :decode_uint64le, []})

  # Magic headers
  caibx_magic = string(<<0xCA, 0x1B, 0x5C>>) |> replace(:caibx)
  caidx_magic = string(<<0xCA, 0x1D, 0x5C>>) |> replace(:caidx)
  catar_magic = string(<<0xCA, 0x1A, 0x52>>) |> replace(:catar)
  cacnk_magic = string(<<0xCA, 0xC4, 0x4E>>) |> replace(:cacnk)

  # Index header: version (4), total_size (8), chunk_count (4), reserved (4)
  index_header =
    uint32le
    |> concat(uint64le)
    |> concat(uint32le)
    |> concat(uint32le)

  # Chunk entry: chunk_id (32 bytes), offset (8), size (4), flags (4)
  chunk_entry =
    times(ascii_char([0..255]), 32)
    |> concat(uint64le)
    |> concat(uint32le)
    |> concat(uint32le)
    |> map({__MODULE__, :decode_chunk_entry, []})

  # Index file format
  index_file =
    choice([caibx_magic, caidx_magic])
    |> concat(index_header)
    |> repeat(chunk_entry)
    |> map({__MODULE__, :decode_index_file, []})

  # Chunk header: compressed_size (4), uncompressed_size (4), compression_type (4), flags (4)
  chunk_header =
    uint32le
    |> concat(uint32le)
    |> concat(uint32le)
    |> concat(uint32le)
    |> map({__MODULE__, :decode_chunk_header, []})

  # Chunk file format
  chunk_file =
    cacnk_magic
    |> concat(chunk_header)
    |> repeat(ascii_char([0..255]))
    |> map({__MODULE__, :decode_chunk_file, []})

  # Catar entry header: size (8), type (8), flags (8), padding (8)
  catar_entry_header =
    uint64le
    |> concat(uint64le)
    |> concat(uint64le)
    |> concat(uint64le)
    |> map({__MODULE__, :decode_catar_entry_header, []})

  # Catar metadata: mode (8), uid (8), gid (8), mtime (8)
  catar_metadata =
    uint64le
    |> concat(uint64le)
    |> concat(uint64le)
    |> concat(uint64le)

  # Catar entry types
  catar_file_entry =
    catar_entry_header
    |> concat(catar_metadata)
    |> map({__MODULE__, :decode_catar_file_entry, []})

  catar_dir_entry =
    catar_entry_header
    |> concat(catar_metadata)
    |> map({__MODULE__, :decode_catar_dir_entry, []})

  catar_symlink_entry =
    catar_entry_header
    |> concat(catar_metadata)
    |> map({__MODULE__, :decode_catar_symlink_entry, []})

  # Catar file format
  catar_file =
    catar_magic
    |> repeat(choice([catar_file_entry, catar_dir_entry, catar_symlink_entry]))
    |> map({__MODULE__, :decode_catar_file, []})

  # Parse entry points
  defparsec(:index_file, index_file)
  defparsec(:chunk_file, chunk_file)
  defparsec(:catar_file, catar_file)

  # Public API

  @doc """
  Parses a .caibx or .caidx index file.
  """
  def parse_index(binary_data) when is_binary(binary_data) do
    case index_file(binary_data) do
      {:ok, result_list, "", _, _, _} when is_list(result_list) ->
        # FIX: Convert list of results to single unified result
        unified_result = combine_parser_results(result_list)
        {:ok, unified_result}
      {:ok, result, "", _, _, _} ->
        {:ok, result}
      {:ok, result_list, remaining, _, _, _} when is_list(result_list) ->
        unified_result = combine_parser_results(result_list)
        {:ok, unified_result, byte_size(remaining)}
      {:ok, result, remaining, _, _, _} ->
        {:ok, result, byte_size(remaining)}
      {:error, reason, _rest, _context, _line, _offset} ->
        {:error, reason}
    end
  end

  # Helper function to combine parser results into expected structure
  defp combine_parser_results(result_list) when is_list(result_list) do
    # Find the main format/structure from the results
    format = find_format_from_results(result_list)
    header = find_header_from_results(result_list)
    chunks = find_chunks_from_results(result_list)

    %{
      format: format,
      header: header,
      chunks: chunks
    }
  end

  defp find_format_from_results(results) do
    results
    |> Enum.find_value(fn
      %{format: format} when format != :unknown -> format
      _ -> nil
    end) || :unknown
  end

  defp find_header_from_results(results) do
    results
    |> Enum.find_value(fn
      %{header: header} when map_size(header) > 0 -> header
      %{version: _, total_size: _, chunk_count: _} = header -> header
      _ -> nil
    end) || %{}
  end

  defp find_chunks_from_results(results) do
    results
    |> Enum.flat_map(fn
      %{chunks: chunks} when is_list(chunks) -> chunks
      %{chunk_id: _, offset: _, size: _, flags: _} = chunk -> [chunk]
      _ -> []
    end)
  end

  # Helper function for combining chunk parser results
  defp combine_chunk_results(result_list) when is_list(result_list) do
    # Find the magic header and chunk data
    magic = find_magic_from_results(result_list)
    header = find_chunk_header_from_results(result_list)
    data = find_chunk_data_from_results(result_list)

    %{
      magic: magic,
      header: header,
      data: data
    }
  end

  # Helper function for combining archive parser results
  defp combine_archive_results(result_list) when is_list(result_list) do
    # Find all entries from the results
    entries = find_archive_entries_from_results(result_list)

    %{
      format: :catar,
      entries: entries
    }
  end

  defp find_magic_from_results(results) do
    results
    |> Enum.find_value(fn
      %{magic: magic} -> magic
      _ -> nil
    end) || :cacnk
  end

  defp find_chunk_header_from_results(results) do
    results
    |> Enum.find_value(fn
      %{header: header} when is_map(header) -> header
      %{compressed_size: _, uncompressed_size: _, compression: _, flags: _} = header -> header
      _ -> nil
    end) || %{}
  end

  defp find_chunk_data_from_results(results) do
    results
    |> Enum.find_value(fn
      %{data: data} when is_binary(data) -> data
      _ -> nil
    end) || <<>>
  end

  defp find_archive_entries_from_results(results) do
    results
    |> Enum.flat_map(fn
      %{entries: entries} when is_list(entries) -> entries
      %{type: _, header: _, mode: _, uid: _, gid: _, mtime: _} = entry -> [entry]
      _ -> []
    end)
  end

  @doc """
  Parses a .cacnk chunk file.
  """
  def parse_chunk(binary_data) when is_binary(binary_data) do
    case chunk_file(binary_data) do
      {:ok, result_list, "", _, _, _} when is_list(result_list) ->
        # FIX: Convert list of results to single unified result
        unified_result = combine_chunk_results(result_list)
        {:ok, unified_result}
      {:ok, result, "", _, _, _} -> {:ok, result}
      {:ok, result_list, remaining, _, _, _} when is_list(result_list) ->
        unified_result = combine_chunk_results(result_list)
        {:ok, unified_result, byte_size(remaining)}
      {:ok, result, remaining, _, _, _} ->
        {:ok, result, byte_size(remaining)}
      {:error, reason, _rest, _context, _line, _offset} ->
        {:error, reason}
    end
  end

  @doc """
  Parses a .catar archive file.
  """
  def parse_archive(binary_data) when is_binary(binary_data) do
    case catar_file(binary_data) do
      {:ok, result_list, "", _, _, _} when is_list(result_list) ->
        # FIX: Convert list of results to single unified result
        unified_result = combine_archive_results(result_list)
        {:ok, unified_result}
      {:ok, result, "", _, _, _} -> {:ok, result}
      {:ok, result_list, remaining, _, _, _} when is_list(result_list) ->
        unified_result = combine_archive_results(result_list)
        {:ok, unified_result, byte_size(remaining)}
      {:ok, result, remaining, _, _, _} ->
        {:ok, result, byte_size(remaining)}
      {:error, reason, _rest, _context, _line, _offset} ->
        {:error, reason}
    end
  end

  @doc """
  Detects the format of a binary file based on magic headers.
  """
  def detect_format(<<0xCA, 0x1B, 0x5C, _rest::binary>>), do: {:ok, :caibx}
  def detect_format(<<0xCA, 0x1D, 0x5C, _rest::binary>>), do: {:ok, :caidx}
  def detect_format(<<0xCA, 0x1A, 0x52, _rest::binary>>), do: {:ok, :catar}
  def detect_format(_), do: {:error, :unknown_format}

  # Encoding functions

  @doc """
  Encodes a parsed index structure back to binary format.
  """
  def encode_index(%{format: format, header: header, chunks: chunks}) do
    magic = case format do
      :caibx -> <<0xCA, 0x1B, 0x5C>>
      :caidx -> <<0xCA, 0x1D, 0x5C>>
    end

    encoded_header = encode_index_header(header)
    encoded_chunks = Enum.map(chunks, &encode_chunk_entry/1) |> Enum.join()

    {:ok, magic <> encoded_header <> encoded_chunks}
  end

  @doc """
  Encodes a parsed chunk structure back to binary format.
  """
  def encode_chunk(%{header: header, data: data}) do
    magic = <<0xCA, 0xC4, 0x4E>>  # CACNK magic
    encoded_header = encode_chunk_header(header)
    {:ok, magic <> encoded_header <> data}
  end

  def encode_chunk(%{magic: magic, header: header, data: data}) do
    encoded_header = encode_chunk_header(header)
    {:ok, magic <> encoded_header <> data}
  end

  @doc """
  Encodes a parsed archive structure back to binary format.
  """
  def encode_archive(%{format: :catar, entries: entries}) do
    magic = <<0xCA, 0x1A, 0x52>>
    encoded_entries = Enum.map(entries, &encode_catar_entry/1) |> Enum.join()
    {:ok, magic <> encoded_entries}
  end

  # Private encoding helper functions

  defp encode_index_header(%{version: version, total_size: total_size, chunk_count: chunk_count}) do
    <<version::little-32>> <>
    <<total_size::little-64>> <>
    <<chunk_count::little-32>> <>
    <<0::little-32>>  # reserved
  end

  defp encode_chunk_entry(%{chunk_id: chunk_id, offset: offset, size: size, flags: flags}) do
    chunk_id <>
    <<offset::little-64>> <>
    <<size::little-32>> <>
    <<flags::little-32>>
  end

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

  defp encode_catar_entry(%{type: type, header: header} = entry) do
    encoded_header = encode_catar_entry_header(header)

    case type do
      :file -> encoded_header <> encode_catar_metadata(entry)
      :directory -> encoded_header <> encode_catar_metadata(entry)
      :symlink -> encoded_header <> encode_catar_metadata(entry)
      _ -> encoded_header
    end
  end

  defp encode_catar_entry_header(%{size: size, type: type, flags: flags}) do
    type_code = case type do
      :file -> 1
      :directory -> 2
      :symlink -> 3
      :device -> 4
      :fifo -> 5
      :socket -> 6
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
