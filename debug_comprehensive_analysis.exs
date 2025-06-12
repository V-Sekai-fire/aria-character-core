#!/usr/bin/env elixir

# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

# Comprehensive analysis of the 40-byte deficit
defmodule RoundtripAnalysis do
  
  def analyze_file(filename) do
    {:ok, original_data} = File.read(filename)
    IO.puts("=== Analyzing #{filename} (#{byte_size(original_data)} bytes) ===")
    
    # Parse with our implementation
    Code.require_file("apps/aria_storage/lib/aria_storage/parsers/casync_format.ex")
    
    case AriaStorage.Parsers.CasyncFormat.parse_archive(original_data) do
      {:ok, parsed} ->
        elements = parsed.elements
        
        # Encode back
        case AriaStorage.Parsers.CasyncFormat.encode_archive(parsed) do
          {:ok, encoded_data} ->
            IO.puts("Original: #{byte_size(original_data)} bytes")
            IO.puts("Encoded:  #{byte_size(encoded_data)} bytes")
            IO.puts("Deficit:  #{byte_size(original_data) - byte_size(encoded_data)} bytes")
            
            # Now analyze the discrepancy by parsing both manually
            analyze_binary_structure(original_data, encoded_data, elements)
            
          {:error, reason} ->
            IO.puts("Encoding failed: #{inspect(reason)}")
        end
        
      {:error, reason} ->
        IO.puts("Parsing failed: #{inspect(reason)}")
    end
  end
  
  def analyze_binary_structure(original, encoded, elements) do
    IO.puts("\n--- Binary Structure Analysis ---")
    
    original_elements = parse_raw_elements(original)
    encoded_elements = parse_raw_elements(encoded)
    
    IO.puts("Original has #{length(original_elements)} raw elements")
    IO.puts("Encoded has #{length(encoded_elements)} raw elements")
    IO.puts("Parsed has #{length(elements)} structured elements")
    
    # Compare each element
    compare_elements(original_elements, encoded_elements, elements)
  end
  
  def parse_raw_elements(data) do
    parse_raw_elements(data, [])
  end
  
  def parse_raw_elements(<<>>, acc), do: Enum.reverse(acc)
  
  def parse_raw_elements(<<size::little-64, type::little-64, rest::binary>>, acc) do
    data_size = size - 16
    
    case rest do
      <<element_data::binary-size(data_size), remaining::binary>> ->
        element = %{
          size: size,
          type: type,
          data: element_data,
          total_bytes: size
        }
        parse_raw_elements(remaining, [element | acc])
      _ ->
        # Not enough data
        Enum.reverse(acc)
    end
  end
  
  def parse_raw_elements(data, acc) when byte_size(data) < 16 do
    # Not enough for header
    Enum.reverse(acc)
  end
  
  def compare_elements(original_raw, encoded_raw, parsed_structured) do
    IO.puts("\n--- Element Comparison ---")
    
    max_count = max(length(original_raw), length(encoded_raw))
    max_count = max(max_count, length(parsed_structured))
    
    original_padded = original_raw ++ List.duplicate(nil, max_count - length(original_raw))
    encoded_padded = encoded_raw ++ List.duplicate(nil, max_count - length(encoded_raw))
    parsed_padded = parsed_structured ++ List.duplicate(nil, max_count - length(parsed_structured))
    
    Enum.zip([original_padded, encoded_padded, parsed_padded])
    |> Enum.with_index()
    |> Enum.each(fn {{orig, enc, parsed}, i} ->
      IO.puts("\nElement #{i + 1}:")
      
      if orig do
        IO.puts("  Original: #{orig.size} bytes, type 0x#{Integer.to_string(orig.type, 16)}")
      else
        IO.puts("  Original: MISSING")
      end
      
      if enc do
        IO.puts("  Encoded:  #{enc.size} bytes, type 0x#{Integer.to_string(enc.type, 16)}")
      else
        IO.puts("  Encoded:  MISSING")
      end
      
      if parsed do
        IO.puts("  Parsed:   type #{inspect(Map.get(parsed, :type))}")
      else
        IO.puts("  Parsed:   MISSING")
      end
      
      # Check for size differences
      cond do
        orig && enc && orig.size != enc.size ->
          IO.puts("  ⚠ SIZE MISMATCH: #{orig.size} vs #{enc.size} (diff: #{enc.size - orig.size})")
        orig && !enc ->
          IO.puts("  ⚠ MISSING ENCODED ELEMENT")
        !orig && enc ->
          IO.puts("  ⚠ EXTRA ENCODED ELEMENT")
        true ->
          if orig && enc, do: IO.puts("  ✓ Size match")
      end
    end)
  end
  
  def type_name(0x1396fabcea5bbb51), do: "ENTRY"
  def type_name(0xf453131aaeeaccb3), do: "USER"
  def type_name(0x25eb6ac969396a52), do: "GROUP"
  def type_name(0x46faf0602fd26c59), do: "SELINUX"
  def type_name(0x6dbb6ebcb3161f0b), do: "FILENAME"
  def type_name(0xac3dace369dfe643), do: "DEVICE"
  def type_name(0x8b9e1d93d6dcffc9), do: "PAYLOAD"
  def type_name(0x664a6fb6830e0d6c), do: "SYMLINK"
  def type_name(0xdfd35c5e8327c403), do: "GOODBYE"
  def type_name(other), do: "UNKNOWN(0x#{Integer.to_string(other, 16)})"
end

# Analyze the flat.catar file
RoundtripAnalysis.analyze_file("apps/aria_storage/test/support/testdata/flat.catar")
