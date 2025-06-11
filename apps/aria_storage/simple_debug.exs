#!/usr/bin/env elixir

Mix.install([])

alias AriaStorage.Parsers.CasyncFormat

file_path = "test/support/testdata/blob1.caibx"

case File.read(file_path) do
  {:ok, original_data} ->
    IO.puts("Testing #{Path.basename(file_path)}")
    IO.puts("Original size: #{byte_size(original_data)}")
    
    case CasyncFormat.parse_index(original_data) do
      {:ok, parsed} ->
        IO.puts("✅ Parsing successful")
        IO.puts("Parsed format: #{inspect(parsed.format)}")
        IO.puts("Chunk count: #{length(parsed.chunks)}")
        
        case CasyncFormat.encode_index(parsed) do
          {:ok, re_encoded} ->
            IO.puts("✅ Encoding successful")  
            IO.puts("Re-encoded size: #{byte_size(re_encoded)}")
            
            if original_data == re_encoded do
              IO.puts("✅ Perfect roundtrip!")
            else
              IO.puts("❌ Roundtrip mismatch")
              
              # Find first difference
              original_bytes = :binary.bin_to_list(original_data)
              reencoded_bytes = :binary.bin_to_list(re_encoded)
              
              Enum.with_index(Enum.zip(original_bytes, reencoded_bytes))
              |> Enum.find(fn {{orig, reenc}, _idx} -> orig != reenc end)
              |> case do
                {{orig, reenc}, idx} ->
                  IO.puts("First difference at byte #{idx}: original=#{orig} (0x#{Integer.to_string(orig, 16)}), reencoded=#{reenc} (0x#{Integer.to_string(reenc, 16)})")
                nil ->
                  IO.puts("No byte differences found (length mismatch?)")
              end
            end
            
          {:error, reason} ->
            IO.puts("❌ Encoding failed: #{inspect(reason)}")
        end
        
      {:error, reason} ->
        IO.puts("❌ Parsing failed: #{inspect(reason)}")
    end
    
  {:error, reason} ->
    IO.puts("❌ File read failed: #{inspect(reason)}")
end
