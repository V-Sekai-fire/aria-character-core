#!/usr/bin/env elixir

# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

# Simple script to test the roundtrip without requiring the full Mix environment

Mix.install([
  {:jason, "~> 1.4"}
])

IO.puts("Testing roundtrip for: blob1.caibx")

# Read the current parser module directly
parser_file = Path.join(__DIR__, "lib/aria_storage/parsers/casync_format.ex")
{_, _} = Code.eval_file(parser_file)

alias AriaStorage.Parsers.CasyncFormat

# Read the test file
original_data = File.read!("test/support/testdata/blob1.caibx")
IO.puts("Original size: #{byte_size(original_data)} bytes")

# Parse
case CasyncFormat.parse_index(original_data) do
  {:ok, parsed} ->
    IO.puts("✅ Parsing successful")
    IO.puts("Format: #{parsed.format}")
    IO.puts("Chunks: #{length(parsed.chunks)}")
    IO.puts("Total size: #{parsed.header.total_size}")
    
    # Re-encode
    case CasyncFormat.encode_index(parsed) do
      {:ok, re_encoded_data} ->
        IO.puts("✅ Encoding successful")
        IO.puts("Re-encoded size: #{byte_size(re_encoded_data)} bytes")
        
        if original_data == re_encoded_data do
          IO.puts("✅ Perfect roundtrip!")
        else
          IO.puts("❌ Roundtrip failed - data differs")
          # Find first difference
          min_size = min(byte_size(original_data), byte_size(re_encoded_data))
          first_diff = Enum.find(0..(min_size-1), fn i ->
            :binary.at(original_data, i) != :binary.at(re_encoded_data, i)
          end)
          
          if first_diff do
            IO.puts("First difference at byte #{first_diff}")
            byte1 = :binary.at(original_data, first_diff)
            byte2 = :binary.at(re_encoded_data, first_diff)
            IO.puts("Original: #{byte1} (0x#{Integer.to_string(byte1, 16)})")
            IO.puts("Re-encoded: #{byte2} (0x#{Integer.to_string(byte2, 16)})")
          else
            IO.puts("Files differ in length: #{byte_size(original_data)} vs #{byte_size(re_encoded_data)}")
          end
        end
        
      {:error, reason} ->
        IO.puts("❌ Encoding failed: #{inspect(reason)}")
    end
    
  {:error, reason} ->
    IO.puts("❌ Parsing failed: #{inspect(reason)}")
end
