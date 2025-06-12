#!/usr/bin/env elixir

# Add the project to the code path
Code.prepend_path("_build/dev/lib/aria_storage/ebin")
Code.prepend_path("_build/dev/lib/ezstd/ebin")
Code.prepend_path("_build/dev/lib/jason/ebin")
Code.prepend_path("_build/dev/lib/nx/ebin")
Code.prepend_path("_build/dev/lib/complex/ebin")
Code.prepend_path("_build/dev/lib/exla/ebin")

alias AriaStorage.Parsers.CasyncFormat

test_files = [
  "./debug_original.catar",
  "./apps/aria_storage/test/support/testdata/flat.catar",
  "./apps/aria_storage/test/support/testdata/nested.catar",
  "./apps/aria_storage/test/support/testdata/complex.catar",
  "./apps/aria_storage/test/support/testdata/flatdir.catar"
]

Enum.each(test_files, fn file_path ->
  if File.exists?(file_path) do
    IO.puts("Testing #{Path.basename(file_path)}")
    
    case File.read(file_path) do
      {:ok, original_data} ->
        case CasyncFormat.parse_archive(original_data) do
          {:ok, parsed} ->
            case CasyncFormat.encode_archive(parsed) do
              {:ok, encoded_data} ->
                original_size = byte_size(original_data)
                encoded_size = byte_size(encoded_data)
                
                if original_data == encoded_data do
                  IO.puts("✓ Perfect bit-exact roundtrip!")
                else
                  IO.puts("⚠ Size or content differences detected")
                  IO.puts("Original size: #{original_size} bytes")
                  IO.puts("Encoded size:  #{encoded_size} bytes")
                  
                  if original_size == encoded_size do
                    IO.puts("Sizes match, checking content differences...")
                    # Compare first differing bytes
                    diff_found = original_data
                    |> :binary.bin_to_list()
                    |> Enum.zip(:binary.bin_to_list(encoded_data))
                    |> Enum.with_index()
                    |> Enum.find(fn {{a, b}, _index} -> a != b end)
                    
                    case diff_found do
                      {{orig_byte, enc_byte}, index} ->
                        IO.puts("First difference at offset #{index}: original=0x#{Integer.to_string(orig_byte, 16)}, encoded=0x#{Integer.to_string(enc_byte, 16)}")
                      nil ->
                        IO.puts("Content is identical (should not happen!)")
                    end
                  end
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
    
    IO.puts("")
  else
    IO.puts("Skipping #{file_path} (not found)")
  end
end)
