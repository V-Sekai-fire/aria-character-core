#!/usr/bin/env elixir

Mix.install([])

# Load the CasyncFormat module
Code.require_file("apps/aria_storage/lib/aria_storage/parsers/casync_format.ex")

alias AriaStorage.Parsers.CasyncFormat

# Load and compare original vs encoded
catar_path = "apps/aria_storage/test/support/testdata/flat.catar"

case File.read(catar_path) do
  {:ok, original_data} ->
    IO.puts("=== DETAILED CATAR ROUNDTRIP ANALYSIS ===")
    IO.puts("Original size: #{byte_size(original_data)} bytes")
    
    # Parse the original
    case CasyncFormat.parse_archive(original_data) do
      {:ok, parsed} ->
        IO.puts("✓ Parsed successfully")
        IO.puts("Elements found: #{length(parsed.elements)}")
        
        # Encode it back
        case CasyncFormat.encode_archive(parsed) do
          {:ok, encoded_data} ->
            IO.puts("✓ Encoded successfully")
            IO.puts("Encoded size: #{byte_size(encoded_data)} bytes")
            IO.puts("Size difference: #{byte_size(encoded_data) - byte_size(original_data)} bytes")
            
            # Compare element by element
            IO.puts("\n=== ELEMENT-BY-ELEMENT COMPARISON ===")
            compare_elements(original_data, encoded_data)
            
          {:error, reason} ->
            IO.puts("✗ Encoding failed: #{inspect(reason)}")
        end
        
      {:error, reason} ->
        IO.puts("✗ Parsing failed: #{inspect(reason)}")
    end
    
  {:error, reason} ->
    IO.puts("Error reading file: #{reason}")
end

defp compare_elements(original, encoded) do
  IO.puts("Parsing original elements...")
  original_elements = parse_elements_with_offsets(original, 0, [])
  
  IO.puts("Parsing encoded elements...")
  encoded_elements = parse_elements_with_offsets(encoded, 0, [])
  
  IO.puts("\nOriginal has #{length(original_elements)} elements")
  IO.puts("Encoded has #{length(encoded_elements)} elements")
  
  # Compare each element
  Enum.zip_with([original_elements, encoded_elements], fn [orig, enc] ->
    compare_element_pair(orig, enc)
  end)
end

defp parse_elements_with_offsets(data, offset, acc) when byte_size(data) < 16 do
  Enum.reverse(acc)
end

defp parse_elements_with_offsets(data, offset, acc) do
  case data do
    <<size::little-64, type::little-64, rest::binary>> ->
      data_size = size - 16
      element_info = %{
        offset: offset,
        size_field: size,
        type: type,
        data_size: data_size
      }
      
      # Calculate actual element size with padding
      unpadded_size = size
      padding_size = rem(8 - rem(unpadded_size, 8), 8)
      actual_element_size = unpadded_size + padding_size
      
      element_with_size = Map.put(element_info, :actual_size, actual_element_size)
      
      if byte_size(data) >= actual_element_size do
        <<_current::binary-size(actual_element_size), remaining::binary>> = data
        parse_elements_with_offsets(remaining, offset + actual_element_size, [element_with_size | acc])
      else
        IO.puts("Warning: Not enough data for element at offset #{offset}")
        Enum.reverse([element_with_size | acc])
      end
      
    _ ->
      IO.puts("Warning: Malformed element at offset #{offset}")
      Enum.reverse(acc)
  end
end

defp compare_element_pair(orig, enc) do
  type_name = get_type_name(orig.type)
  IO.puts("\n--- #{type_name} (0x#{Integer.to_string(orig.type, 16)}) ---")
  IO.puts("Original: offset=#{orig.offset}, size_field=#{orig.size_field}, actual_size=#{orig.actual_size}")
  IO.puts("Encoded:  offset=#{enc.offset}, size_field=#{enc.size_field}, actual_size=#{enc.actual_size}")
  
  if orig.size_field != enc.size_field do
    IO.puts("  ⚠️  SIZE FIELD MISMATCH: #{orig.size_field} != #{enc.size_field}")
  end
  
  if orig.actual_size != enc.actual_size do
    IO.puts("  ⚠️  ACTUAL SIZE MISMATCH: #{orig.actual_size} != #{enc.actual_size}")
  end
end

defp get_type_name(type) do
  case type do
    0x1396FABCEA5BBB51 -> "entry"
    0x46FAF0602FD26C59 -> "filename"  
    0x8B9E1D93D6DCFFC9 -> "payload"
    0xF453131AAEEACCB3 -> "user"
    0x25EB6AC969396A52 -> "group" 
    0xAC3DACE369DFE643 -> "selinux"
    0x664A6FB6830E0D6C -> "symlink"
    0x6DBB6EBCB3161F0B -> "device"
    0xDFD35C5E8327C403 -> "goodbye"
    _ -> "unknown"
  end
end
