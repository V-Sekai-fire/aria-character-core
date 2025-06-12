#!/usr/bin/env elixir

# Debug script to trace rolling hash step by step

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

IO.puts("=== STEP BY STEP ROLLING HASH DEBUG ===")
IO.puts("Input file size: #{byte_size(data)} bytes")
IO.puts("Parameters: min=#{min_size}, avg=#{avg_size}, max=#{max_size}")
IO.puts("Discriminator: #{discriminator}")
IO.puts("Expected first boundary at: #{Enum.at(expected_chunks, 0).offset + Enum.at(expected_chunks, 0).size}")
IO.puts("")

# Manual rolling hash calculation for the first expected boundary
window_size = 48
first_expected_boundary = 81590

# Let's check what happens around the first expected boundary
start_pos = first_expected_boundary - window_size + 1
end_pos = first_expected_boundary + 50

IO.puts("=== CHECKING AROUND FIRST EXPECTED BOUNDARY (#{first_expected_boundary}) ===")

for pos <- start_pos..end_pos do
  if pos >= window_size - 1 and pos < byte_size(data) do
    window_start = pos - window_size + 1
    if window_start >= 0 do
      window_data = binary_part(data, window_start, window_size)
      hash = Chunks.calculate_buzhash_test(window_data)
      remainder = rem(hash, discriminator)
      is_boundary = remainder == discriminator - 1
      
      if pos >= first_expected_boundary - 5 and pos <= first_expected_boundary + 5 do
        IO.puts("Pos #{pos}: hash=#{hash}, rem=#{remainder}, boundary?=#{is_boundary} (expected at #{first_expected_boundary})")
      end
    end
  end
end

IO.puts("")
IO.puts("=== OUR ALGORITHM'S FIRST BOUNDARY ===")

# Find our first boundary manually
our_first_boundary = 
  Enum.find(min_size..max_size, fn pos ->
    if pos >= window_size - 1 do
      window_start = pos - window_size + 1
      window_data = binary_part(data, window_start, window_size)
      hash = Chunks.calculate_buzhash_test(window_data)
      remainder = rem(hash, discriminator)
      
      if remainder == discriminator - 1 do
        IO.puts("Found boundary at #{pos}: hash=#{hash}, rem=#{remainder}")
        true
      else
        false
      end
    else
      false
    end
  end)

if our_first_boundary do
  IO.puts("Our algorithm found first boundary at: #{our_first_boundary}")
else
  IO.puts("No boundary found before max size, would use max size: #{max_size}")
end
