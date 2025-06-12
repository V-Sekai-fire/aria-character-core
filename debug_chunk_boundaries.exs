#!/usr/bin/env elixir

# Debug script to understand chunk boundary differences
Mix.install([
  {:aria_storage, path: "apps/aria_storage"}
])

alias AriaStorage.Chunks
alias AriaStorage.Parsers.CasyncFormat

# Load test data
input_path = "apps/aria_storage/test/support/testdata/chunker.input"
index_path = "apps/aria_storage/test/support/testdata/chunker.index"

{:ok, data} = File.read(input_path)
{:ok, expected_index} = File.read(index_path)
{:ok, index_info} = CasyncFormat.parse_index(expected_index)

# Parameters from test
min_size = 16 * 1024       # 16KB
avg_size = 64 * 1024       # 64KB
max_size = 256 * 1024      # 256KB
discriminator = Chunks.discriminator_from_avg(avg_size)

IO.puts("=== CHUNK BOUNDARY DEBUG ===")
IO.puts("Data size: #{byte_size(data)}")
IO.puts("Discriminator: #{discriminator}")
IO.puts("Min size: #{min_size}, Avg size: #{avg_size}, Max size: #{max_size}")

# Get expected chunks
expected_chunks = index_info.chunks
IO.puts("\nExpected chunks: #{length(expected_chunks)}")
Enum.with_index(expected_chunks) |> Enum.each(fn {chunk, i} ->
  IO.puts("  Chunk #{i+1}: offset=#{chunk.offset}, size=#{chunk.size}")
end)

# Get our chunks
our_chunks = Chunks.find_all_chunks_in_data(data, min_size, max_size, discriminator, :none)
IO.puts("\nOur chunks: #{length(our_chunks)}")
Enum.with_index(our_chunks) |> Enum.each(fn {chunk, i} ->
  IO.puts("  Chunk #{i+1}: offset=#{chunk.offset}, size=#{chunk.size}")
end)

# Show first few differences
IO.puts("\n=== BOUNDARY COMPARISON ===")
min_count = min(length(expected_chunks), length(our_chunks))
Enum.zip(Enum.take(expected_chunks, min_count), Enum.take(our_chunks, min_count))
|> Enum.with_index()
|> Enum.each(fn {{expected, actual}, i} ->
  if expected.offset != actual.offset or expected.size != actual.size do
    IO.puts("DIFF Chunk #{i+1}:")
    IO.puts("  Expected: offset=#{expected.offset}, size=#{expected.size}")
    IO.puts("  Actual:   offset=#{actual.offset}, size=#{actual.size}")
  end
end)
