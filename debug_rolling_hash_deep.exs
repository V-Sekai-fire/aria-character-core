#!/usr/bin/env elixir

# Deep debugging of rolling hash implementation
# This script systematically tests every aspect of the rolling hash to find the exact issue

Mix.install([
  {:aria_storage, path: "apps/aria_storage"}
])

alias AriaStorage.Chunks
alias AriaStorage.Parsers.CasyncFormat

defmodule RollingHashDebugger do
  @window_size 48
  
  def run do
    # Load test data
    input_path = "apps/aria_storage/test/support/testdata/chunker.input"
    index_path = "apps/aria_storage/test/support/testdata/chunker.index"
    
    {:ok, data} = File.read(input_path)
    {:ok, expected_index} = File.read(index_path)
    {:ok, index_info} = CasyncFormat.parse_index(expected_index)
    
    min_size = index_info.chunk_size_min
    avg_size = index_info.chunk_size_avg
    max_size = index_info.chunk_size_max
    discriminator = Chunks.discriminator_from_avg(avg_size)
    
    IO.puts("=== ROLLING HASH DEEP DEBUG ===")
    IO.puts("Data size: #{byte_size(data)} bytes")
    IO.puts("Min size: #{min_size}, Avg size: #{avg_size}, Max size: #{max_size}")
    IO.puts("Discriminator: #{discriminator}")
    IO.puts("Window size: #{@window_size}")
    IO.puts("")
    
    # Get expected chunks
    expected_chunks = index_info.chunks
    first_expected_boundary = 81590  # From analysis of expected chunks
    
    IO.puts("Expected first boundary: #{first_expected_boundary}")
    IO.puts("Expected chunk count: #{length(expected_chunks)}")
    IO.puts("")
    
    # Test 1: Verify buzhash table and basic calculation
    test_buzhash_basic()
    
    # Test 2: Verify window positioning interpretation
    test_window_positioning(data, first_expected_boundary, discriminator)
    
    # Test 3: Verify rolling hash update logic
    test_rolling_hash_updates(data, min_size, discriminator)
    
    # Test 4: Compare with desync reference values
    test_desync_reference_comparison(data, expected_chunks, discriminator)
    
    # Test 5: Find our actual boundaries and compare
    test_boundary_detection_complete(data, min_size, max_size, discriminator, expected_chunks)
  end
  
  def test_buzhash_basic do
    IO.puts("=== TEST 1: BUZHASH BASIC CALCULATION ===")
    
    # Test with known data
    test_data = "Hello, World! This is a test string for buzhash testing."
    
    if byte_size(test_data) >= @window_size do
      window = binary_part(test_data, 0, @window_size)
      hash = Chunks.calculate_buzhash_test(window)
      
      IO.puts("Test string: #{inspect(test_data)}")
      IO.puts("Window (#{@window_size} bytes): #{inspect(window)}")
      IO.puts("Hash: #{hash} (0x#{Integer.to_string(hash, 16)})")
      
      # Test rolling by one byte
      if byte_size(test_data) > @window_size do
        next_window = binary_part(test_data, 1, @window_size)
        next_hash_direct = Chunks.calculate_buzhash_test(next_window)
        
        out_byte = :binary.at(test_data, 0)
        in_byte = :binary.at(test_data, @window_size)
        next_hash_rolled = Chunks.update_buzhash_test(hash, out_byte, in_byte)
        
        IO.puts("Next window: #{inspect(next_window)}")
        IO.puts("Direct hash: #{next_hash_direct}")
        IO.puts("Rolled hash: #{next_hash_rolled}")
        IO.puts("Match: #{next_hash_direct == next_hash_rolled}")
        
        if next_hash_direct != next_hash_rolled do
          IO.puts("❌ ROLLING HASH UPDATE IS BROKEN!")
          :failed
        else
          IO.puts("✅ Rolling hash update works correctly")
          :ok
        end
      end
    end
    
    IO.puts("")
  end
  
  def test_window_positioning(data, first_expected_boundary, discriminator) do
    IO.puts("=== TEST 2: WINDOW POSITIONING ===")
    
    # Test different interpretations of window positioning around expected boundary
    test_positions = [first_expected_boundary - 2, first_expected_boundary - 1, 
                     first_expected_boundary, first_expected_boundary + 1, first_expected_boundary + 2]
    
    IO.puts("Testing positions around expected boundary #{first_expected_boundary}:")
    
    Enum.each(test_positions, fn pos ->
      if pos >= @window_size and pos < byte_size(data) do
        # Method 1: Window ends at pos (our current approach)
        window_start1 = pos - @window_size + 1
        window1 = binary_part(data, window_start1, @window_size)
        hash1 = Chunks.calculate_buzhash_test(window1)
        remainder1 = rem(hash1, discriminator)
        boundary1 = remainder1 == discriminator - 1
        
        # Method 2: Window starts at pos
        if pos + @window_size <= byte_size(data) do
          window2 = binary_part(data, pos, @window_size)
          hash2 = Chunks.calculate_buzhash_test(window2)
          remainder2 = rem(hash2, discriminator)
          boundary2 = remainder2 == discriminator - 1
          
          IO.puts("Pos #{pos}:")
          IO.puts("  Window ends at pos:   hash=#{hash1}, rem=#{remainder1}, boundary=#{boundary1}")
          IO.puts("  Window starts at pos: hash=#{hash2}, rem=#{remainder2}, boundary=#{boundary2}")
        else
          IO.puts("Pos #{pos}:")
          IO.puts("  Window ends at pos:   hash=#{hash1}, rem=#{remainder1}, boundary=#{boundary1}")
          IO.puts("  Window starts at pos: N/A (beyond data)")
        end
      end
    end)
    
    IO.puts("")
  end
  
  def test_rolling_hash_updates(data, min_size, discriminator) do
    IO.puts("=== TEST 3: ROLLING HASH CONSISTENCY ===")
    
    # Start from min_size and test rolling for several positions
    start_pos = min_size
    test_length = 100  # Test 100 positions
    
    if start_pos >= @window_size and start_pos + test_length < byte_size(data) do
      # Get initial window ending at start_pos
      window_start = start_pos - @window_size + 1
      initial_window = binary_part(data, window_start, @window_size)
      current_hash = Chunks.calculate_buzhash_test(initial_window)
      
      IO.puts("Starting at position #{start_pos}")
      IO.puts("Initial window: [#{window_start}..#{start_pos}]")
      IO.puts("Initial hash: #{current_hash}")
      
      # Test rolling forward using functional approach with Enum.reduce
      {final_state, errors} = 
        Enum.reduce(1..test_length, {current_hash, 0}, fn offset, {current_hash_state, error_count} ->
          new_pos = start_pos + offset
          
          # Calculate expected hash directly
          new_window_start = window_start + offset
          expected_window = binary_part(data, new_window_start, @window_size)
          expected_hash = Chunks.calculate_buzhash_test(expected_window)
          
          # Calculate hash using rolling update
          # When window moves from [window_start..window_start+size-1] to [window_start+1..window_start+size]
          # Byte leaving: window_start + offset - 1 (the old start)
          # Byte entering: window_start + offset + @window_size - 1 (the new end)
          out_byte = :binary.at(data, window_start + offset - 1)  # Byte leaving window
          in_byte = :binary.at(data, window_start + offset + @window_size - 1)  # Byte entering window
          rolled_hash = Chunks.update_buzhash_test(current_hash_state, out_byte, in_byte)
          
          new_error_count = if expected_hash != rolled_hash do
            if error_count < 5 do  # Only show first 5 errors
              IO.puts("❌ Mismatch at pos #{new_pos}: expected=#{expected_hash}, rolled=#{rolled_hash}")
              IO.puts("   Window: [#{new_window_start}..#{new_pos}]")
              IO.puts("   Out byte: #{out_byte}, In byte: #{in_byte}")
            end
            error_count + 1
          else
            error_count
          end
          
          {rolled_hash, new_error_count}  # Return updated state
        end)
      
      if errors == 0 do
        IO.puts("✅ All #{test_length} rolling hash updates are correct")
      else
        IO.puts("❌ Found #{errors} rolling hash errors out of #{test_length} tests")
      end
    end
    
    IO.puts("")
  end
  
  def test_desync_reference_comparison(data, expected_chunks, discriminator) do
    IO.puts("=== TEST 4: DESYNC REFERENCE COMPARISON ===")
    
    # Check if our hash values at expected boundary positions match what would create boundaries
    Enum.with_index(expected_chunks) 
    |> Enum.take(5)  # Test first 5 chunks
    |> Enum.each(fn {chunk, i} ->
      boundary_pos = chunk.offset + chunk.size
      
      if boundary_pos >= @window_size and boundary_pos < byte_size(data) do
        # Test our boundary calculation at this position
        window_start = boundary_pos - @window_size + 1
        window_data = binary_part(data, window_start, @window_size)
        hash = Chunks.calculate_buzhash_test(window_data)
        remainder = rem(hash, discriminator)
        is_boundary = remainder == discriminator - 1
        
        IO.puts("Expected boundary #{i+1} at pos #{boundary_pos}:")
        IO.puts("  Window: [#{window_start}..#{boundary_pos}]")
        IO.puts("  Hash: #{hash}")
        IO.puts("  Remainder: #{remainder} (target: #{discriminator - 1})")
        IO.puts("  Is boundary: #{is_boundary}")
        
        if not is_boundary do
          # Try alternative positioning
          if boundary_pos - 1 >= @window_size do
            alt_window_start = boundary_pos - @window_size
            alt_window = binary_part(data, alt_window_start, @window_size)
            alt_hash = Chunks.calculate_buzhash_test(alt_window)
            alt_remainder = rem(alt_hash, discriminator)
            alt_boundary = alt_remainder == discriminator - 1
            
            IO.puts("  Alternative (window starts at boundary-#{@window_size}):")
            IO.puts("    Hash: #{alt_hash}, Remainder: #{alt_remainder}, Boundary: #{alt_boundary}")
          end
        end
      end
    end)
    
    IO.puts("")
  end
  
  def test_boundary_detection_complete(data, min_size, max_size, discriminator, expected_chunks) do
    IO.puts("=== TEST 5: COMPLETE BOUNDARY DETECTION ===")
    
    # Find our actual boundaries
    our_chunks = Chunks.find_all_chunks_in_data(data, min_size, max_size, discriminator, :none)
    
    IO.puts("Our chunks: #{length(our_chunks)}")
    IO.puts("Expected chunks: #{length(expected_chunks)}")
    
    # Show first few boundary comparisons
    max_compare = min(length(our_chunks), length(expected_chunks))
    
    for i <- 0..(max_compare - 1) do
      our_chunk = Enum.at(our_chunks, i)
      expected_chunk = Enum.at(expected_chunks, i)
      
      our_boundary = our_chunk.offset + our_chunk.size
      expected_boundary = expected_chunk.offset + expected_chunk.size
      
      match = our_boundary == expected_boundary
      
      IO.puts("Chunk #{i+1}: ours=#{our_boundary}, expected=#{expected_boundary}, match=#{match}")
      
      if not match and i < 3 do
        # For first few mismatches, investigate the area around expected boundary
        investigate_boundary_area(data, expected_boundary, discriminator)
      end
    end
    
    # Summary
    exact_matches = Enum.zip(our_chunks, expected_chunks)
    |> Enum.count(fn {our, expected} -> 
      our.offset + our.size == expected.offset + expected.size
    end)
    
    IO.puts("")
    IO.puts("=== SUMMARY ===")
    IO.puts("Exact boundary matches: #{exact_matches}/#{max_compare}")
    
    if exact_matches == max_compare and length(our_chunks) == length(expected_chunks) do
      IO.puts("✅ PERFECT MATCH - Our algorithm works correctly!")
    else
      IO.puts("❌ MISMATCH - Algorithm needs fixing")
      
      # Show where our first boundary differs
      if length(our_chunks) > 0 and length(expected_chunks) > 0 do
        our_first = List.first(our_chunks)
        expected_first = List.first(expected_chunks)
        
        IO.puts("")
        IO.puts("First boundary analysis:")
        IO.puts("  Our first boundary: #{our_first.offset + our_first.size}")
        IO.puts("  Expected first boundary: #{expected_first.offset + expected_first.size}")
        IO.puts("  Difference: #{(our_first.offset + our_first.size) - (expected_first.offset + expected_first.size)}")
      end
    end
  end
  
  def investigate_boundary_area(data, expected_boundary, discriminator) do
    IO.puts("  🔍 Investigating area around expected boundary #{expected_boundary}:")
    
    # Check a range around the expected boundary
    range_start = max(expected_boundary - 50, @window_size)
    range_end = min(expected_boundary + 50, byte_size(data) - @window_size)
    
    boundaries_found = for pos <- range_start..range_end do
      window_start = pos - @window_size + 1
      window_data = binary_part(data, window_start, @window_size)
      hash = Chunks.calculate_buzhash_test(window_data)
      remainder = rem(hash, discriminator)
      
      if remainder == discriminator - 1 do
        pos
      else
        nil
      end
    end |> Enum.filter(&(&1 != nil))
    
    if length(boundaries_found) > 0 do
      IO.puts("    Actual boundaries in range #{range_start}..#{range_end}: #{inspect(boundaries_found)}")
      IO.puts("    Closest to expected: #{Enum.min_by(boundaries_found, &abs(&1 - expected_boundary))}")
    else
      IO.puts("    No boundaries found in range #{range_start}..#{range_end}")
    end
  end
end

RollingHashDebugger.run()
