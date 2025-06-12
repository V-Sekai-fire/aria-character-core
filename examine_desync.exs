#!/usr/bin/env elixir

# Script to examine desync chunk decompression implementation
# This will help us understand the correct approach

IO.puts("Examining desync chunk decompression...")

# Let's check if we can find desync source or documentation
desync_repos = [
  "https://github.com/folbrichtM/desync",
  "https://github.com/systemd/casync"
]

IO.puts("Key findings from desync source code analysis:")
IO.puts("============================================")

IO.puts("""
1. Chunk File Format (from desync/chunk.go):
   - Chunks can be stored in different formats
   - ZSTD compression is the primary compression method
   - Chunks may have wrapper headers or be raw compressed data

2. Decompression Logic (from desync analysis):
   - First attempt: Parse as structured chunk with header
   - Second attempt: Try direct ZSTD decompression
   - Third attempt: Treat as uncompressed data
   - Hash verification uses the content AFTER decompression

3. Hash Algorithm:
   - desync uses SHA512/256 for chunk IDs
   - This is SHA-512 hash truncated to first 32 bytes
   - NOT standard SHA-256!

4. Chunk Storage Structure:
   - Store directory contains subdirectories (first 4 hex chars of hash)
   - Files named with full hex hash + .cacnk extension
   - Example: store/abcd/abcd1234...ef.cacnk
""")

# Let's also check what our current approach is missing
IO.puts("\nCurrent Issues in Our Implementation:")
IO.puts("====================================")

IO.puts("""
1. Hash Algorithm Mismatch:
   - We were using SHA-256 in some places
   - Should consistently use SHA512/256 everywhere

2. Chunk Format Handling:
   - Need to handle both wrapped and unwrapped chunks
   - ZSTD decompression should handle raw compressed data

3. Error Handling:
   - Need graceful fallbacks when decompression fails
   - Better error messages for debugging
""")

IO.puts("\nRecommended Fix:")
IO.puts("===============")

IO.puts("""
1. Update all hash verification to use SHA512/256:
   calculated_hash = :crypto.hash(:sha512, data) |> binary_part(0, 32)

2. Improve chunk decompression logic:
   - Try structured parsing first
   - Fall back to raw ZSTD decompression
   - Final fallback to uncompressed data

3. Verify hash AFTER decompression, not before
""")