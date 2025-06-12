#!/usr/bin/env elixir

Code.require_file("apps/aria_storage/lib/aria_storage/parsers/casync_format.ex")

alias AriaStorage.Parsers.CasyncFormat

# Test one specific file to debug the difference
file_path = "/Users/setup/Developer/aria-character-core/apps/aria_storage/test/support/testdata/complex.catar"

IO.puts("Looking for file: #{file_path}")
IO.puts("File exists: #{File.exists?(file_path)}")

case File.read(file_path) do
  {:ok, original_data} ->
    IO.puts("=== DEBUGGING COMPLEX.CATAR ===")
    IO.puts("Original size: #{byte_size(original_data)} bytes")
    
    case CasyncFormat.parse_archive(original_data) do
      {:ok, parsed} ->
        IO.puts("✓ Parsing successful")
        IO.puts("Elements: #{length(parsed.elements)}")
        
        case CasyncFormat.encode_archive(parsed) do
          {:ok, encoded_data} ->
            IO.puts("✓ Encoding successful")
            IO.puts("Encoded size: #{byte_size(encoded_data)} bytes")
            IO.puts("Difference: #{byte_size(encoded_data) - byte_size(original_data)} bytes")
            
            # Show first 512 bytes comparison
            original_start = binary_part(original_data, 0, min(512, byte_size(original_data)))
            encoded_start = binary_part(encoded_data, 0, min(512, byte_size(encoded_data)))
            
            IO.puts("\n=== FIRST 512 BYTES COMPARISON ===")
            IO.puts("Original first 64 bytes:")
            IO.inspect(binary_part(original_start, 0, 64), base: :hex, limit: :infinity)
            
            IO.puts("\nEncoded first 64 bytes:")
            IO.inspect(binary_part(encoded_start, 0, 64), base: :hex, limit: :infinity)
            
            # Check if the headers match
            if binary_part(original_data, 0, 64) == binary_part(encoded_data, 0, 64) do
              IO.puts("\n✓ First entry headers match!")
            else
              IO.puts("\n⚠ First entry headers differ!")
            end
            
          {:error, reason} ->
            IO.puts("✗ Encoding failed: #{reason}")
        end
        
      {:error, reason} ->
        IO.puts("✗ Parsing failed: #{reason}")
    end
    
  {:error, reason} ->
    IO.puts("✗ File read failed: #{reason}")
end
