#!/usr/bin/env elixir

# Debug chunk hash mismatch
chunk_path = "apps/aria_storage/test/support/testdata/blob1.store/15cc/15cc115dc5d8bef2fea4cb8ec58fa86d86f5bebb47577670154e625e67ac9e42.cacnk"

IO.puts("Debug chunk hash mismatch starting...")
IO.puts("Looking for chunk at: #{chunk_path}")

if not File.exists?(chunk_path) do
  IO.puts("ERROR: Chunk file does not exist!")
  System.halt(1)
end
{:ok, data} = File.read(chunk_path)

IO.puts("Chunk size: #{byte_size(data)} bytes")
IO.puts("First 20 bytes (hex): #{Base.encode16(binary_part(data, 0, 20))}")

try do
  result = :ezstd.decompress(data)
  IO.puts("Decompressed successfully: #{byte_size(result)} bytes")
  
  # Check if it's printable text
  first_100 = binary_part(result, 0, min(100, byte_size(result)))
  is_printable = String.printable?(first_100)
  
  if is_printable do
    IO.puts("First 100 chars: #{first_100}")
  else
    IO.puts("First 100 bytes (hex): #{Base.encode16(first_100)}")
  end
  
  # Calculate hash of decompressed data using SHA-512 with first 32 bytes (SHA512/256)
  hash_sha512_256 = :crypto.hash(:sha512, result) |> binary_part(0, 32)
  hash_sha512_256_hex = Base.encode16(hash_sha512_256, case: :lower)
  
  # Also try regular SHA-256
  hash_sha256 = :crypto.hash(:sha256, result)
  hash_sha256_hex = Base.encode16(hash_sha256, case: :lower)
  
  IO.puts("SHA512/256 hash: #{hash_sha512_256_hex}")
  IO.puts("SHA256 hash:     #{hash_sha256_hex}")
  
  # Expected hash from filename
  expected = "15cc115dc5d8bef2fea4cb8ec58fa86d86f5bebb47577670154e625e67ac9e42"
  IO.puts("Expected hash:   #{expected}")
  IO.puts("SHA512/256 match: #{hash_sha512_256_hex == expected}")
  IO.puts("SHA256 match:     #{hash_sha256_hex == expected}")
catch
  error -> IO.puts("Decompression failed: #{inspect(error)}")
end
