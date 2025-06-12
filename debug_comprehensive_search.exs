#!/usr/bin/env elixir

# Comprehensive debug to find exact desync window positioning

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

IO.puts("=== COMPREHENSIVE BOUNDARY DETECTION DEBUG ===")
IO.puts("Input file size: #{byte_size(data)} bytes")
IO.puts("Parameters: min=#{min_size}, avg=#{avg_size}, max=#{max_size}")
IO.puts("Discriminator: #{discriminator}")
IO.puts("Window size: #{window_size}")
IO.puts("")

# First expected boundary: 81590
# Our algorithm finds: 46409 (from earlier run)
first_expected = 81590

IO.puts("Expected first boundary: #{first_expected}")
IO.puts("")

# Test both window positioning approaches around the expected boundary
IO.puts("=== TESTING WINDOW POSITIONING AROUND EXPECTED BOUNDARY ===")

# Test range around the expected boundary
test_range = (first_expected - 20)..(first_expected + 20)

IO.puts("Testing positions around #{first_expected}...")

# Method 1: Window ENDS at position (our current approach)
IO.puts("\n--- Method 1: Window ENDS at position ---")
for pos <- test_range do
  if pos >= window_size - 1 and pos < byte_size(data) do
    window_start = pos - window_size + 1
    if window_start >= 0 do
      window_data = binary_part(data, window_start, window_size)
      hash = Chunks.calculate_buzhash_test(window_data)
      remainder = rem(hash, discriminator)
      is_boundary = remainder == discriminator - 1
      
      if is_boundary or pos == first_expected do
        IO.puts("  Pos #{pos}: window [#{window_start}..#{pos}], hash=#{hash}, rem=#{remainder}, boundary?=#{is_boundary}")
      end
    end
  end
end

# Method 2: Window STARTS at position
IO.puts("\n--- Method 2: Window STARTS at position ---")
for pos <- test_range do
  if pos + window_size <= byte_size(data) do
    window_data = binary_part(data, pos, window_size)
    hash = Chunks.calculate_buzhash_test(window_data)
    remainder = rem(hash, discriminator)
    is_boundary = remainder == discriminator - 1
    
    if is_boundary or pos == first_expected do
      IO.puts("  Pos #{pos}: window [#{pos}..#{pos + window_size - 1}], hash=#{hash}, rem=#{remainder}, boundary?=#{is_boundary}")
    end
  end
end

# Method 3: Different boundary conditions
IO.puts("\n--- Method 3: Testing different boundary conditions ---")
boundary_conditions = [
  {0, "rem == 0"},
  {1, "rem == 1"},
  {discriminator - 1, "rem == discriminator - 1"},
  {discriminator - 2, "rem == discriminator - 2"}
]

for pos <- [first_expected - 1, first_expected, first_expected + 1] do
  if pos >= window_size - 1 and pos < byte_size(data) do
    window_start = pos - window_size + 1
    window_data = binary_part(data, window_start, window_size)
    hash = Chunks.calculate_buzhash_test(window_data)
    remainder = rem(hash, discriminator)
    
    IO.puts("  Pos #{pos}: hash=#{hash}, rem=#{remainder}")
    for {condition_value, condition_desc} <- boundary_conditions do
      is_boundary = remainder == condition_value
      IO.puts("    #{condition_desc}: #{is_boundary}")
    end
  end
end

# Method 4: Search for ANY position that would give us the expected boundary
IO.puts("\n--- Method 4: Searching for positions with boundary condition ---")
found_boundaries = []

# Search a wider range to find where boundaries occur
search_range = (min_size)..(first_expected + 1000)

for pos <- search_range do
  if pos >= window_size - 1 and pos < byte_size(data) do
    window_start = pos - window_size + 1
    window_data = binary_part(data, window_start, window_size)
    hash = Chunks.calculate_buzhash_test(window_data)
    remainder = rem(hash, discriminator)
    
    if remainder == discriminator - 1 do
      found_boundaries = [pos | found_boundaries]
      if length(found_boundaries) <= 10 do
        IO.puts("  Found boundary at pos #{pos}: hash=#{hash}, rem=#{remainder}")
      end
    end
  end
end

found_boundaries = Enum.reverse(found_boundaries)
IO.puts("Found #{length(found_boundaries)} boundaries in range #{min_size}..#{first_expected + 1000}")
if length(found_boundaries) > 0 do
  IO.puts("First few: #{inspect(Enum.take(found_boundaries, 5))}")
end
