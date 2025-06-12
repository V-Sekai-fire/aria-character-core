#!/usr/bin/env elixir

Mix.install([])

# Simple CATAR roundtrip test
defmodule SimpleCatarTest do
  def run do
    catar_path = "apps/aria_storage/test/support/testdata/flat.catar"
    
    case File.read(catar_path) do
      {:ok, original_data} ->
        IO.puts("Original size: #{byte_size(original_data)} bytes")
        
        # We need to use the compiled module
        {result, _} = Code.eval_string("""
        alias AriaStorage.Parsers.CasyncFormat
        
        case CasyncFormat.parse_archive(original_data) do
          {:ok, parsed} ->
            case CasyncFormat.encode_archive(parsed) do
              {:ok, encoded_data} ->
                {original_data, encoded_data}
              error -> 
                {:encode_error, error}
            end
          error ->
            {:parse_error, error}
        end
        """, [original_data: original_data])
        
        case result do
          {orig, enc} ->
            IO.puts("Encoded size: #{byte_size(enc)} bytes")
            IO.puts("Size difference: #{byte_size(enc) - byte_size(orig)} bytes")
            
            # Write files for external comparison
            File.write!("debug_original.catar", orig)
            File.write!("debug_encoded.catar", enc)
            IO.puts("Files written: debug_original.catar, debug_encoded.catar")
            
          error ->
            IO.puts("Error: #{inspect(error)}")
        end
        
      {:error, reason} ->
        IO.puts("Error reading file: #{reason}")
    end
  end
end

SimpleCatarTest.run()
