# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaStorage.Parsers.CasyncFormat.Utilities do
  @moduledoc "Utility functions for ARCANA format processing.\n\nProvides helper functions for format detection, hex comparison,\nroundtrip testing, and debugging binary data.\n"
  require Logger
  require AriaStorage.Parsers.CasyncFormat.Constants
  import AriaStorage.Parsers.CasyncFormat.Constants
  alias AriaStorage.Parsers.CasyncFormat.Constants

  @type comparison_result :: %{
          match: boolean(),
          size_original: non_neg_integer(),
          size_encoded: non_neg_integer(),
          differences: [tuple()]
        }
  @doc "Detect the format of binary data based on desync FormatIndex structure.\n"
  @spec detect_format(binary()) :: {:ok, Constants.format_type()} | {:error, :unknown_format}
  def detect_format(
        <<format_header_size::little-64, format_type::little-64, feature_flags::little-64,
          _rest::binary>>
      ) do
    case {format_header_size, format_type} do
      {48, ca_format_index()} ->
        if feature_flags == 0 do
          {:ok, :caidx}
        else
          {:ok, :caibx}
        end

      {64, ca_format_entry()} ->
        {:ok, :catar}

      _ ->
        {:error, :unknown_format}
    end
  end

  def detect_format(<<202, 196, 78, _::binary>>) do
    {:ok, :cacnk}
  end

  def detect_format(<<202, 26, 82, _::binary>>) do
    {:ok, :catar}
  end

  def detect_format(binary) when byte_size(binary) >= 32 do
    {:error, :unknown_format}
  end

  def detect_format(_) do
    {:error, :unknown_format}
  end

  @doc "Convert parser result to JSON-safe format by encoding binary data as base64.\n"
  @spec to_json_safe(map() | any()) :: map() | any()
  def to_json_safe(result) when is_map(result) do
    result
    |> Map.update(:chunks, [], fn chunks ->
      Enum.map(chunks, fn chunk -> chunk |> Map.update(:chunk_id, nil, &Base.encode64/1) end)
    end)
    |> Map.update(:_original_table_data, nil, fn
      nil -> nil
      binary_data when is_binary(binary_data) -> Base.encode64(binary_data)
      other -> other
    end)
  end

  def to_json_safe(result) do
    result
  end

  @doc "Compare two binary data chunks byte-by-byte and return hex diff information.\nUseful for verifying bit-exact encoding roundtrips.\n"
  @spec hex_compare(binary(), binary()) :: comparison_result()
  def hex_compare(original, encoded) when is_binary(original) and is_binary(encoded) do
    original_size = byte_size(original)
    encoded_size = byte_size(encoded)
    size_match = original_size == encoded_size

    if size_match do
      case compare_bytes(original, encoded, 0, []) do
        [] ->
          %{
            match: true,
            size_original: original_size,
            size_encoded: encoded_size,
            differences: []
          }

        differences ->
          %{
            match: false,
            size_original: original_size,
            size_encoded: encoded_size,
            differences: differences
          }
      end
    else
      %{
        match: false,
        size_original: original_size,
        size_encoded: encoded_size,
        differences: [{:size_mismatch, original_size, encoded_size}]
      }
    end
  end

  @doc "Print hex dump comparison of two binary data chunks.\n"
  @spec print_hex_diff(binary(), binary()) :: comparison_result()
  def print_hex_diff(original, encoded) do
    comparison = hex_compare(original, encoded)
    Logger.debug("=== HEX COMPARISON ===")
    Logger.debug("Original size: #{comparison.size_original} bytes")
    Logger.debug("Encoded size:  #{comparison.size_encoded} bytes")
    Logger.debug("Match: #{comparison.match}")

    if not comparison.match do
      Logger.debug("\n=== DIFFERENCES ===")

      Enum.each(comparison.differences, fn
        {:size_mismatch, orig_size, enc_size} ->
          Logger.debug("Size mismatch: original=#{orig_size}, encoded=#{enc_size}")

        {:byte_diff, offset, orig_byte, enc_byte} ->
          Logger.debug(
            "Offset 0x#{Integer.to_string(offset, 16) |> String.pad_leading(8, "0")}: " <>
              "original=0x#{Integer.to_string(orig_byte, 16) |> String.pad_leading(2, "0")} " <>
              "encoded=0x#{Integer.to_string(enc_byte, 16) |> String.pad_leading(2, "0")}"
          )
      end)

      if length(comparison.differences) > 0 do
        first_diff = hd(comparison.differences)

        case first_diff do
          {:byte_diff, offset, _, _} -> print_hex_context(original, encoded, offset)
          _ -> :ok
        end
      end
    else
      Logger.debug("✓ Binary data matches exactly!")
    end

    comparison
  end

  @doc "Test roundtrip encoding for a given binary data and format.\nReturns detailed comparison results.\n"
  @spec test_roundtrip_encoding(binary(), Constants.format_type()) ::
          {:ok, comparison_result() | :perfect_match} | {:error, String.t()}
  def test_roundtrip_encoding(binary_data, format_type) do
    Logger.debug("=== TESTING ROUNDTRIP FOR #{String.upcase(to_string(format_type))} ===")
    Logger.debug("Original size: #{byte_size(binary_data)} bytes")

    case format_type do
      :caibx -> test_index_roundtrip(binary_data)
      :caidx -> test_index_roundtrip(binary_data)
      :cacnk -> test_chunk_roundtrip(binary_data)
      :catar -> test_archive_roundtrip(binary_data)
      _ -> {:error, "Unknown format type: #{format_type}"}
    end
  end

  @doc "Test roundtrip encoding for a given file path and parsed data.\nReturns detailed comparison results.\n"
  @spec test_file_roundtrip_encoding(String.t(), map()) ::
          {:ok, :perfect_match | {:differences, comparison_result()}} | {:error, String.t()}
  def test_file_roundtrip_encoding(file_path, parsed) do
    filename = Path.basename(file_path)
    Logger.debug("=== TESTING ROUNDTRIP FOR #{filename} ===")

    case File.read(file_path) do
      {:ok, original_data} ->
        Logger.debug("Original size: #{byte_size(original_data)} bytes")

        case AriaStorage.Parsers.CasyncFormat.Encoder.encode_archive(parsed) do
          {:ok, encoded_data} ->
            Logger.info(" Encoding successful")
            Logger.debug("Encoded size: #{byte_size(encoded_data)} bytes")

            if original_data == encoded_data do
              Logger.info(" Perfect bit-exact roundtrip!")
              {:ok, :perfect_match}
            else
              Logger.debug("⚠ Size or content differences detected")
              comparison = print_hex_diff(original_data, encoded_data)
              {:ok, {:differences, comparison}}
            end

          {:error, reason} ->
            Logger.error(" Encoding failed: #{reason}")
            {:error, reason}
        end

      {:error, reason} ->
        Logger.error(" File read failed: #{reason}")
        {:error, reason}
    end
  end

  @spec compare_bytes(binary(), binary(), non_neg_integer(), [tuple()]) :: [tuple()]
  defp compare_bytes(<<>>, <<>>, _offset, acc) do
    Enum.reverse(acc)
  end

  defp compare_bytes(<<>>, _encoded, _offset, acc) do
    Enum.reverse(acc)
  end

  defp compare_bytes(_original, <<>>, _offset, acc) do
    Enum.reverse(acc)
  end

  defp compare_bytes(
         <<orig_byte, orig_rest::binary>>,
         <<enc_byte, enc_rest::binary>>,
         offset,
         acc
       ) do
    if orig_byte == enc_byte do
      compare_bytes(orig_rest, enc_rest, offset + 1, acc)
    else
      diff = {:byte_diff, offset, orig_byte, enc_byte}
      compare_bytes(orig_rest, enc_rest, offset + 1, [diff | acc])
    end
  end

  @spec print_hex_context(binary(), binary(), non_neg_integer()) :: :ok
  defp print_hex_context(original, encoded, offset) do
    start_offset = max(0, offset - 16)
    length = min(32, byte_size(original) - start_offset)
    Logger.debug("
=== HEX CONTEXT AROUND OFFSET 0x#{Integer.to_string(offset, 16) |> String.upcase()} ===")
    orig_chunk = binary_part(original, start_offset, length)

    enc_chunk =
      if byte_size(encoded) >= start_offset + length do
        binary_part(encoded, start_offset, length)
      else
        <<>>
      end

    Logger.debug("Original:")
    print_hex_dump(orig_chunk, start_offset)
    Logger.debug("\nEncoded:")
    print_hex_dump(enc_chunk, start_offset)
  end

  @spec print_hex_dump(binary(), non_neg_integer()) :: :ok
  defp print_hex_dump(binary, base_offset) do
    binary
    |> :binary.bin_to_list()
    |> Enum.chunk_every(16)
    |> Enum.with_index()
    |> Enum.each(fn {bytes, row} ->
      offset = base_offset + row * 16

      hex_part =
        bytes
        |> Enum.map_join(" ", &(Integer.to_string(&1, 16) |> String.pad_leading(2, "0")))
        |> String.pad_trailing(47)

      ascii_part =
        Enum.map_join(bytes, "", fn b ->
          if b >= 32 and b <= 126 do
            <<b>>
          else
            "."
          end
        end)

      Logger.debug(
        "#{Integer.to_string(offset, 16) |> String.pad_leading(8, "0") |> String.upcase()}: #{hex_part} |#{ascii_part}|"
      )
    end)
  end

  @spec test_index_roundtrip(binary()) :: {:ok, comparison_result()} | {:error, String.t()}
  defp test_index_roundtrip(binary_data) do
    case AriaStorage.Parsers.CasyncFormat.IndexParser.parse_index(binary_data) do
      {:ok, parsed} ->
        Logger.debug("✓ Parsing successful")
        Logger.debug("  Format: #{parsed.format}")
        Logger.debug("  Chunks: #{length(parsed.chunks)}")

        case AriaStorage.Parsers.CasyncFormat.Encoder.encode_index(parsed) do
          {:ok, encoded} ->
            Logger.debug("✓ Encoding successful")
            comparison = print_hex_diff(binary_data, encoded)
            {:ok, comparison}
        end

      {:error, reason} ->
        Logger.debug("✗ Parsing failed: #{reason}")
        {:error, reason}
    end
  end

  @spec test_chunk_roundtrip(binary()) :: {:ok, comparison_result()} | {:error, String.t()}
  defp test_chunk_roundtrip(binary_data) do
    case AriaStorage.Parsers.CasyncFormat.ChunkParser.parse_chunk(binary_data) do
      {:ok, parsed} ->
        Logger.debug("✓ Parsing successful")
        Logger.debug("  Magic: #{parsed.magic}")
        Logger.debug("  Compression: #{parsed.header.compression}")

        case AriaStorage.Parsers.CasyncFormat.Encoder.encode_chunk(parsed) do
          {:ok, encoded} ->
            Logger.debug("✓ Encoding successful")
            comparison = print_hex_diff(binary_data, encoded)
            {:ok, comparison}
        end

      {:error, reason} ->
        Logger.debug("✗ Parsing failed: #{reason}")
        {:error, reason}
    end
  end

  @spec test_archive_roundtrip(binary()) :: {:ok, comparison_result()} | {:error, String.t()}
  defp test_archive_roundtrip(binary_data) do
    case AriaStorage.Parsers.CasyncFormat.ArchiveParser.parse_archive(binary_data) do
      {:ok, parsed} ->
        Logger.debug("✓ Parsing successful")
        Logger.debug("  Format: #{parsed.format}")
        Logger.debug("  Elements: #{length(parsed.elements)}")
        Logger.debug("  Files: #{length(parsed.files)}")
        Logger.debug("  Directories: #{length(parsed.directories)}")

        case AriaStorage.Parsers.CasyncFormat.Encoder.encode_archive(parsed) do
          {:ok, encoded} ->
            Logger.debug("✓ Encoding successful")
            comparison = print_hex_diff(binary_data, encoded)
            {:ok, comparison}

          {:error, reason} ->
            Logger.debug("✗ Encoding failed: #{reason}")
            {:error, reason}
        end

      {:error, reason} ->
        Logger.debug("✗ Parsing failed: #{reason}")
        {:error, reason}
    end
  end
end
