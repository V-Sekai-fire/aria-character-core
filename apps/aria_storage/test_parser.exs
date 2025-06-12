#!/usr/bin/env elixir

# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

# Simple CLI test script for CasyncFormat parser
# Usage: elixir -S mix run test_parser.exs

# This script should be run with: elixir -S mix run test_parser.exs

defmodule TestParser do
  alias AriaStorage.Parsers.CasyncFormat

  def run do
    IO.puts("=== ARIA Storage Parser CLI Test ===\n")

    testdata_path = Path.join([__DIR__, "test", "support", "testdata"])

    if File.exists?(testdata_path) do
      test_caibx_files(testdata_path)
      test_catar_files(testdata_path)
      test_format_detection(testdata_path)
    else
      IO.puts("❌ Testdata directory not found: #{testdata_path}")
      System.halt(1)
    end
  end

  defp test_caibx_files(testdata_path) do
    IO.puts("🔍 Testing CAIBX files...")

    caibx_files = Path.wildcard(Path.join(testdata_path, "*.caibx"))

    if Enum.empty?(caibx_files) do
      IO.puts("⚠️  No CAIBX files found")
    else
    Enum.each(caibx_files, fn file_path ->
      filename = Path.basename(file_path)
      IO.write("  Testing #{filename}... ")

      case File.read(file_path) do
        {:ok, data} ->
          case CasyncFormat.parse_index(data) do
            {:ok, result} ->
              IO.puts("✅ OK (#{result.header.chunk_count} chunks, #{result.header.total_size} bytes)")

            {:error, reason} ->
              IO.puts("❌ FAILED: #{reason}")
          end

        {:error, reason} ->
          IO.puts("❌ File read error: #{reason}")
      end
    end)
    end

    IO.puts("")
  end

  defp test_catar_files(testdata_path) do
    IO.puts("🔍 Testing CATAR files...")

    catar_files = Path.wildcard(Path.join(testdata_path, "*.catar"))

    if Enum.empty?(catar_files) do
      IO.puts("⚠️  No CATAR files found")
    else
    Enum.each(catar_files, fn file_path ->
      filename = Path.basename(file_path)
      IO.write("  Testing #{filename}... ")

      case File.read(file_path) do
        {:ok, data} ->
          case CasyncFormat.parse_archive(data) do
            {:ok, result} ->
              IO.puts("✅ OK (#{length(result.entries)} entries)")

            {:error, reason} ->
              IO.puts("❌ FAILED: #{reason}")
          end

        {:error, reason} ->
          IO.puts("❌ File read error: #{reason}")
      end
    end)
    end

    IO.puts("")
  end

  defp test_format_detection(testdata_path) do
    IO.puts("🔍 Testing format detection...")

    test_files = [
      {"blob1.caibx", :caibx},
      {"blob2.caibx", :caibx},
      {"flat.catar", :catar},
      {"nested.catar", :catar},
      {"complex.catar", :catar}
    ]

    Enum.each(test_files, fn {filename, expected_format} ->
      file_path = Path.join(testdata_path, filename)
      IO.write("  Detecting #{filename}... ")

      if File.exists?(file_path) do
        case File.read(file_path) do
          {:ok, data} ->
            case CasyncFormat.detect_format(data) do
              {:ok, detected_format} ->
                if detected_format == expected_format do
                  IO.puts("✅ OK (#{detected_format})")
                else
                  IO.puts("❌ WRONG: expected #{expected_format}, got #{detected_format}")
                end

              {:error, reason} ->
                IO.puts("❌ FAILED: #{reason}")
            end

          {:error, reason} ->
            IO.puts("❌ File read error: #{reason}")
        end
      else
        IO.puts("⚠️  File not found")
      end
    end)

    IO.puts("")
  end

  defp test_hex_debug(file_path, bytes \\ 32) do
    IO.puts("🔍 Hex dump of #{Path.basename(file_path)}:")

    case File.read(file_path) do
      {:ok, data} ->
        data
        |> binary_part(0, min(bytes, byte_size(data)))
        |> Base.encode16()
        |> String.graphemes()
        |> Enum.chunk_every(2)
        |> Enum.map(&Enum.join/1)
        |> Enum.chunk_every(16)
        |> Enum.with_index()
        |> Enum.each(fn {chunk, index} ->
          offset = index * 16
          hex_part = chunk |> Enum.join(" ")
          IO.puts("  #{String.pad_leading(Integer.to_string(offset, 16), 8, "0")}: #{hex_part}")
        end)

      {:error, reason} ->
        IO.puts("❌ File read error: #{reason}")
    end

    IO.puts("")
  end

  def debug_file(filename) do
    testdata_path = Path.join([__DIR__, "test", "support", "testdata"])
    file_path = Path.join(testdata_path, filename)

    IO.puts("=== Debug: #{filename} ===")
    test_hex_debug(file_path, 64)

    case File.read(file_path) do
      {:ok, data} ->
        IO.puts("File size: #{byte_size(data)} bytes")

        # Try to parse with ABNF directly
        IO.puts("\nTesting ABNF format_index parser...")
        case CasyncFormat.format_index(data) do
          {:ok, parsed_list, remaining_data, _context, _position, _consumed} ->
            IO.puts("✅ ABNF parse successful!")
            IO.puts("Parsed structure: #{inspect(parsed_list, limit: :infinity)}")
            IO.puts("Remaining data size: #{byte_size(remaining_data)}")

            # Test the extract_binary_field function
            IO.puts("\nTesting field extraction...")
            format_index_data = Keyword.get(parsed_list, :format_index, [])

            # Extract fields manually to debug
            size_field_raw = Keyword.get(format_index_data, :size_field, [])
            type_field_raw = Keyword.get(format_index_data, :type_field, [])

            IO.puts("size_field raw: #{inspect(size_field_raw)}")
            IO.puts("type_field raw: #{inspect(type_field_raw)}")

            size_field = debug_extract_binary_field(size_field_raw)
            type_field = debug_extract_binary_field(type_field_raw)

            IO.puts("size_field extracted: #{inspect(size_field)} (#{Base.encode16(size_field)})")
            IO.puts("type_field extracted: #{inspect(type_field)} (#{Base.encode16(type_field)})")

            size_val = :binary.decode_unsigned(size_field, :little)
            type_val = :binary.decode_unsigned(type_field, :little)

            IO.puts("size_val: #{size_val}")
            IO.puts("type_val: 0x#{Integer.to_string(type_val, 16)}")
            IO.puts("Expected type: 0x96824d9c7b129ff9")

          {:error, reason, _rest, _context, _line, _offset} ->
            IO.puts("❌ ABNF parse failed: #{inspect(reason)}")
        end

      {:error, reason} ->
        IO.puts("❌ File read error: #{reason}")
    end
  end  # Debug version of extract_binary_field
  defp debug_extract_binary_field(list) when is_list(list) do
    result = list
    |> Enum.map(fn
      str when is_binary(str) and byte_size(str) == 1 ->
        # Single character string - these are actually raw bytes, not UTF-8 characters
        # We need to get the actual byte value, not the UTF-8 interpretation
        case :binary.bin_to_list(str) do
          [byte] ->
            IO.puts("  Converting string '#{str}' to byte #{byte} (0x#{Integer.to_string(byte, 16)})")
            byte
          _ ->
            byte = :binary.first(str)
            IO.puts("  Converting string '#{str}' to byte #{byte} (0x#{Integer.to_string(byte, 16)}) [fallback]")
            byte
        end
      bin when is_binary(bin) ->
        # Multi-byte binary - convert to list of bytes
        bytes = :binary.bin_to_list(bin)
        IO.puts("  Converting binary #{inspect(bin)} to bytes #{inspect(bytes)}")
        bytes
      int when is_integer(int) ->
        # Single byte as integer
        IO.puts("  Using integer #{int} as-is")
        int
      other ->
        # Fallback - convert to iodata and extract bytes
        bytes = other
        |> IO.iodata_to_binary()
        |> :binary.bin_to_list()
        IO.puts("  Converting other #{inspect(other)} -> bytes #{inspect(bytes)}")
        bytes
    end)
    |> List.flatten()
    |> :binary.list_to_bin()

    IO.puts("  Final result: #{inspect(result)} (#{Base.encode16(result)})")
    result
  end
end

# Run the tests
case System.argv() do
  ["debug", filename] ->
    TestParser.debug_file(filename)
  _ ->
    TestParser.run()
end
