#!/usr/bin/env elixir

# Test script to understand chunk format and decompression
Code.put_path("_build/dev/lib/*/ebin")
Application.ensure_all_started(:ezstd)

defmodule ChunkAnalyzer do
  def analyze_chunk(chunk_path) do
    IO.puts("Analyzing chunk: #{Path.basename(chunk_path)}")
    
    case File.read(chunk_path) do
      {:ok, chunk_data} ->
        IO.puts("Chunk size: #{byte_size(chunk_data)} bytes")
        
        # Extract expected hash from filename
        chunk_filename = Path.basename(chunk_path, ".cacnk")
        expected_hash = Base.decode16!(chunk_filename, case: :lower)
        
        IO.puts("Expected hash: #{chunk_filename}")
        
        # Try different decompression approaches
        test_decompression_approaches(chunk_data, expected_hash)
        
      {:error, reason} ->
        IO.puts("Failed to read chunk: #{inspect(reason)}")
    end
  end
  
  defp test_decompression_approaches(chunk_data, expected_hash) do
    IO.puts("\nTesting decompression approaches:")
    IO.puts("================================")
    
    # Method 1: Direct ZSTD decompression
    IO.puts("1. Direct ZSTD decompression:")
    case :ezstd.decompress(chunk_data) do
      decompressed when is_binary(decompressed) ->
        IO.puts("   ✓ ZSTD decompression successful")
        IO.puts("   Decompressed size: #{byte_size(decompressed)} bytes")
        test_hash_algorithms(decompressed, expected_hash, "decompressed data")
        
      error ->
        IO.puts("   ✗ ZSTD decompression failed: #{inspect(error)}")
        
        # Method 2: Try as uncompressed
        IO.puts("2. Treating as uncompressed:")
        test_hash_algorithms(chunk_data, expected_hash, "raw data")
    end
  end
  
  defp test_hash_algorithms(data, expected_hash, data_type) do
    IO.puts("\nTesting hash algorithms on #{data_type}:")
    
    # SHA-256
    sha256_hash = :crypto.hash(:sha256, data)
    sha256_matches = sha256_hash == expected_hash
    IO.puts("   SHA-256: #{Base.encode16(sha256_hash, case: :lower)} #{if sha256_matches, do: "✓ MATCH", else: "✗"}")
    
    # SHA-512/256 (first 32 bytes of SHA-512)
    sha512_256_hash = :crypto.hash(:sha512, data) |> binary_part(0, 32)
    sha512_256_matches = sha512_256_hash == expected_hash
    IO.puts("   SHA-512/256: #{Base.encode16(sha512_256_hash, case: :lower)} #{if sha512_256_matches, do: "✓ MATCH", else: "✗"}")
    
    # Full SHA-512 for reference
    sha512_hash = :crypto.hash(:sha512, data)
    IO.puts("   SHA-512 (full): #{Base.encode16(sha512_hash, case: :lower)}")
    
    cond do
      sha256_matches ->
        IO.puts("   → Chunk ID uses SHA-256")
        {:ok, :sha256}
      sha512_256_matches ->
        IO.puts("   → Chunk ID uses SHA-512/256")
        {:ok, :sha512_256}
      true ->
        IO.puts("   → No hash algorithm matches!")
        {:error, :no_match}
    end
  end
end

# Test with a real chunk from testdata
testdata_path = "apps/aria_storage/test/support/testdata"
store_path = Path.join(testdata_path, "blob1.store")

if File.exists?(store_path) do
  IO.puts("Found blob1.store, analyzing first chunk...")
  
  case File.ls(store_path) do
    {:ok, chunk_dirs} ->
      chunk_dir = List.first(chunk_dirs)
      chunk_dir_path = Path.join(store_path, chunk_dir)
      
      case File.ls(chunk_dir_path) do
        {:ok, chunk_files} ->
          chunk_file = List.first(chunk_files)
          chunk_path = Path.join(chunk_dir_path, chunk_file)
          
          ChunkAnalyzer.analyze_chunk(chunk_path)
          
        {:error, reason} ->
          IO.puts("Failed to list chunk files: #{inspect(reason)}")
      end
      
    {:error, reason} ->
      IO.puts("Failed to list chunk directories: #{inspect(reason)}")
  end
else
  IO.puts("Testdata not found at: #{store_path}")
  IO.puts("Please run from the project root directory")
end