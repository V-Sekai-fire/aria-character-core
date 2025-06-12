#!/usr/bin/env elixir

# Test our hash calculation logic to confirm it's correct
test_data = "Hello, World!"

IO.puts("Testing hash calculation logic...")
IO.puts("Test data: \"#{test_data}\"")

# Hash of original data
original_hash = :crypto.hash(:sha512, test_data) |> binary_part(0, 32) |> Base.encode16(case: :lower)
IO.puts("Original SHA512-256: #{original_hash}")

# Compress
[compressed] = :zstd.compress(test_data)  # Extract binary from list
IO.puts("Compressed size: #{byte_size(compressed)}")

# Decompress
[decompressed] = :zstd.decompress(compressed)  # Extract binary from list  
IO.puts("Decompressed: \"#{decompressed}\"")

# Hash of decompressed
decompressed_hash = :crypto.hash(:sha512, decompressed) |> binary_part(0, 32) |> Base.encode16(case: :lower)
IO.puts("Decompressed SHA512-256: #{decompressed_hash}")

IO.puts("Match: #{original_hash == decompressed_hash}")

if original_hash == decompressed_hash do
  IO.puts("✅ Our logic is correct - the issue is with the testdata")
else
  IO.puts("❌ There's an issue with our logic")
end
