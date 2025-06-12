#!/usr/bin/env elixir

# Debug all element types and their encoding
IO.puts("Starting comprehensive element encoding debug...")

Code.require_file("apps/aria_storage/lib/aria_storage/parsers/casync_format.ex")

alias AriaStorage.Parsers.CasyncFormat

# Load test data
data = File.read!("apps/aria_storage/test/support/testdata/flat.catar")
IO.puts("Loaded #{byte_size(data)} bytes from flat.catar")

case CasyncFormat.parse_archive(data) do
  {:ok, result} ->
    IO.puts("Successfully parsed CATAR!")
    IO.puts("Total elements: #{length(result.elements)}")
    
    # Group elements by type
    elements_by_type = Enum.group_by(result.elements, fn element ->
      Map.get(element, :type)
    end)
    
    IO.puts("\n=== ELEMENT TYPES BREAKDOWN ===")
    Enum.each(elements_by_type, fn {type, elements} ->
      IO.puts("#{type}: #{length(elements)} elements")
      
      # Show first element as example
      case elements do
        [first | _] ->
          IO.puts("  Example: #{inspect(first, limit: 1, pretty: true)}")
        [] ->
          IO.puts("  (no elements)")
      end
      IO.puts("")
    end)
    
    # Test encoding each element individually to find size differences
    IO.puts("=== INDIVIDUAL ELEMENT ENCODING TEST ===")
    total_original_size = 0
    total_encoded_size = 0
    
    Enum.with_index(result.elements)
    |> Enum.each(fn {element, idx} ->
      # Try to encode this single element
      try do
        encoded_element = CasyncFormat.encode_catar_element(element)
        encoded_size = byte_size(encoded_element)
        
        IO.puts("Element #{idx} (#{element.type}): #{encoded_size} bytes")
        total_encoded_size = total_encoded_size + encoded_size
        
      rescue
        error ->
          IO.puts("Element #{idx} (#{element.type}): ENCODING ERROR - #{inspect(error)}")
      end
    end)
    
    IO.puts("\n=== SIZE SUMMARY ===")
    IO.puts("Original total: #{byte_size(data)} bytes")
    IO.puts("Sum of encoded elements: #{total_encoded_size} bytes")
    IO.puts("Difference: #{total_encoded_size - byte_size(data)} bytes")
    
  {:error, reason} ->
    IO.puts("❌ Failed to parse: #{inspect(reason)}")
end
