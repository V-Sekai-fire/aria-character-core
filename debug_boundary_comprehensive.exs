#!/usr/bin/env elixir

Mix.install([
  {:aria_storage, path: "apps/aria_storage"}
])

# Comprehensive analysis of boundary detection around position 81590

case File.read("apps/aria_storage/test/support/testdata/chunker.input") do
  {:ok, test_data} ->
    discriminator = 28212
    window_size = 48
    target_remainder = discriminator - 1  # 28211
    
    IO.puts "=== COMPREHENSIVE BOUNDARY ANALYSIS ==="
    IO.puts "Target position: 81590"
    IO.puts "Discriminator: #{discriminator}"
    IO.puts "Target remainder: #{target_remainder}"
    IO.puts ""
    
    # Check a wide range around the expected boundary
    start_range = 81590 - 200
    end_range = 81590 + 200
    
    boundaries_found = for pos <- start_range..end_range do
      # Test all possible window interpretations
      results = []
      
      # Interpretation A: Window ending at pos
      if pos >= window_size do
        window_start = pos - window_size + 1
        window_data = binary_part(test_data, window_start, window_size)
        hash = AriaStorage.Chunks.calculate_buzhash_test(window_data)
        remainder = rem(hash, discriminator)
        if remainder == target_remainder do
          results = [{:window_ends_at, pos, hash, remainder} | results]
        end
      end
      
      # Interpretation B: Window starting at pos  
      if pos + window_size <= byte_size(test_data) do
        window_data = binary_part(test_data, pos, window_size)
        hash = AriaStorage.Chunks.calculate_buzhash_test(window_data)
        remainder = rem(hash, discriminator)
        if remainder == target_remainder do
          results = [{:window_starts_at, pos, hash, remainder} | results]
        end
      end
      
      # Interpretation C: Boundary position (as used in some algorithms)
      if pos >= window_size and pos < byte_size(test_data) do
        # Window from (pos - window_size) to (pos - 1)
        window_start = pos - window_size
        window_data = binary_part(test_data, window_start, window_size)
        hash = AriaStorage.Chunks.calculate_buzhash_test(window_data)
        remainder = rem(hash, discriminator)
        if remainder == target_remainder do
          results = [{:boundary_at, pos, hash, remainder} | results]
        end
      end
      
      if length(results) > 0 do
        {pos, results}
      else
        nil
      end
    end
    |> Enum.filter(&(&1 != nil))
    
    IO.puts "=== BOUNDARIES FOUND IN RANGE #{start_range}..#{end_range} ==="
    if length(boundaries_found) == 0 do
      IO.puts "❌ NO BOUNDARIES FOUND!"
      IO.puts ""
      IO.puts "This suggests the boundary detection logic is fundamentally wrong."
      IO.puts "Let's check what remainder values exist around position 81590:"
      IO.puts ""
      
      # Show remainder values around target position
      for pos <- (81590-10)..(81590+10) do
        if pos >= window_size do
          window_start = pos - window_size + 1
          window_data = binary_part(test_data, window_start, window_size)
          hash = AriaStorage.Chunks.calculate_buzhash_test(window_data)
          remainder = rem(hash, discriminator)
          marker = if pos == 81590, do: " <- TARGET", else: ""
          IO.puts "  Pos #{pos}: remainder=#{remainder}#{marker}"
        end
      end
    else
      Enum.each(boundaries_found, fn {pos, interpretations} ->
        IO.puts "✅ Position #{pos}:"
        Enum.each(interpretations, fn {type, pos, hash, remainder} ->
          IO.puts "    #{type}: hash=#{hash}, remainder=#{remainder}"
        end)
      end)
    end
    
  {:error, reason} ->
    IO.puts "Failed to read test data: #{inspect(reason)}"
end
