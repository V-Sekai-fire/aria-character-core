#!/usr/bin/env elixir

Code.eval_file("deps.exs")

# Test data
test_data = File.read!("test_data.bin")
min_size = 16 * 1024  # 16KB
avg_size = 64 * 1024  # 64KB
max_size = 256 * 1024 # 256KB

# Calculate discriminator
discriminator = round(avg_size / (1.0 + (-0.0000001428888521 * avg_size + 1.3323751522)))

IO.puts "=== HASH DEBUGGING ==="
IO.puts "Discriminator: #{discriminator}"
IO.puts "Test data size: #{byte_size(test_data)}"
IO.puts ""

# Let's examine what happens around the expected first boundary at position 81590
expected_boundary = 81590
search_start = max(min_size, 48)  # Start from min_size or window size
window_size = 48

IO.puts "Searching from position #{search_start} to #{expected_boundary + 100}"
IO.puts ""

# Check hashes at various positions around the expected boundary
for pos <- (expected_boundary - 10)..(expected_boundary + 10) do
  if pos >= window_size and pos < byte_size(test_data) do
    # Get the window ending at this position
    window_start = pos - window_size + 1
    window_data = binary_part(test_data, window_start, window_size)
    hash = AriaStorage.Chunks.calculate_buzhash_test(window_data)
    remainder = rem(hash, discriminator)
    is_boundary = remainder == discriminator - 1
    
    IO.puts "Pos #{pos}: hash=#{hash}, rem=#{remainder}, boundary=#{is_boundary}"
  end
end

IO.puts ""
IO.puts "=== ROLLING HASH TEST ==="

# Test our rolling hash starting from min_size
start_pos = search_start
window_start = start_pos - window_size + 1

if window_start >= 0 do
  # Initial window
  initial_window = binary_part(test_data, window_start, window_size)
  hash = AriaStorage.Chunks.calculate_buzhash_test(initial_window)
  
  IO.puts "Initial position #{start_pos}:"
  IO.puts "  Window start: #{window_start}"
  IO.puts "  Hash: #{hash}"
  IO.puts "  Remainder: #{rem(hash, discriminator)}"
  IO.puts "  Is boundary: #{rem(hash, discriminator) == discriminator - 1}"
  IO.puts ""
  
  # Test rolling the hash forward a few positions
  current_hash = hash
  for offset <- 1..20 do
    new_pos = start_pos + offset
    if new_pos < byte_size(test_data) do
      # Calculate what the new hash should be
      old_window_start = window_start + offset - 1
      new_window_start = window_start + offset
      
      if new_window_start + window_size <= byte_size(test_data) do
        # Get the actual window for verification
        actual_window = binary_part(test_data, new_window_start, window_size)
        actual_hash = AriaStorage.Chunks.calculate_buzhash_test(actual_window)
        
        # Calculate rolling hash
        out_byte = :binary.at(test_data, old_window_start)
        in_byte = :binary.at(test_data, new_window_start + window_size - 1)
        
        rolled_hash = AriaStorage.Chunks.update_buzhash(current_hash, out_byte, in_byte)
        current_hash = rolled_hash
        
        remainder = rem(rolled_hash, discriminator)
        is_boundary = remainder == discriminator - 1
        
        matches = if rolled_hash == actual_hash, do: "✓", else: "✗ (expected #{actual_hash})"
        
        IO.puts "Pos #{new_pos}: rolled=#{rolled_hash} #{matches}, rem=#{remainder}, boundary=#{is_boundary}"
      end
    end
  end
end
