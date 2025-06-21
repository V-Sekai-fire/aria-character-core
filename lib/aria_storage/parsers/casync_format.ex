# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaStorage.Parsers.CasyncFormat do
  @moduledoc """
  Parser for the ARCANA (Aria Content Archive) format.

  ARCANA is based on the casync format specification and provides parsing
  for CAIBX/CAIDX index files, CACNK chunk files, and CATAR archive files.

  This implementation is based on analysis of the desync source code and
  provides bit-exact compatibility with casync/desync tools.

  ## Format Support

  - **CAIBX**: Content Archive Index for Blobs
  - **CAIDX**: Content Archive Index for Directories  
  - **CACNK**: Content Archive Chunk (compressed data)
  - **CATAR**: Content Archive (tar-like archive format)

  ## Usage

      # Parse any supported format
      {:ok, result} = AriaStorage.Parsers.CasyncFormat.parse(binary_data)

      # Parse specific formats
      {:ok, index} = AriaStorage.Parsers.CasyncFormat.parse_index(caibx_data)
      {:ok, chunk} = AriaStorage.Parsers.CasyncFormat.parse_chunk(cacnk_data)
      {:ok, archive} = AriaStorage.Parsers.CasyncFormat.parse_archive(catar_data)

      # Encode back to binary
      {:ok, binary} = AriaStorage.Parsers.CasyncFormat.encode_index(index)
      {:ok, binary} = AriaStorage.Parsers.CasyncFormat.encode_chunk(chunk)
      {:ok, binary} = AriaStorage.Parsers.CasyncFormat.encode_archive(archive)

  ## Implementation Notes

  This parser handles the complex binary format used by casync/desync tools,
  including variable-length elements, different UID/GID encoding schemes,
  and proper handling of padding and alignment requirements.

  The implementation is split into focused modules:
  - `Constants` - Format constants and type definitions
  - `IndexParser` - CAIBX/CAIDX parsing logic
  - `ChunkParser` - CACNK parsing logic
  - `ArchiveParser` - CATAR parsing logic
  - `Encoder` - Encoding functions for all formats
  - `Utilities` - Helper functions and testing utilities
  """

  alias AriaStorage.Parsers.CasyncFormat.{
    Constants,
    IndexParser,
    ChunkParser,
    ArchiveParser,
    Encoder,
    Utilities
  }

  # Re-export types from Constants for backward compatibility
  @type format_type :: Constants.format_type()
  @type compression_type :: Constants.compression_type()
  @type catar_element_type :: Constants.catar_element_type()
  @type chunk_item :: Constants.chunk_item()
  @type table_item :: Constants.table_item()
  @type index_header :: Constants.index_header()
  @type chunk_header :: Constants.chunk_header()
  @type catar_element :: Constants.catar_element()

  @type parse_result :: {:ok, map()} | {:error, String.t()}
  @type encode_result :: {:ok, binary()} | {:error, String.t()}

  @doc """
  Parse binary data and automatically detect the format.

  Supports CAIBX, CAIDX, CACNK, and CATAR formats.
  """
  @spec parse(binary()) :: parse_result()
  def parse(binary_data) when is_binary(binary_data) do
    case Utilities.detect_format(binary_data) do
      {:ok, :caibx} -> parse_index(binary_data)
      {:ok, :caidx} -> parse_index(binary_data)
      {:ok, :cacnk} -> parse_chunk(binary_data)
      {:ok, :catar} -> parse_archive(binary_data)
      {:error, :unknown_format} -> {:error, "Unknown or unsupported format"}
    end
  end

  @doc """
  Parse a caibx/caidx index file from binary data.

  Format structure based on desync source:
  - FormatIndex header (48 bytes)
  - FormatTable with variable number of items (40 bytes each)
  - Table tail marker
  """
  @spec parse_index(binary()) :: parse_result()
  def parse_index(binary_data) when is_binary(binary_data) do
    IndexParser.parse_index(binary_data)
  end

  @doc """
  Parse a cacnk chunk file from binary data.

  CACNK format structure:
  - 3-byte magic (0xCA, 0xC4, 0x4E)
  - 16-byte header (4 x 32-bit fields)
  - Compressed data payload
  """
  @spec parse_chunk(binary()) :: parse_result()
  def parse_chunk(binary_data) when is_binary(binary_data) do
    ChunkParser.parse_chunk(binary_data)
  end

  @doc """
  Parse a catar archive file from binary data.

  CATAR format contains a sequence of elements representing files, directories,
  and metadata in a structured format compatible with casync/desync tools.
  """
  @spec parse_archive(binary()) :: parse_result()
  def parse_archive(binary_data) when is_binary(binary_data) do
    ArchiveParser.parse_archive(binary_data)
  end

  @doc """
  Encode index data to binary format (CAIBX/CAIDX).

  Supports both blob index (CAIBX) and directory index (CAIDX) formats
  with bit-exact roundtrip encoding when original table data is preserved.
  """
  @spec encode_index(map()) :: encode_result()
  def encode_index(index_data) do
    Encoder.encode_index(index_data)
  end

  @doc """
  Encode chunk data to binary format (CACNK).

  Creates a CACNK file with proper magic bytes and header information.
  """
  @spec encode_chunk(map()) :: encode_result()
  def encode_chunk(chunk_data) do
    Encoder.encode_chunk(chunk_data)
  end

  @doc """
  Encode archive data to binary format (CATAR).

  Supports encoding from elements structure for full compatibility
  with casync/desync CATAR format.
  """
  @spec encode_archive(map()) :: encode_result()
  def encode_archive(archive_data) do
    Encoder.encode_archive(archive_data)
  end

  @doc """
  Detect the format of binary data based on desync FormatIndex structure.
  """
  @spec detect_format(binary()) :: {:ok, format_type()} | {:error, :unknown_format}
  def detect_format(binary_data) do
    Utilities.detect_format(binary_data)
  end

  @doc """
  Convert parser result to JSON-safe format by encoding binary data as base64.
  """
  @spec to_json_safe(map() | any()) :: map() | any()
  def to_json_safe(result) do
    Utilities.to_json_safe(result)
  end

  @doc """
  Compare two binary data chunks byte-by-byte and return hex diff information.
  Useful for verifying bit-exact encoding roundtrips.
  """
  @spec hex_compare(binary(), binary()) :: Utilities.comparison_result()
  def hex_compare(original, encoded) do
    Utilities.hex_compare(original, encoded)
  end

  @doc """
  Print hex dump comparison of two binary data chunks.
  """
  @spec print_hex_diff(binary(), binary()) :: Utilities.comparison_result()
  def print_hex_diff(original, encoded) do
    Utilities.print_hex_diff(original, encoded)
  end

  @doc """
  Test roundtrip encoding for a given binary data and format.
  Returns detailed comparison results.
  """
  @spec test_roundtrip_encoding(binary(), format_type()) :: {:ok, Utilities.comparison_result() | :perfect_match} | {:error, String.t()}
  def test_roundtrip_encoding(binary_data, format_type) do
    Utilities.test_roundtrip_encoding(binary_data, format_type)
  end

  @doc """
  Test roundtrip encoding for a given file path and parsed data.
  Returns detailed comparison results.
  """
  @spec test_file_roundtrip_encoding(String.t(), map()) :: {:ok, :perfect_match | {:differences, Utilities.comparison_result()}} | {:error, String.t()}
  def test_file_roundtrip_encoding(file_path, parsed) do
    Utilities.test_file_roundtrip_encoding(file_path, parsed)
  end

  # Legacy compatibility functions - delegate to Constants module
  require Constants
  @doc false
  def ca_format_index, do: Constants.ca_format_index()
  @doc false
  def ca_format_table, do: Constants.ca_format_table()
  @doc false
  def ca_format_table_tail_marker, do: Constants.ca_format_table_tail_marker()
end
