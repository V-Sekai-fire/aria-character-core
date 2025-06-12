#!/usr/bin/env elixir

# Simple comparison script
Mix.install([])

defmodule SimpleDebug do
  def run do
    file_path = "apps/aria_storage/test/support/testdata/flat.catar"
    
    IO.puts("=== Debug Analysis for #{Path.basename(file_path)} ===")
    
    # Show desync mtree output
    IO.puts("\n--- Desync mtree output ---")
    {output, 0} = System.cmd("desync", ["mtree", file_path])
    IO.puts(output)
    
    # Parse with our code
    IO.puts("\n--- Our parser analysis ---")
    case File.read(file_path) do
      {:ok, data} ->
        IO.puts("File size: #{byte_size(data)} bytes")
        
        # Load our parser
        Code.require_file("apps/aria_storage/lib/aria_storage/parsers/casync_format.ex")
        alias AriaStorage.Parsers.CasyncFormat
        
        case CasyncFormat.parse_archive(data) do
          {:ok, parsed} ->
            IO.puts("✓ Parsed successfully")
            IO.puts("Elements: #{length(parsed.elements)}")
            IO.puts("Files: #{length(parsed.files)}")  
            IO.puts("Directories: #{length(parsed.directories)}")
            
            # Show element types
            element_types = parsed.elements
            |> Enum.group_by(& &1.type)
            |> Enum.map(fn {type, elements} -> {type, length(elements)} end)
            |> Enum.sort()
            
            IO.puts("\nElement breakdown:")
            Enum.each(element_types, fn {type, count} ->
              IO.puts("  #{type}: #{count}")
            end)
            
            # Test encoding
            case CasyncFormat.encode_archive(parsed) do
              {:ok, encoded} ->
                size_diff = byte_size(encoded) - byte_size(data)
                IO.puts("\nEncoding test:")
                IO.puts("  Original: #{byte_size(data)} bytes")
                IO.puts("  Encoded: #{byte_size(encoded)} bytes")
                IO.puts("  Difference: #{size_diff} bytes")
                
                if size_diff == 0 do
                  IO.puts("✓ Perfect size match!")
                else
                  IO.puts("⚠ Size difference detected")
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
  end
end

SimpleDebug.run()
