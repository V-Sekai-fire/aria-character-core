#!/usr/bin/env elixir

# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

# Detailed element-by-element analysis to identify missing bytes
defmodule ElementAnalysis do
  require Logger

  def analyze_file(filename) do
    IO.puts("\n=== Analyzing #{filename} ===")
    
    # Read original file
    original_path = Path.join("test/fixtures", filename)
    {:ok, original_data} = File.read(original_path)
    
    # Parse elements
    case AriaStorage.Parsers.CasyncFormat.parse_catar(original_data) do
      {:ok, elements} ->
        IO.puts("Parsed #{length(elements)} elements successfully")
        
        # Analyze each element's encoding
        analyze_elements(elements, original_data)
        
        # Re-encode and compare total sizes
        encoded_data = AriaStorage.Parsers.CasyncFormat.encode_catar(elements)
        
        IO.puts("\nSize Analysis:")
        IO.puts("Original size: #{byte_size(original_data)} bytes")
        IO.puts("Encoded size:  #{byte_size(encoded_data)} bytes")
        IO.puts("Difference:    #{byte_size(encoded_data) - byte_size(original_data)} bytes")
        
        # Create byte-by-byte comparison
        compare_bytes(original_data, encoded_data)
        
      {:error, reason} ->
        IO.puts("Failed to parse: #{inspect(reason)}")
    end
  end
  
  def analyze_elements(elements, original_data) do
    IO.puts("\nElement-by-element analysis:")
    
    # Parse original data to get raw element data
    {parsed_elements, _rest} = parse_elements_with_raw_data(original_data, [])
    
    Enum.zip(elements, parsed_elements)
    |> Enum.with_index()
    |> Enum.each(fn {{element, {_raw_element, raw_size}}, index} ->
      encoded_element = AriaStorage.Parsers.CasyncFormat.encode_catar_element(element)
      encoded_size = byte_size(encoded_element)
      
      IO.puts("Element #{index + 1}: #{inspect(elem(element, 0))}")
      IO.puts("  Original size: #{raw_size} bytes")
      IO.puts("  Encoded size:  #{encoded_size} bytes")
      IO.puts("  Difference:    #{encoded_size - raw_size} bytes")
      
      if encoded_size != raw_size do
        IO.puts("  ⚠ SIZE MISMATCH!")
        # Show detailed element data
        case element do
          {:entry, data} -> IO.puts("    Entry data: #{inspect(data)}")
          {:filename, name} -> IO.puts("    Filename: #{inspect(name)}")
          {:payload, _} -> IO.puts("    Payload: #{byte_size(elem(element, 1))} bytes")
          {:user, user} -> IO.puts("    User: #{inspect(user)}")
          {:group, group} -> IO.puts("    Group: #{inspect(group)}")
          {:xattr, xattr} -> IO.puts("    Xattr: #{inspect(xattr)}")
          {:selinux, context} -> IO.puts("    SELinux: #{inspect(context)}")
          other -> IO.puts("    Data: #{inspect(other)}")
        end
      end
      
      IO.puts("")
    end)
  end
  
  def parse_elements_with_raw_data(<<>>, acc), do: {Enum.reverse(acc), <<>>}
  
  def parse_elements_with_raw_data(data, acc) do
    case parse_single_element_with_size(data) do
      {:ok, element, size, rest} ->
        parse_elements_with_raw_data(rest, [{element, size} | acc])
      {:error, _reason} ->
        {Enum.reverse(acc), data}
    end
  end
  
  def parse_single_element_with_size(<<type::little-64, size::little-64, rest::binary>>) do
    data_size = size - 16  # Subtract header size
    
    case rest do
      <<data::binary-size(data_size), remaining::binary>> ->
        element_data = <<type::little-64, size::little-64, data::binary>>
        
        # Parse the element
        case parse_element_type(type, data) do
          {:ok, element} -> {:ok, element, size, remaining}
          {:error, reason} -> {:error, reason}
        end
      _ ->
        {:error, :insufficient_data}
    end
  end
  
  def parse_single_element_with_size(_), do: {:error, :invalid_header}
  
  def parse_element_type(0x1396FABCEA5BCE51, data) do # ENTRY
    try do
      <<feature_flags::little-64, mode::little-32, uid_data::binary>> = data
      
      {uid, gid, rest} = parse_uid_gid(uid_data, feature_flags)
      
      <<mtime::little-64, rest::binary>> = rest
      
      entry = %{
        feature_flags: feature_flags,
        mode: mode,
        uid: uid,
        gid: gid,
        mtime: mtime
      }
      
      {:ok, {:entry, entry}}
    rescue
      _ -> {:error, :invalid_entry}
    end
  end
  
  def parse_element_type(0x6dbb6ebcf3161f0b, data) do # FILENAME
    try do
      # Remove null terminator if present
      filename = case :binary.last(data) do
        0 -> :binary.part(data, 0, byte_size(data) - 1)
        _ -> data
      end
      {:ok, {:filename, filename}}
    rescue
      _ -> {:error, :invalid_filename}
    end
  end
  
  def parse_element_type(0x8b9e1d93d6dcffc9, data) do # PAYLOAD
    {:ok, {:payload, data}}
  end
  
  def parse_element_type(0x664a6fb6830e2c85, data) do # USER
    try do
      # Remove null terminator if present
      user = case :binary.last(data) do
        0 -> :binary.part(data, 0, byte_size(data) - 1)
        _ -> data
      end
      {:ok, {:user, user}}
    rescue
      _ -> {:error, :invalid_user}
    end
  end
  
  def parse_element_type(0xf4103aa8bdde9864, data) do # GROUP
    try do
      # Remove null terminator if present
      group = case :binary.last(data) do
        0 -> :binary.part(data, 0, byte_size(data) - 1)
        _ -> data
      end
      {:ok, {:group, group}}
    rescue
      _ -> {:error, :invalid_group}
    end
  end
  
  def parse_element_type(type, data) do
    # For other types, just return the raw data
    {:ok, {:unknown, {type, data}}}
  end
  
  def parse_uid_gid(data, feature_flags) do
    use Bitwise
    
    cond do
      (feature_flags &&& 0x10) != 0 ->  # 64-bit UIDs
        <<uid::little-64, gid::little-64, rest::binary>> = data
        {uid, gid, rest}
      
      (feature_flags &&& 0x08) != 0 ->  # 32-bit UIDs  
        <<uid::little-32, gid::little-32, rest::binary>> = data
        {uid, gid, rest}
      
      true ->  # 16-bit UIDs (default)
        <<uid::little-32, gid::little-32, rest::binary>> = data
        {uid, gid, rest}
    end
  end
  
  def compare_bytes(original, encoded) do
    IO.puts("\nByte-by-byte comparison (first 200 bytes):")
    
    original_bytes = :binary.bin_to_list(binary_part(original, 0, min(200, byte_size(original))))
    encoded_bytes = :binary.bin_to_list(binary_part(encoded, 0, min(200, byte_size(encoded))))
    
    max_len = max(length(original_bytes), length(encoded_bytes))
    
    original_padded = original_bytes ++ List.duplicate(0, max_len - length(original_bytes))
    encoded_padded = encoded_bytes ++ List.duplicate(0, max_len - length(encoded_bytes))
    
    Enum.zip(original_padded, encoded_padded)
    |> Enum.with_index()
    |> Enum.each(fn {{orig, enc}, index} ->
      if orig != enc do
        IO.puts("Byte #{index}: Original=#{orig} (0x#{Integer.to_string(orig, 16)}), Encoded=#{enc} (0x#{Integer.to_string(enc, 16)})")
      end
    end)
  end
end

# Load the AriaStorage module
Code.require_file("apps/aria_storage/lib/aria_storage/parsers/casync_format.ex")

# Test files to analyze
test_files = [
  "debug_original.catar",
  "flat.catar"
]

Enum.each(test_files, &ElementAnalysis.analyze_file/1)
