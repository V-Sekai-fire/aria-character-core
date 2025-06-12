#!/usr/bin/env elixir

# Setup the application path
IO.puts("Loading application...")
Application.put_env(:aria_storage, :launch_type, :script)

# Add code paths
Code.prepend_path("_build/dev/lib/aria_storage/ebin")
Code.prepend_path("_build/dev/lib/aria_storage/consolidated")

# Load dependencies
:ok = Application.ensure_loaded(:aria_storage)
:ok = Application.ensure_loaded(:ezstd)
:ok = Application.ensure_loaded(:crypto)

IO.puts("Starting testing...")

# Load modules
alias AriaStorage.Chunks
alias AriaStorage.Utils
alias AriaStorage.Parsers.CasyncFormat

# Configure paths
input_path = Path.join(__DIR__, "apps/aria_storage/test/support/testdata/chunker.input")
index_path = Path.join(__DIR__, "apps/aria_storage/test/support/testdata/chunker.index")

# Parse the expected index file to get chunk info
{:ok, expected_index} = File.read(index_path)
{:ok, index_info} = CasyncFormat.parse_index(expected_index)
expected_chunks = index_info.chunks

IO.puts("\n=== EXPECTED CHUNKS ===")
IO.puts("Expected chunks count: #{length(expected_chunks)}")
first_chunk = List.first(expected_chunks)
IO.puts("First chunk ID: #{Base.encode16(first_chunk.id, case: :lower) |> String.slice(0, 16)}...")
IO.puts("First chunk size: #{first_chunk.size}")

# Test with our chunking algorithm
IO.puts("\n=== RUNNING CHUNKING ALGORITHM ===")
{:ok, data} = File.read(input_path)
IO.puts("Input file size: #{byte_size(data)} bytes")

# Use the same parameters as desync/casync
min_size = 16 * 1024       # 16KB
avg_size = 64 * 1024       # 64KB
max_size = 256 * 1024      # 256KB
discriminator = Chunks.discriminator_from_avg(avg_size)

IO.puts("Parameters: min=#{min_size}, avg=#{avg_size}, max=#{max_size}, discriminator=#{discriminator}")

# Create chunks and time the operation
{time_us, our_chunks} = :timer.tc(fn ->
  Chunks.find_all_chunks_in_data(data, min_size, max_size, discriminator, :none)
end)

IO.puts("Chunking completed in #{time_us / 1000} ms")
IO.puts("Our chunks count: #{length(our_chunks)}")

# Compare the first chunk
our_first_chunk = List.first(our_chunks)
first_chunk_id_hex = Base.encode16(our_first_chunk.id, case: :lower)
IO.puts("Our first chunk ID: #{String.slice(first_chunk_id_hex, 0, 16)}...")
IO.puts("Our first chunk size: #{our_first_chunk.size}")

# Compare chunk counts
if length(our_chunks) == length(expected_chunks) do
  IO.puts("\n✅ CHUNK COUNT MATCHES: #{length(our_chunks)} chunks")
else
  IO.puts("\n❌ CHUNK COUNT MISMATCH: Expected #{length(expected_chunks)}, got #{length(our_chunks)}")
end

# Compare chunk boundaries
IO.puts("\n=== CHECKING CHUNK BOUNDARIES ===")
chunk_boundaries_match = true
prev_offset = 0

Enum.with_index(our_chunks) |> Enum.each(fn {chunk, i} ->
  expected_chunk = Enum.at(expected_chunks, i)

  if chunk.offset != prev_offset do
    IO.puts("❌ BOUNDARY GAP: Chunk #{i+1} offset #{chunk.offset} doesn't follow previous chunk end #{prev_offset}")
    chunk_boundaries_match = false
  else
    exp_offset = expected_chunk && expected_chunk.offset || :unknown
    if chunk.offset == exp_offset do
      IO.puts("✅ Chunk #{i+1}: offset #{chunk.offset} matches expected")
    else
      IO.puts("❌ Chunk #{i+1}: offset #{chunk.offset} doesn't match expected #{exp_offset}")
      chunk_boundaries_match = false
    end
  end

  prev_offset = chunk.offset + chunk.size
end)

# Summary
IO.puts("\n=== OVERALL VERIFICATION ===")
if length(our_chunks) == length(expected_chunks) && chunk_boundaries_match do
  IO.puts("✅ SUCCESS: Our chunking matches desync/casync exactly!")
else
  IO.puts("❌ MISMATCH: Our chunking doesn't match desync/casync")
end
