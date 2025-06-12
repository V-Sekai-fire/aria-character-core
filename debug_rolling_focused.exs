#!/usr/bin/env elixir

# Focused rolling hash debug - test one specific issue at a time

# Setup application paths
Code.prepend_path("_build/dev/lib/aria_storage/ebin")

# Start the application
Application.start(:aria_storage)

alias AriaStorage.Chunks
alias AriaStorage.Parsers.CasyncFormat

# Load test data
{:ok, data} = File.read("apps/aria_storage/test/support/testdata/chunker.input")
{:ok, expected_index} = File.read("apps/aria_storage/test/support/testdata/chunker.index")
{:ok, index_info} = CasyncFormat.parse_index(expected_index)

min_size = index_info.chunk_size_min
discriminator = Chunks.discriminator_from_avg(index_info.chunk_size_avg)

IO.puts "=== FOCUSED ROLLING HASH DEBUG ==="
IO.puts "Data size: #{byte_size(data)} bytes"
IO.puts "Min size: #{min_size}"
IO.puts "Discriminator: #{discriminator}"
IO.puts ""

# Test 1: Basic rolling hash functionality
IO.puts "=== TEST 1: BASIC ROLLING HASH ==="
test_window = binary_part(data, 1000, 48)
hash1 = Chunks.calculate_buzhash_test(test_window)
IO.puts "Test window hash: #{hash1}"

# Test rolling by one byte
next_window = binary_part(data, 1001, 48)
hash2_direct = Chunks.calculate_buzhash_test(next_window)

out_byte = :binary.at(data, 1000)
in_byte = :binary.at(data, 1048)
hash2_rolled = Chunks.update_buzhash_test(hash1, out_byte, in_byte)

IO.puts "Direct next hash: #{hash2_direct}"
IO.puts "Rolled next hash: #{hash2_rolled}"
IO.puts "Rolling hash works: #{hash2_direct == hash2_rolled}"
IO.puts ""

# Test 2: Boundary detection around expected position
IO.puts "=== TEST 2: BOUNDARY DETECTION ==="
expected_boundary = 81590

# Check boundaries around expected position
for pos <- (expected_boundary - 5)..(expected_boundary + 5) do
  if pos >= 48 do
    window_start = pos - 47
    window_data = binary_part(data, window_start, 48)
    hash = Chunks.calculate_buzhash_test(window_data)
    remainder = rem(hash, discriminator)
    is_boundary = remainder == discriminator - 1
    
    marker = if pos == expected_boundary, do: " <-- EXPECTED", else: ""
    IO.puts "Pos #{pos}: hash=#{hash}, rem=#{remainder}, boundary=#{is_boundary}#{marker}"
  end
end

IO.puts ""

# Test 3: Find our actual first boundary
IO.puts "=== TEST 3: OUR FIRST BOUNDARY ==="
start_search = min_size

our_first_boundary = Enum.find(start_search..(start_search + 100000), fn pos ->
  if pos >= 48 do
    window_start = pos - 47
    window_data = binary_part(data, window_start, 48)
    hash = Chunks.calculate_buzhash_test(window_data)
    remainder = rem(hash, discriminator)
    remainder == discriminator - 1
  else
    false
  end
end)

case our_first_boundary do
  nil ->
    IO.puts "No boundary found in search range"
  pos ->
    IO.puts "Our first boundary found at: #{pos}"
    IO.puts "Expected first boundary: #{expected_boundary}"
    IO.puts "Difference: #{pos - expected_boundary}"
end
