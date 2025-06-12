#!/usr/bin/env elixir

# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule RoundtripDebug do
  alias AriaStorage.Parsers.CasyncFormat

  def test_roundtrip(file_path) do
    IO.puts("Testing roundtrip for: #{Path.basename(file_path)}")
    
    case File.read(file_path) do
      {:ok, original_data} ->
        IO.puts("Original size: #{byte_size(original_data)} bytes")
        
        # Parse the data
        case CasyncFormat.parse_index(original_data) do
          {:ok, parsed} ->
            IO.puts("✅ Parsing successful")
            
            # Re-encode
            case CasyncFormat.encode_index(parsed) do
              {:ok, re_encoded_data} ->
                IO.puts("✅ Encoding successful")
                IO.puts("Re-encoded size: #{byte_size(re_encoded_data)} bytes")
                
                if original_data == re_encoded_data do
                  IO.puts("✅ Perfect roundtrip!")
                else
                  IO.puts("❌ Roundtrip failed - data differs")
                  find_first_difference(original_data, re_encoded_data)
                end
                
              {:error, reason} ->
                IO.puts("❌ Encoding failed: #{inspect(reason)}")
            end
            
          {:error, reason} ->
            IO.puts("❌ Parsing failed: #{inspect(reason)}")
        end
        
      {:error, reason} ->
        IO.puts("❌ Could not read file: #{inspect(reason)}")
    end
  end
  
  defp find_first_difference(data1, data2) do
    min_size = min(byte_size(data1), byte_size(data2))
    
    case find_difference_at(data1, data2, 0, min_size) do
      nil ->
        if byte_size(data1) != byte_size(data2) do
          IO.puts("Files differ in length: #{byte_size(data1)} vs #{byte_size(data2)}")
        else
          IO.puts("Files are identical")
        end
      index ->
        IO.puts("First difference at byte #{index}")
        show_context(data1, data2, index)
    end
  end
  
  defp find_difference_at(data1, data2, index, max_index) when index < max_index do
    byte1 = :binary.at(data1, index)
    byte2 = :binary.at(data2, index)
    
    if byte1 == byte2 do
      find_difference_at(data1, data2, index + 1, max_index)
    else
      index
    end
  end
  
  defp find_difference_at(_, _, index, max_index) when index >= max_index do
    nil
  end
  
  defp show_context(data1, data2, index) do
    start_pos = max(0, index - 8)
    end_pos = min(byte_size(data1), index + 8)
    
    original_context = :binary.part(data1, start_pos, end_pos - start_pos)
    reencoded_context = :binary.part(data2, start_pos, min(byte_size(data2), end_pos) - start_pos)
    
    IO.puts("Context around byte #{index}:")
    IO.puts("Original  : #{inspect(original_context, base: :hex)}")
    IO.puts("Re-encoded: #{inspect(reencoded_context, base: :hex)}")
    
    if index < byte_size(data1) and index < byte_size(data2) do
      byte1 = :binary.at(data1, index)
      byte2 = :binary.at(data2, index)
      IO.puts("Byte #{index}: #{byte1} (0x#{Integer.to_string(byte1, 16)}) vs #{byte2} (0x#{Integer.to_string(byte2, 16)})")
    end
  end
end

# Test with the provided file
case System.argv() do
  [file_path] ->
    RoundtripDebug.test_roundtrip(file_path)
  _ ->
    IO.puts("Usage: elixir debug_roundtrip.exs <caibx_file>")
    IO.puts("Testing with blob1.caibx by default...")
    RoundtripDebug.test_roundtrip("test/support/testdata/blob1.caibx")
end
