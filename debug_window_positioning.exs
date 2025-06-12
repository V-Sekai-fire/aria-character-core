#!/usr/bin/env elixir

Mix.install([
  {:aria_storage, path: "apps/aria_storage"}
])

# Let's debug the exact positioning and hash calculation step by step
# focusing on the expected first boundary at position 81590

case File.read("apps/aria_storage/test/support/testdata/chunker.input") do
  {:ok, test_data} ->
    min_size = 16384
    discriminator = 28212
    window_size = 48

    IO.puts "=== STEP-BY-STEP HASH DEBUGGING ==="
    IO.puts "Data size: #{byte_size(test_data)}"
    IO.puts "Min size: #{min_size}"
    IO.puts "Window size: #{window_size}"
    IO.puts "Discriminator: #{discriminator}"
    IO.puts "Expected boundary: 81590"
    IO.puts ""

    # Let's check what happens at different interpretations of window positioning

    # Interpretation 1: Window ends at position (desync style)
    IO.puts "=== INTERPRETATION 1: Window ends at position ==="
    for pos <- [81588, 81589, 81590, 81591, 81592] do
      if pos >= window_size do
        window_start = pos - window_size + 1
        window_data = binary_part(test_data, window_start, window_size)
        hash = AriaStorage.Chunks.calculate_buzhash_test(window_data)
        remainder = rem(hash, discriminator)
        is_boundary = remainder == discriminator - 1
        
        IO.puts "Pos #{pos}: window [#{window_start}..#{pos}], hash=#{hash}, rem=#{remainder}, boundary=#{is_boundary}"
      end
    end

    IO.puts ""

    # Interpretation 2: Window starts at position
    IO.puts "=== INTERPRETATION 2: Window starts at position ==="
    for pos <- [81542, 81543, 81544, 81545, 81546] do  # 81590 - 48 = 81542
      if pos + window_size <= byte_size(test_data) do
        window_data = binary_part(test_data, pos, window_size)
        hash = AriaStorage.Chunks.calculate_buzhash_test(window_data)
        remainder = rem(hash, discriminator)
        is_boundary = remainder == discriminator - 1
        
        window_end = pos + window_size - 1
        IO.puts "Pos #{pos}: window [#{pos}..#{window_end}], hash=#{hash}, rem=#{remainder}, boundary=#{is_boundary}"
      end
    end

    # Let's also examine our current implementation to see where it finds the first boundary
    IO.puts ""
    IO.puts "=== OUR CURRENT IMPLEMENTATION ==="

    # Simulate our algorithm
    start_pos = min_size
    window_start = start_pos - window_size + 1

    if window_start >= 0 do
      initial_window = binary_part(test_data, window_start, window_size)
      hash = AriaStorage.Chunks.calculate_buzhash_test(initial_window)
      
      IO.puts "Starting from pos #{start_pos} (window #{window_start}..#{start_pos})"
      IO.puts "Initial hash: #{hash}, remainder: #{rem(hash, discriminator)}"
      
      # Check a few positions forward to see where we find a boundary
      current_hash = hash
      boundary_found = Enum.find_value(0..100, fn offset ->
        test_pos = start_pos + offset
        if test_pos < byte_size(test_data) and test_pos - window_size + 1 >= 0 do
          new_hash = if offset == 0 do
            # First position, use initial hash
            current_hash
          else
            # Roll the hash forward
            old_window_start = window_start + offset - 1
            new_window_start = window_start + offset
            
            if new_window_start + window_size <= byte_size(test_data) do
              out_byte = :binary.at(test_data, old_window_start)
              in_byte = :binary.at(test_data, new_window_start + window_size - 1)
              AriaStorage.Chunks.update_buzhash_test(current_hash, out_byte, in_byte)
            else
              current_hash
            end
          end
          
          remainder = rem(new_hash, discriminator)
          if remainder == discriminator - 1 do
            {test_pos, new_hash, remainder}
          else
            nil
          end
        else
          nil
        end
      end)
      
      case boundary_found do
        {pos, hash_val, remainder} ->
          IO.puts "Found boundary at pos #{pos}! Hash=#{hash_val}, remainder=#{remainder}"
        nil ->
          IO.puts "No boundary found in first 100 positions"
      end
    end
    
  {:error, reason} ->
    IO.puts "Failed to read test data: #{inspect(reason)}"
end
