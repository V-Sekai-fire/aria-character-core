#!/usr/bin/env elixir

# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

Mix.install([])

# Compile the module
Code.compile_file("apps/aria_storage/lib/aria_storage/parsers/casync_format.ex")

# Test file
filename = "apps/aria_storage/test/support/testdata/flat.catar"
{:ok, original_data} = File.read(filename)

IO.puts("Testing CATAR roundtrip on #{filename}")
IO.puts("Original size: #{byte_size(original_data)} bytes")

case AriaStorage.Parsers.CasyncFormat.parse_archive(original_data) do
  {:ok, parsed} ->
    IO.puts("Parsed #{length(parsed.elements)} elements successfully")
    
    case AriaStorage.Parsers.CasyncFormat.encode_archive(parsed) do
      {:ok, encoded_data} ->
        IO.puts("Encoded size: #{byte_size(encoded_data)} bytes")
        
        difference = byte_size(encoded_data) - byte_size(original_data)
        IO.puts("Size difference: #{difference} bytes")
        
        if difference == 0 do
          if original_data == encoded_data do
            IO.puts("✅ SUCCESS: Perfect bit-exact roundtrip!")
          else
            IO.puts("⚠ Size matches but content differs")
          end
        else
          IO.puts("❌ Size mismatch: #{if difference > 0, do: "over-encoding", else: "under-encoding"} by #{abs(difference)} bytes")
        end
        
      {:error, reason} ->
        IO.puts("❌ Encoding failed: #{inspect(reason)}")
    end
  {:error, reason} ->
    IO.puts("❌ Parsing failed: #{inspect(reason)}")
end
