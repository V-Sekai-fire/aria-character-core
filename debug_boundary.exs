#!/usr/bin/env elixir

# Debug script to test boundary detection specifically

Mix.install([
  {:aria_storage, path: "apps/aria_storage"}
])

alias AriaStorage.Chunks

# Test data paths
input_path = "apps/aria_storage/test/support/testdata/chunker.input"
{:ok, data} = File.read(input_path)

# Use same parameters as test
min_size = 16 * 1024
avg_size = 64 * 1024
max_size = 256 * 1024
discriminator = Chunks.discriminator_from_avg(avg_size)

IO.puts("=== BOUNDARY DETECTION DEBUG ===")
IO.puts("Input file size: #{byte_size(data)} bytes")
IO.puts("Parameters: min=#{min_size}, avg=#{avg_size}, max=#{max_size}")
IO.puts("Discriminator: #{discriminator}")
IO.puts("")

# Test the first boundary detection
# We know the first expected boundary should be at position 81590
# Let's see what our algorithm finds starting from min_size (16384)

# Manually test boundary detection from position 16384 to see where we find boundaries
test_positions = [16384, 40000, 60000, 80000, 81590, 90000]

for pos <- test_positions do
  if pos + 48 <= byte_size(data) do
    # Get a window at this position
    window_data = binary_part(data, pos - 47, 48)
    hash = AriaStorage.Chunks.calculate_buzhash_test(window_data)
    is_boundary = rem(hash, discriminator) == discriminator - 1
    
    IO.puts("Position #{pos}: hash=#{hash}, rem=#{rem(hash, discriminator)}, boundary=#{is_boundary}")
  end
end

IO.puts("")
IO.puts("Expected first boundary at: 81590")
IO.puts("Let's check a few positions around it:")

for pos <- 81580..81600 do
  if pos + 48 <= byte_size(data) do
    window_data = binary_part(data, pos - 47, 48)
    hash = AriaStorage.Chunks.calculate_buzhash_test(window_data)
    is_boundary = rem(hash, discriminator) == discriminator - 1
    
    IO.puts("Position #{pos}: hash=#{hash}, rem=#{rem(hash, discriminator)}, boundary=#{is_boundary}")
  end
end
