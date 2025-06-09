# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaStorage.Parsers.CasyncFormat do
  @moduledoc """
  ABNF parser for casync/desync binary formats.

  This module implements parsers for:
  - .caibx (chunk index for blobs)
  - .caidx (chunk index for catar archives)
  - .cacnk (compressed chunk files)
  - .catar (archive format)

  Based on the casync/desync format specifications.
  """

  import NimbleParsec

  # Define parsec grammar for casync formats

  # Basic types
  defparsec :uint32le,
    times(ascii_char([0..255]), 4)
    |> map({__MODULE__, :decode_uint32le, []})

  defparsec :uint64le,
    times(ascii_char([0..255]), 8)
    |> map({__MODULE__, :decode_uint64le, []})

  defparsec :sha512_256_hash,
    times(ascii_char([0..255]), 32)

  # Magic headers
  defparsec :caibx_magic,
    ascii_char([0xCA])
    |> ascii_char([0x1B])
    |> ascii_char([0x5C])

  defparsec :caidx_magic,
    ascii_char([0xCA])
    |> ascii_char([0x1D])
    |> ascii_char([0x5C])

  defparsec :catar_magic,
    ascii_char([0xCA])
    |> ascii_char([0x1A])
    |> ascii_char([0x52])

  # Index file header
  defparsec :index_header,
    parsec(:uint32le)  # version
    |> parsec(:uint64le)  # total_size
    |> parsec(:uint32le)  # chunk_count
    |> parsec(:uint32le)  # reserved
    |> map({__MODULE__, :decode_index_header, []})

  # Chunk entry in index
  defparsec :chunk_entry,
    parsec(:sha512_256_hash)  # chunk_id
    |> parsec(:uint64le)      # offset
    |> parsec(:uint32le)      # size
    |> parsec(:uint32le)      # flags
    |> map({__MODULE__, :decode_chunk_entry, []})

  # Index file format (.caibx/.caidx)
  defparsec :index_file,
    choice([
      parsec(:caibx_magic) |> replace(:caibx),
      parsec(:caidx_magic) |> replace(:caidx)
    ])
    |> parsec(:index_header)
    |> times(parsec(:chunk_entry), min: 0)
    |> map({__MODULE__, :decode_index_file, []})

  # Chunk file header (.cacnk)
  defparsec :chunk_header,
    parsec(:uint32le)  # compressed_size
    |> parsec(:uint32le)  # uncompressed_size
    |> parsec(:uint32le)  # compression_type (0=none, 1=zstd)
    |> parsec(:uint32le)  # flags
    |> map({__MODULE__, :decode_chunk_header, []})

  # Chunk file format (.cacnk)
  defparsec :chunk_file,
    parsec(:chunk_header)
    |> repeat(ascii_char([0..255]))  # chunk_data
    |> map({__MODULE__, :decode_chunk_file, []})

  # Archive entry header (.catar)
  defparsec :catar_entry_header,
    parsec(:uint64le)  # size
    |> parsec(:uint64le)  # type
    |> parsec(:uint64le)  # flags
    |> times(ascii_char([0..255]), 8)  # padding
    |> map({__MODULE__, :decode_catar_entry_header, []})

  # File entry in archive
  defparsec :catar_file_entry,
    parsec(:catar_entry_header)
    |> parsec(:uint64le)  # mode
    |> parsec(:uint64le)  # uid
    |> parsec(:uint64le)  # gid
    |> parsec(:uint64le)  # mtime
    |> map({__MODULE__, :decode_catar_file_entry, []})

  # Directory entry in archive
  defparsec :catar_dir_entry,
    parsec(:catar_entry_header)
    |> parsec(:uint64le)  # mode
    |> parsec(:uint64le)  # uid
    |> parsec(:uint64le)  # gid
    |> parsec(:uint64le)  # mtime
    |> map({__MODULE__, :decode_catar_dir_entry, []})

  # Symlink entry in archive
  defparsec :catar_symlink_entry,
    parsec(:catar_entry_header)
    |> parsec(:uint64le)  # mode
    |> parsec(:uint64le)  # uid
    |> parsec(:uint64le)  # gid
    |> parsec(:uint64le)  # mtime
    |> map({__MODULE__, :decode_catar_symlink_entry, []})

  # Archive format (.catar)
  defparsec :catar_file,
    parsec(:catar_magic)
    |> times(
      choice([
        parsec(:catar_file_entry),
        parsec(:catar_dir_entry),
        parsec(:catar_symlink_entry)
      ]), min: 0
    )
    |> map({__MODULE__, :decode_catar_file, []})

  # Decoder functions

  def decode_uint32le([a, b, c, d]) do
    <<value::little-32>> = <<a, b, c, d>>
    value
  end

  def decode_uint64le([a, b, c, d, e, f, g, h]) do
    <<value::little-64>> = <<a, b, c, d, e, f, g, h>>
    value
  end

  def decode_index_header([version, total_size, chunk_count, _reserved]) do
    %{
      version: version,
      total_size: total_size,
      chunk_count: chunk_count
    }
  end

  def decode_chunk_entry([chunk_id, offset, size, flags]) do
    %{
      chunk_id: :erlang.list_to_binary(chunk_id),
      offset: offset,
      size: size,
      flags: flags
    }
  end

  def decode_index_file([format, header, chunks]) do
    %{
      format: format,
      header: header,
      chunks: chunks
    }
  end

  def decode_chunk_header([compressed_size, uncompressed_size, compression_type, flags]) do
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

  def decode_chunk_file([header, data]) do
    %{
      header: header,
      data: :erlang.list_to_binary(data)
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

  def decode_catar_file_entry([header, mode, uid, gid, mtime]) do
    %{
      type: :file,
      header: header,
      mode: mode,
      uid: uid,
      gid: gid,
      mtime: mtime
    }
  end

  def decode_catar_dir_entry([header, mode, uid, gid, mtime]) do
    %{
      type: :directory,
      header: header,
      mode: mode,
      uid: uid,
      gid: gid,
      mtime: mtime
    }
  end

  def decode_catar_symlink_entry([header, mode, uid, gid, mtime]) do
    %{
      type: :symlink,
      header: header,
      mode: mode,
      uid: uid,
      gid: gid,
      mtime: mtime
    }
  end

  def decode_catar_file([_magic, entries]) do
    %{
      format: :catar,
      entries: entries
    }
  end

  # Public API

  @doc """
  Parses a .caibx or .caidx index file.
  """
  def parse_index(binary_data) when is_binary(binary_data) do
    case index_file(binary_data) do
      {:ok, result, "", _, _, _} -> {:ok, result}
      {:ok, result, remaining, _, _, _} ->
        {:ok, result, byte_size(remaining)}
      {:error, reason, _rest, _context, _line, _offset} ->
        {:error, reason}
    end
  end

  @doc """
  Parses a .cacnk chunk file.
  """
  def parse_chunk(binary_data) when is_binary(binary_data) do
    case chunk_file(binary_data) do
      {:ok, result, "", _, _, _} -> {:ok, result}
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
      {:ok, result, "", _, _, _} -> {:ok, result}
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
end
