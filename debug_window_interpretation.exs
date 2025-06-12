#!/usr/bin/env elixir

# Debug script to understand desync's window positioning

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
window_size = 48

IO.puts("=== DESYNC WINDOW POSITIONING ANALYSIS ===")
IO.puts("Input file size: #{byte_size(data)} bytes")
IO.puts("Parameters: min=#{min_size}, avg=#{avg_size}, max=#{max_size}")
IO.puts("Discriminator: #{discriminator}")
IO.puts("Window size: #{window_size}")
IO.puts("")

# Expected boundaries from the test file
expected_boundaries = expected_chunks |> Enum.map(fn chunk -> chunk.offset + chunk.size end) |> Enum.drop(-1)
IO.puts("Expected boundaries: #{inspect(expected_boundaries |> Enum.take(5))}")
IO.puts("")

# Test different window positioning interpretations
IO.puts("=== TESTING DIFFERENT WINDOW INTERPRETATIONS ===")

# Interpretation 1: Window ends at position (our current approach)
IO.puts("\n--- Interpretation 1: Window ends at position ---")
for pos <- [81590, 128386, 164929] do
  if pos >= window_size - 1 do
    window_start = pos - window_size + 1
    window_data = binary_part(data, window_start, window_size)
    hash = Chunks.calculate_buzhash_test(window_data)
    remainder = rem(hash, discriminator)
    is_boundary = remainder == discriminator - 1
    IO.puts("Pos #{pos}: window [#{window_start}..#{pos}], hash=#{hash}, rem=#{remainder}, boundary?=#{is_boundary}")
  end
end

# Interpretation 2: Window starts at position
IO.puts("\n--- Interpretation 2: Window starts at position ---")
for pos <- [81590, 128386, 164929] do
  if pos + window_size <= byte_size(data) do
    window_data = binary_part(data, pos, window_size)
    hash = Chunks.calculate_buzhash_test(window_data)
    remainder = rem(hash, discriminator)
    is_boundary = remainder == discriminator - 1
    IO.puts("Pos #{pos}: window [#{pos}..#{pos + window_size - 1}], hash=#{hash}, rem=#{remainder}, boundary?=#{is_boundary}")
  end
end

# Interpretation 3: Check if desync uses 0-based boundary condition
IO.puts("\n--- Interpretation 3: Boundary condition (rem == 0) ---")
for pos <- [81590, 128386, 164929] do
  if pos >= window_size - 1 do
    window_start = pos - window_size + 1
    window_data = binary_part(data, window_start, window_size)
    hash = Chunks.calculate_buzhash_test(window_data)
    remainder = rem(hash, discriminator)
    is_boundary_v1 = remainder == discriminator - 1
    is_boundary_v2 = remainder == 0
    IO.puts("Pos #{pos}: hash=#{hash}, rem=#{remainder}, boundary(rem==#{discriminator-1})?=#{is_boundary_v1}, boundary(rem==0)?=#{is_boundary_v2}")
  end
end

# Interpretation 4: Check around expected boundaries with different offsets
IO.puts("\n--- Interpretation 4: Search around expected boundary with different offsets ---")
first_expected = 81590

for offset <- [-2, -1, 0, 1, 2] do
  pos = first_expected + offset
  if pos >= window_size - 1 and pos < byte_size(data) do
    window_start = pos - window_size + 1
    window_data = binary_part(data, window_start, window_size)
    hash = Chunks.calculate_buzhash_test(window_data)
    remainder = rem(hash, discriminator)
    is_boundary = remainder == discriminator - 1
    is_boundary_v2 = remainder == 0
    IO.puts("Pos #{pos} (expected+#{offset}): hash=#{hash}, rem=#{remainder}, boundary(#{discriminator-1})?=#{is_boundary}, boundary(0)?=#{is_boundary_v2}")
  end
end
