#!/usr/bin/env elixir

Mix.install([
  {:aria_storage, path: "apps/aria_storage"}
])

# Let's see what boundaries our current implementation actually finds

case File.read("apps/aria_storage/test/support/testdata/chunker.input") do
  {:ok, test_data} ->
    min_size = 16384
    max_size = 262144
    discriminator = 28212
    
    IO.puts "=== CHECKING OUR BOUNDARY DETECTION ==="
    IO.puts "Data size: #{byte_size(test_data)}"
    IO.puts "Min size: #{min_size}"
    IO.puts "Max size: #{max_size}" 
    IO.puts "Discriminator: #{discriminator}"
    IO.puts ""
    
    # Use our algorithm to find boundaries
    chunks = AriaStorage.Chunks.find_all_chunks_in_data(test_data, min_size, max_size, discriminator, :none)
    
    IO.puts "Found #{length(chunks)} chunks:"
    Enum.with_index(chunks) 
    |> Enum.take(10)
    |> Enum.each(fn {chunk, i} ->
      end_pos = chunk.offset + chunk.size
      IO.puts "  Chunk #{i+1}: #{chunk.offset} -> #{end_pos} (size: #{chunk.size})"
    end)
    
    IO.puts ""
    IO.puts "=== MANUAL BOUNDARY SEARCH ==="
    IO.puts "Let's manually search for boundaries using remainder = #{discriminator - 1}"
    
    # Manually search for the first few boundaries starting from min_size
    window_size = 48
    target_remainder = discriminator - 1
    found_boundaries = []
    
    # Search from min_size onwards
    pos = min_size
    count = 0
    
    while pos < byte_size(test_data) and count < 5 do
      if pos >= window_size do
        # Window ends at pos
        window_start = pos - window_size + 1
        window_data = binary_part(test_data, window_start, window_size)
        hash = AriaStorage.Chunks.calculate_buzhash_test(window_data)
        remainder = rem(hash, discriminator)
        
        if remainder == target_remainder do
          found_boundaries = [pos | found_boundaries]
          count = count + 1
          IO.puts "  Manual boundary found at pos #{pos}"
        end
      end
      pos = pos + 1
    end
    
    IO.puts ""
    if length(found_boundaries) == 0 do
      IO.puts "❌ NO MANUAL BOUNDARIES FOUND!"
      IO.puts "This suggests that either:"
      IO.puts "1. The boundary condition is wrong"
      IO.puts "2. The hash calculation is wrong"
      IO.puts "3. The discriminator calculation is wrong"
    else
      IO.puts "✅ Manual boundaries: #{Enum.reverse(found_boundaries)}"
      IO.puts "   Our algorithm boundaries: #{Enum.take(chunks, 5) |> Enum.map(fn c -> c.offset + c.size end)}"
    end
    
  {:error, reason} ->
    IO.puts "Failed to read test data: #{inspect(reason)}"
end
