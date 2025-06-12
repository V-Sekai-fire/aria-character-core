#!/usr/bin/env elixir

# Debug script to analyze chunk file and test different hash algorithms
chunk_file = "apps/aria_storage/test/support/testdata/blob1.store/15cc/15cc115dc5d8bef2fea4cb8ec58fa86d86f5bebb47577670154e625e67ac9e42.cacnk"

case File.read(chunk_file) do
  {:ok, data} ->
    IO.puts("Raw chunk size: #{byte_size(data)} bytes")
    IO.puts("First 32 bytes: #{Base.encode16(binary_part(data, 0, min(32, byte_size(data))))}")
    
    # Try to decompress with ZSTD
    decompressed_raw = :zstd.decompress(data)
    decompressed = case decompressed_raw do
      result when is_list(result) -> :erlang.list_to_binary(result)
      result when is_binary(result) -> result
    end
    IO.puts("\n✓ ZSTD decompression successful")
    IO.puts("Decompressed size: #{byte_size(decompressed)} bytes")
    IO.puts("First 64 chars of decompressed: #{inspect(binary_part(decompressed, 0, min(64, byte_size(decompressed))))}")
    
    # Calculate various hashes
    sha256_hash = :crypto.hash(:sha256, decompressed) |> Base.encode16(case: :lower)
    sha512_256_hash = :crypto.hash(:sha512, decompressed) |> binary_part(0, 32) |> Base.encode16(case: :lower)
    
    # Also try hashing the compressed data (in case that's what's expected)
    sha256_compressed = :crypto.hash(:sha256, data) |> Base.encode16(case: :lower)
    sha512_256_compressed = :crypto.hash(:sha512, data) |> binary_part(0, 32) |> Base.encode16(case: :lower)
    
    expected = "15cc115dc5d8bef2fea4cb8ec58fa86d86f5bebb47577670154e625e67ac9e42"
    
    IO.puts("\nHash calculations (decompressed data):")
    IO.puts("SHA-256: #{sha256_hash}")
    IO.puts("SHA-512/256: #{sha512_256_hash}")
    
    IO.puts("\nHash calculations (compressed data):")
    IO.puts("SHA-256: #{sha256_compressed}")
    IO.puts("SHA-512/256: #{sha512_256_compressed}")
    
    IO.puts("\nExpected (from filename): #{expected}")
    
    cond do
      sha256_hash == expected ->
        IO.puts("✓ SHA-256 of decompressed data matches!")
      sha512_256_hash == expected ->
        IO.puts("✓ SHA-512/256 of decompressed data matches!")
      sha256_compressed == expected ->
        IO.puts("✓ SHA-256 of compressed data matches!")
      sha512_256_compressed == expected ->
        IO.puts("✓ SHA-512/256 of compressed data matches!")
      true ->
        IO.puts("✗ None of the hashes match")
        IO.puts("This suggests the testdata might have been generated with different parameters")
        IO.puts("or there's a mismatch in our understanding of the format.")
    end
    
  {:error, reason} ->
    IO.puts("Failed to read chunk file: #{reason}")
end
