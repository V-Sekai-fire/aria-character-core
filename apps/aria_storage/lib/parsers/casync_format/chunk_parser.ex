# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaStorage.Parsers.CasyncFormat.ChunkParser do
  @moduledoc "Parser for ARCANA chunk files (.cacnk format).\n\nHandles parsing of compressed chunk data with headers containing\ncompression information and chunk metadata.\n"
  require AriaStorage.Parsers.CasyncFormat.Constants
  import AriaStorage.Parsers.CasyncFormat.Constants
  alias AriaStorage.Parsers.CasyncFormat.Constants
  @type parse_result :: {:ok, map()} | {:error, String.t()}
  @doc "Parse a cacnk chunk file from binary data.\n\nCACNK format structure:\n- 3-byte magic (0xCA, 0xC4, 0x4E)\n- 16-byte header (4 x 32-bit fields)\n- Compressed data payload\n"
  @spec parse_chunk(binary()) :: parse_result()
  def parse_chunk(binary_data) when is_binary(binary_data) do
    case binary_data do
      <<202, 196, 78, compressed_size::little-32, uncompressed_size::little-32,
        compression_type::little-32, flags::little-32, remaining_data::binary>> ->
        compression = decode_compression_type(compression_type)

        header = %{
          compressed_size: compressed_size,
          uncompressed_size: uncompressed_size,
          compression: compression,
          flags: flags
        }

        result = %{magic: :cacnk, header: header, data: remaining_data}
        {:ok, result}

      _ ->
        {:error, "Invalid chunk file magic"}
    end
  end

  @spec decode_compression_type(non_neg_integer()) :: Constants.compression_type()
  defp decode_compression_type(compression_type) do
    case compression_type do
      compression_none() -> :none
      compression_zstd() -> :zstd
      _ -> :unknown
    end
  end
end
