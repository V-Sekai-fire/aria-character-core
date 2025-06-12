#!/usr/bin/env elixir

# Debug script to compare our chunking output with expected desync output

Mix.install([
  {:aria_storage, path: "apps/aria_storage"}
])

alias AriaStorage.Chunks
alias AriaStorage.Parsers.CasyncFormat

# Test data paths
input_path = "apps/aria_storage/test/support/testdata/chunker.input"
index_path = "apps/aria_storage/test/support/testdata/chunker.index"

# Load and parse reference data
{:ok, expected_index} = File.read(index_path)
{:ok, index_info} = CasyncFormat.parse_index(expected_index)
expected_chunks = index_info.chunks

{:ok, data} = File.read(input_path)

# Use exact parameters from the index file
min_size = index_info.chunk_size_min
avg_size = index_info.chunk_size_avg
max_size = index_info.chunk_size_max
discriminator = Chunks.discriminator_from_avg(avg_size)

IO.puts("=== DEBUG CHUNKING COMPARISON ===")
IO.puts("Input file size: #{byte_size(data)} bytes")
IO.puts("Parameters: min=#{min_size}, avg=#{avg_size}, max=#{max_size}")
IO.puts("Discriminator: #{discriminator}")
IO.puts("")

# Create chunks using our algorithm
our_chunks = Chunks.find_all_chunks_in_data(data, min_size, max_size, discriminator, :none)

IO.puts("Expected chunks: #{length(expected_chunks)}")
IO.puts("Our chunks: #{length(our_chunks)}")
IO.puts("")

# Compare first few chunks
IO.puts("=== FIRST 5 CHUNKS COMPARISON ===")
Enum.zip(expected_chunks, our_chunks)
|> Enum.take(5)
|> Enum.with_index()
|> Enum.each(fn {{expected, actual}, i} ->
  IO.puts("Chunk #{i+1}:")
  IO.puts("  Expected: offset=#{expected.offset}, size=#{expected.size}")
  IO.puts("  Actual:   offset=#{actual.offset}, size=#{actual.size}")
  IO.puts("  Match: #{expected.offset == actual.offset and expected.size == actual.size}")
  IO.puts("")
end)

# Show boundary positions
IO.puts("=== EXPECTED CHUNK BOUNDARIES ===")
expected_chunks
|> Enum.take(10)
|> Enum.with_index()
|> Enum.each(fn {chunk, i} ->
  end_pos = chunk.offset + chunk.size
  IO.puts("Chunk #{i+1}: #{chunk.offset} -> #{end_pos} (size: #{chunk.size})")
end)

IO.puts("")
IO.puts("=== OUR CHUNK BOUNDARIES ===")
our_chunks
|> Enum.take(10)
|> Enum.with_index()
|> Enum.each(fn {chunk, i} ->
  end_pos = chunk.offset + chunk.size
  IO.puts("Chunk #{i+1}: #{chunk.offset} -> #{end_pos} (size: #{chunk.size})")
end)
