#!/usr/bin/env elixir

# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

# Debug script to analyze the exact 40-byte size difference in CATAR roundtrip encoding
# This script will compare original vs encoded data element by element

Code.require_file("apps/aria_storage/lib/aria_storage/parsers/casync_format.ex")

alias AriaStorage.Parsers.CasyncFormat

defmodule SizeDiffAnalyzer do
  @moduledoc """
  Detailed analysis of size differences in CATAR roundtrip encoding
  """

  def analyze_file(file_path) do
    IO.puts("=== ANALYZING SIZE DIFFERENCES FOR #{Path.basename(file_path)} ===")
    
    case File.read(file_path) do
      {:ok, original_data} ->
        original_size = byte_size(original_data)
        IO.puts("Original file size: #{original_size} bytes")
        
        case CasyncFormat.parse_archive(original_data) do
          {:ok, parsed} ->
            IO.puts("✓ Parsing successful")
            IO.puts("  Elements: #{length(parsed.elements)}")
            
            # Analyze each element's size contribution
            analyze_elements(parsed.elements, original_data)
            
            case CasyncFormat.encode_archive(parsed) do
              {:ok, encoded_data} ->
                encoded_size = byte_size(encoded_data)
                size_diff = original_size - encoded_size
                
                IO.puts("\n=== SUMMARY ===")
                IO.puts("Original size: #{original_size} bytes")
                IO.puts("Encoded size:  #{encoded_size} bytes")
                IO.puts("Difference:    #{size_diff} bytes (#{if size_diff > 0, do: "under-encoding", else: "over-encoding"})")
                
                if size_diff != 0 do
                  analyze_detailed_diff(original_data, encoded_data, parsed.elements)
                end
                
                {:ok, size_diff}
                
              {:error, reason} ->
                IO.puts("✗ Encoding failed: #{reason}")
                {:error, reason}
            end
            
          {:error, reason} ->
            IO.puts("✗ Parsing failed: #{reason}")
            {:error, reason}
        end
        
      {:error, reason} ->
        IO.puts("✗ File read failed: #{reason}")
        {:error, reason}
    end
  end
  
  def analyze_elements(elements, original_data) do
    IO.puts("\n=== ELEMENT ANALYSIS ===")
    
    {_, element_sizes} = Enum.reduce(elements, {0, []}, fn element, {offset, sizes} ->
      case element do
        %{type: :entry, size: size} ->
          actual_size = 64  # Entry is always 64 bytes
          IO.puts("Entry: declared=#{size}, actual=#{actual_size}")
          {offset + actual_size, [{:entry, size, actual_size} | sizes]}
          
        %{type: :filename, name: name} ->
          name_data = name <> <<0>>
          actual_size = 16 + byte_size(name_data)
          IO.puts("Filename '#{name}': actual=#{actual_size}")
          {offset + actual_size, [{:filename, actual_size, actual_size} | sizes]}
          
        %{type: :payload, size: payload_size} ->
          actual_size = 16 + payload_size
          # Check if there's padding in original
          padding_needed = case rem(actual_size, 8) do
            0 -> 0
            remainder -> 8 - remainder
          end
          total_with_padding = actual_size + padding_needed
          IO.puts("Payload: declared=#{payload_size}, header+data=#{actual_size}, with_padding=#{total_with_padding}")
          {offset + total_with_padding, [{:payload, payload_size, total_with_padding} | sizes]}
          
        %{type: :symlink, target: target} ->
          target_data = target <> <<0>>
          actual_size = 16 + byte_size(target_data)
          padding_needed = case rem(actual_size, 8) do
            0 -> 0
            remainder -> 8 - remainder
          end
          total_with_padding = actual_size + padding_needed
          IO.puts("Symlink '#{target}': header+data=#{actual_size}, with_padding=#{total_with_padding}")
          {offset + total_with_padding, [{:symlink, actual_size, total_with_padding} | sizes]}
          
        %{type: :user, name: name} ->
          name_data = name <> <<0>>
          actual_size = 16 + byte_size(name_data)
          padding_needed = case rem(actual_size, 8) do
            0 -> 0
            remainder -> 8 - remainder
          end
          total_with_padding = actual_size + padding_needed
          IO.puts("User '#{name}': header+data=#{actual_size}, with_padding=#{total_with_padding}")
          {offset + total_with_padding, [{:user, actual_size, total_with_padding} | sizes]}
          
        %{type: :group, name: name} ->
          name_data = name <> <<0>>
          actual_size = 16 + byte_size(name_data)
          padding_needed = case rem(actual_size, 8) do
            0 -> 0
            remainder -> 8 - remainder
          end
          total_with_padding = actual_size + padding_needed
          IO.puts("Group '#{name}': header+data=#{actual_size}, with_padding=#{total_with_padding}")
          {offset + total_with_padding, [{:group, actual_size, total_with_padding} | sizes]}
          
        %{type: :selinux, context: context} ->
          context_data = context <> <<0>>
          actual_size = 16 + byte_size(context_data)
          padding_needed = case rem(actual_size, 8) do
            0 -> 0
            remainder -> 8 - remainder
          end
          total_with_padding = actual_size + padding_needed
          IO.puts("SELinux '#{context}': header+data=#{actual_size}, with_padding=#{total_with_padding}")
          {offset + total_with_padding, [{:selinux, actual_size, total_with_padding} | sizes]}
          
        %{type: :goodbye, items: items} ->
          actual_size = 16 + (length(items) * 24)
          IO.puts("Goodbye: #{length(items)} items, actual=#{actual_size}")
          {offset + actual_size, [{:goodbye, actual_size, actual_size} | sizes]}
          
        %{type: :device, major: major, minor: minor} ->
          actual_size = 32  # Device is always 32 bytes
          IO.puts("Device: major=#{major}, minor=#{minor}, actual=#{actual_size}")
          {offset + actual_size, [{:device, actual_size, actual_size} | sizes]}
          
        %{type: :xattr, data: data} ->
          actual_size = 16 + byte_size(data)
          padding_needed = case rem(actual_size, 8) do
            0 -> 0
            remainder -> 8 - remainder
          end
          total_with_padding = actual_size + padding_needed
          IO.puts("XAttr: data_size=#{byte_size(data)}, header+data=#{actual_size}, with_padding=#{total_with_padding}")
          {offset + total_with_padding, [{:xattr, actual_size, total_with_padding} | sizes]}
          
        %{type: :metadata, format: format, size: data_size, data: data} ->
          actual_size = 16 + data_size
          padding_needed = case rem(actual_size, 8) do
            0 -> 0
            remainder -> 8 - remainder
          end
          total_with_padding = actual_size + padding_needed
          IO.puts("Metadata: format=0x#{Integer.to_string(format, 16)}, data_size=#{data_size}, header+data=#{actual_size}, with_padding=#{total_with_padding}")
          {offset + total_with_padding, [{:metadata, actual_size, total_with_padding} | sizes]}
          
        _ ->
          IO.puts("Unknown element: #{inspect(element)}")
          {offset, sizes}
      end
    end)
    
    total_calculated = Enum.reduce(element_sizes, 0, fn {_type, _declared, actual}, acc -> acc + actual end)
    IO.puts("\nTotal calculated size: #{total_calculated} bytes")
    
    element_sizes
  end
  
  def analyze_detailed_diff(original_data, encoded_data, elements) do
    IO.puts("\n=== DETAILED BYTE-BY-BYTE ANALYSIS ===")
    
    # Parse original data step by step
    analyze_original_structure(original_data, 0)
    
    IO.puts("\n=== ENCODED DATA STRUCTURE ===")
    analyze_encoded_structure(encoded_data, 0)
    
    # Find first difference
    find_first_difference(original_data, encoded_data)
  end
  
  def analyze_original_structure(<<>>, offset) do
    IO.puts("End of original data at offset #{offset}")
  end
  
  def analyze_original_structure(data, offset) when byte_size(data) < 16 do
    IO.puts("Remaining #{byte_size(data)} bytes at offset #{offset}: #{inspect(data)}")
  end
  
  def analyze_original_structure(data, offset) do
    case data do
      <<size::little-64, type::little-64, rest::binary>> ->
        type_name = get_type_name(type)
        IO.puts("Offset #{offset}: #{type_name} (size=#{size}, type=0x#{Integer.to_string(type, 16)})")
        
        data_size = size - 16
        case rest do
          <<element_data::binary-size(data_size), remaining::binary>> ->
            # Check if there's padding
            next_offset = offset + size
            padding_needed = case rem(next_offset, 8) do
              0 -> 0
              remainder -> 8 - remainder
            end
            
            if padding_needed > 0 do
              case remaining do
                <<padding::binary-size(padding_needed), after_padding::binary>> ->
                  IO.puts("  -> Data: #{data_size} bytes")
                  IO.puts("  -> Padding: #{padding_needed} bytes (#{inspect(padding)})")
                  analyze_original_structure(after_padding, next_offset + padding_needed)
                _ ->
                  IO.puts("  -> Data: #{data_size} bytes (no padding found)")
                  analyze_original_structure(remaining, next_offset)
              end
            else
              IO.puts("  -> Data: #{data_size} bytes (no padding needed)")
              analyze_original_structure(remaining, next_offset)
            end
            
          _ ->
            IO.puts("  -> Insufficient data for element")
        end
        
      _ ->
        IO.puts("Cannot parse remaining data at offset #{offset}")
    end
  end
  
  def analyze_encoded_structure(data, offset) do
    analyze_original_structure(data, offset)  # Same logic
  end
  
  def find_first_difference(original, encoded) do
    IO.puts("\n=== FIRST DIFFERENCE ANALYSIS ===")
    
    min_size = min(byte_size(original), byte_size(encoded))
    find_first_diff_byte(original, encoded, 0, min_size)
  end
  
  def find_first_diff_byte(original, encoded, offset, max_offset) when offset >= max_offset do
    orig_size = byte_size(original)
    enc_size = byte_size(encoded)
    
    if orig_size != enc_size do
      IO.puts("Size difference at end: original=#{orig_size}, encoded=#{enc_size}")
      
      if orig_size > enc_size do
        remaining = binary_part(original, enc_size, orig_size - enc_size)
        IO.puts("Missing bytes: #{inspect(remaining)}")
        print_hex_dump(remaining, enc_size)
      else
        extra = binary_part(encoded, orig_size, enc_size - orig_size)
        IO.puts("Extra bytes: #{inspect(extra)}")
        print_hex_dump(extra, orig_size)
      end
    else
      IO.puts("No differences found")
    end
  end
  
  def find_first_diff_byte(original, encoded, offset, max_offset) do
    <<orig_byte::binary-size(1), orig_rest::binary>> = binary_part(original, offset, byte_size(original) - offset)
    <<enc_byte::binary-size(1), enc_rest::binary>> = binary_part(encoded, offset, byte_size(encoded) - offset)
    
    if orig_byte == enc_byte do
      find_first_diff_byte(original, encoded, offset + 1, max_offset)
    else
      IO.puts("First difference at offset #{offset}:")
      IO.puts("  Original: 0x#{Base.encode16(orig_byte)}")
      IO.puts("  Encoded:  0x#{Base.encode16(enc_byte)}")
      
      # Print context
      start_context = max(0, offset - 16)
      end_context = min(byte_size(original), offset + 16)
      context_size = end_context - start_context
      
      orig_context = binary_part(original, start_context, context_size)
      enc_context = if byte_size(encoded) >= start_context + context_size do
        binary_part(encoded, start_context, context_size)
      else
        <<>>
      end
      
      IO.puts("\nContext around difference:")
      IO.puts("Original:")
      print_hex_dump(orig_context, start_context)
      IO.puts("Encoded:")
      print_hex_dump(enc_context, start_context)
    end
  end
  
  def print_hex_dump(binary, base_offset \\ 0) do
    binary
    |> :binary.bin_to_list()
    |> Enum.chunk_every(16)
    |> Enum.with_index()
    |> Enum.each(fn {bytes, row} ->
      offset = base_offset + row * 16
      hex_part = bytes 
        |> Enum.map(&(Integer.to_string(&1, 16) |> String.pad_leading(2, "0")))
        |> Enum.join(" ")
        |> String.pad_trailing(47)
      
      ascii_part = bytes
        |> Enum.map(fn b -> if b >= 32 and b <= 126, do: <<b>>, else: "." end)
        |> Enum.join()
      
      IO.puts("#{Integer.to_string(offset, 16) |> String.pad_leading(8, "0") |> String.upcase()}: #{hex_part} |#{ascii_part}|")
    end)
  end
  
  def get_type_name(type) do
    case type do
      0x1396fabcea5bbb51 -> "Entry"
      0x6dbb6ebcb3161f0b -> "Filename"
      0x8b9e1d93d6dcffc9 -> "Payload"
      0x664a6fb6830e0d6c -> "Symlink"
      0xac3dace369dfe643 -> "Device"
      0xdfd35c5e8327c403 -> "Goodbye"
      0xf453131aaeeaccb3 -> "User"
      0x25eb6ac969396a52 -> "Group"
      0x46faf0602fd26c59 -> "SELinux"
      0xb8157091f80bc486 -> "XAttr"
      _ -> "Unknown(0x#{Integer.to_string(type, 16)})"
    end
  end
end

# Test with all CATAR files
test_files = [
  "debug_original.catar",
  "apps/aria_storage/test/fixtures/simple.catar",
  "apps/aria_storage/test/fixtures/complex.catar"
]

Enum.each(test_files, fn file_path ->
  if File.exists?(file_path) do
    case SizeDiffAnalyzer.analyze_file(file_path) do
      {:ok, size_diff} ->
        IO.puts("✓ Analysis complete for #{Path.basename(file_path)}: #{size_diff} bytes difference\n")
      {:error, reason} ->
        IO.puts("✗ Analysis failed for #{Path.basename(file_path)}: #{reason}\n")
    end
  else
    IO.puts("⚠ File not found: #{file_path}\n")
  end
end)
