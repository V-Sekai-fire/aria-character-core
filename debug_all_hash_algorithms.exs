#!/usr/bin/env elixir

# Comprehensive script to test all possible hash algorithms on chunk files
chunk_file = "apps/aria_storage/test/support/testdata/blob1.store/15cc/15cc115dc5d8bef2fea4cb8ec58fa86d86f5bebb47577670154e625e67ac9e42.cacnk"

defmodule HashTester do
  def test_chunk(file_path) do
    case File.read(file_path) do
      {:ok, data} ->
        IO.puts("Raw chunk size: #{byte_size(data)} bytes")
        IO.puts("First 32 bytes: #{Base.encode16(binary_part(data, 0, min(32, byte_size(data))))}")
        
        # Extract expected hash from filename
        expected = file_path |> Path.basename(".cacnk") |> String.downcase()
        IO.puts("\nExpected (from filename): #{expected}")
        
        # Try to decompress with ZSTD
        case decompress_chunk(data) do
          {:ok, decompressed} ->
            IO.puts("\n✓ ZSTD decompression successful")
            IO.puts("Decompressed size: #{byte_size(decompressed)} bytes")
            test_all_algorithms(data, decompressed, expected)
            
          {:error, _reason} ->
            IO.puts("\n⚠️  ZSTD decompression failed, testing uncompressed data")
            test_all_algorithms(data, data, expected)
        end
        
      {:error, reason} ->
        IO.puts("Failed to read chunk file: #{reason}")
    end
  end

  defp decompress_chunk(data) do
    try do
      decompressed_raw = :zstd.decompress(data)
      decompressed = case decompressed_raw do
        result when is_list(result) -> :erlang.list_to_binary(result)
        result when is_binary(result) -> result
      end
      {:ok, decompressed}
    rescue
      _ -> {:error, :decompression_failed}
    end
  end

  defp test_all_algorithms(compressed_data, decompressed_data, expected) do
    IO.puts("\n=== TESTING ALL HASH ALGORITHMS ===")
    
    algorithms = [
      # Test decompressed data
      {"SHA-256 (decompressed)", :sha256, decompressed_data},
      {"SHA-512/256 (decompressed)", :sha512_256, decompressed_data},
      {"SHA-512 (decompressed)", :sha512, decompressed_data},
      {"SHA-1 (decompressed)", :sha, decompressed_data},
      {"MD5 (decompressed)", :md5, decompressed_data},
      
      # Test compressed data
      {"SHA-256 (compressed)", :sha256, compressed_data},
      {"SHA-512/256 (compressed)", :sha512_256, compressed_data},
      {"SHA-512 (compressed)", :sha512, compressed_data},
      {"SHA-1 (compressed)", :sha, compressed_data},
      {"MD5 (compressed)", :md5, compressed_data},
    ]
    
    matches = []
    
    for {name, algorithm, data} <- algorithms do
      hash_hex = calculate_hash(algorithm, data)
      match? = hash_hex == expected
      
      status = if match?, do: "✅ MATCH!", else: "  "
      IO.puts("#{status} #{name}: #{hash_hex}")
      
      if match? do
        matches = [name | matches]
      end
    end
    
    IO.puts("\n=== SUMMARY ===")
    case matches do
      [] ->
        IO.puts("❌ No algorithm matches the expected hash")
        IO.puts("This suggests:")
        IO.puts("1. The testdata was generated with different parameters")
        IO.puts("2. There's a format/encoding issue we're missing")
        IO.puts("3. The hash might be calculated from a different part of the data")
        
      matches ->
        IO.puts("✅ Found #{length(matches)} matching algorithm(s):")
        for match <- matches do
          IO.puts("   - #{match}")
        end
    end
  end

  defp calculate_hash(:sha512_256, data) do
    :crypto.hash(:sha512, data) |> binary_part(0, 32) |> Base.encode16(case: :lower)
  end
  
  defp calculate_hash(algorithm, data) do
    :crypto.hash(algorithm, data) |> Base.encode16(case: :lower)
  end
end

HashTester.test_chunk(chunk_file)
