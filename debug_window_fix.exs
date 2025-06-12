#!/usr/bin/env elixir

# Debug script to test the corrected window positioning

Mix.install([
  {:aria_storage, path: "apps/aria_storage"}
])

alias AriaStorage.Chunks
alias AriaStorage.Parsers.CasyncFormat

defmodule WindowPositionTester do
  @window_size 48
  
  def run do
    # Load test data
    input_path = "apps/aria_storage/test/support/testdata/chunker.input"
    index_path = "apps/aria_storage/test/support/testdata/chunker.index"
    
    {:ok, data} = File.read(input_path)
    {:ok, expected_index} = File.read(index_path)
    {:ok, index_info} = CasyncFormat.parse_index(expected_index)
    
    avg_size = index_info.chunk_size_avg
    discriminator = Chunks.discriminator_from_avg(avg_size)
    
    IO.puts("=== WINDOW POSITION CORRECTION TEST ===")
    IO.puts("Discriminator: #{discriminator}")
    IO.puts("Expected boundary: 81590")
    IO.puts("")
    
    # Test the new interpretation: 
    # Boundary position 81590 means the rolling hash window 
    # covers bytes [81590-47..81590+0] = [81543..81590]
    
    # Method 1: Our current approach (window ends at boundary)
    boundary_pos = 81590
    window_start_current = boundary_pos - @window_size + 1  # 81543
    window_current = binary_part(data, window_start_current, @window_size)
    hash_current = Chunks.calculate_buzhash_test(window_current)
    remainder_current = rem(hash_current, discriminator)
    
    IO.puts("Current approach (window ends at boundary):")
    IO.puts("  Window: [#{window_start_current}..#{boundary_pos}]")
    IO.puts("  Hash: #{hash_current}, Remainder: #{remainder_current}")
    IO.puts("  Is boundary: #{remainder_current == discriminator - 1}")
    IO.puts("")
    
    # Method 2: Alternative approach (window starts at boundary-48)
    window_start_alt = boundary_pos - @window_size  # 81542
    window_alt = binary_part(data, window_start_alt, @window_size)
    hash_alt = Chunks.calculate_buzhash_test(window_alt)
    remainder_alt = rem(hash_alt, discriminator)
    
    IO.puts("Alternative approach (window starts at boundary-48):")
    IO.puts("  Window: [#{window_start_alt}..#{window_start_alt + @window_size - 1}]")
    IO.puts("  Hash: #{hash_alt}, Remainder: #{remainder_alt}")
    IO.puts("  Is boundary: #{remainder_alt == discriminator - 1}")
    IO.puts("")
    
    # Method 3: Test desync interpretation
    # In desync, position 81590 might mean the hash window is 
    # positioned such that the boundary detection happens at byte 81590
    # This could mean the window is [81590-47..81590] (same as method 1)
    # OR it could mean the window is at some other position
    
    IO.puts("Testing different window positions for boundary at 81590:")
    
    # Test positions around 81590 to see which one gives remainder 49534
    for offset <- -10..10 do
      test_pos = 81590 + offset
      if test_pos >= @window_size and test_pos < byte_size(data) do
        # Window ending at test_pos
        win_start = test_pos - @window_size + 1
        win_data = binary_part(data, win_start, @window_size)
        hash = Chunks.calculate_buzhash_test(win_data)
        remainder = rem(hash, discriminator)
        
        if remainder == discriminator - 1 do
          IO.puts("  ✅ Position #{test_pos}: window [#{win_start}..#{test_pos}] gives boundary!")
        end
      end
    end
    
    IO.puts("")
    IO.puts("=== CONCLUSION ===")
    if remainder_current == discriminator - 1 do
      IO.puts("✅ Current approach is correct")
    elsif remainder_alt == discriminator - 1 do
      IO.puts("✅ Alternative approach is correct - we need to adjust our window positioning")
    else
      IO.puts("❌ Neither approach gives the expected boundary")
    end
  end
end

WindowPositionTester.run()
