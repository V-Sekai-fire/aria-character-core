#!/usr/bin/env elixir

# Minimal rolling hash debug

Mix.install([
  {:aria_storage, path: "apps/aria_storage"}
])

alias AriaStorage.Chunks
import Bitwise

# Test with simple data first
test_data = "Hello, World! This is a test string for buzhash testing. More data here to test rolling hash properly. ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

window_size = 48

IO.puts("=== MINIMAL ROLLING HASH DEBUG ===")
IO.puts("Data: #{inspect(test_data)}")
IO.puts("Window size: #{window_size}")

# Start from position where we have enough data for a full window
start_pos = window_size - 1  # Position 47

IO.puts("\n=== SINGLE STEP TEST ===")

# Initial window: [0..47]
initial_window = binary_part(test_data, 0, window_size)
initial_hash = Chunks.calculate_buzhash_test(initial_window)

IO.puts("Initial window: #{inspect(initial_window)}")
IO.puts("Initial hash: #{initial_hash}")

# Next window: [1..48] 
next_window = binary_part(test_data, 1, window_size)
expected_hash = Chunks.calculate_buzhash_test(next_window)

IO.puts("Next window:    #{inspect(next_window)}")
IO.puts("Expected hash:  #{expected_hash}")

# Rolling update
out_byte = :binary.at(test_data, 0)   # Byte leaving: position 0
in_byte = :binary.at(test_data, window_size)  # Byte entering: position 48

IO.puts("Out byte: #{out_byte} ('#{<<out_byte>>}')")
IO.puts("In byte:  #{in_byte} ('#{<<in_byte>>}')")

rolled_hash = Chunks.update_buzhash_test(initial_hash, out_byte, in_byte)
IO.puts("Rolled hash:    #{rolled_hash}")

match = if expected_hash == rolled_hash, do: "✅ MATCH", else: "❌ MISMATCH"
IO.puts("Result: #{match}")

if expected_hash != rolled_hash do
  IO.puts("\nDebugging the mismatch:")
  IO.puts("  Initial hash: #{initial_hash} (0x#{Integer.to_string(initial_hash, 16)})")
  IO.puts("  Expected:     #{expected_hash} (0x#{Integer.to_string(expected_hash, 16)})")
  IO.puts("  Rolled:       #{rolled_hash} (0x#{Integer.to_string(rolled_hash, 16)})")
  
  # Let's manually trace the rolling hash calculation
  IO.puts("\nManual calculation:")
  
  # Get hash table values - truncated for brevity, using same table as in chunks.ex
  hash_table = [
    0x458be752, 0xc10748cc, 0xfbbcdbb8, 0x6ded5b68,
    0xb10a82b5, 0x20d75648, 0xdfc5665f, 0xa8428801,
    0x7ebf5191, 0x841135c7, 0x65cc53b3, 0x280a597c,
    0x16f60255, 0xc78cbc3e, 0x294415f5, 0xb938d494
  ]
  
  # Add more entries to get to 256 entries (using pattern)
  full_hash_table = hash_table ++ List.duplicate(0x12345678, 256 - length(hash_table))
  
  out_table_value = Enum.at(full_hash_table, out_byte)
  in_table_value = Enum.at(full_hash_table, in_byte)
  
  IO.puts("  Hash table[#{out_byte}] = #{out_table_value} (0x#{Integer.to_string(out_table_value, 16)})")
  IO.puts("  Hash table[#{in_byte}] = #{in_table_value} (0x#{Integer.to_string(in_table_value, 16)})")
  
  # Step 1: Rotate left by 1
  mask32 = 0xFFFFFFFF
  rotated_hash = bor(bsl(initial_hash, 1) |> band(mask32), bsr(initial_hash, 31))
  IO.puts("  Step 1: rol32(#{initial_hash}, 1) = #{rotated_hash} (0x#{Integer.to_string(rotated_hash, 16)})")
  
  # Step 2: Rotate out value by window size
  shift = rem(window_size, 32)
  rotated_out = bor(bsl(out_table_value, shift) |> band(mask32), bsr(out_table_value, 32 - shift))
  IO.puts("  Step 2: rol32(#{out_table_value}, #{window_size}) = #{rotated_out} (0x#{Integer.to_string(rotated_out, 16)})")
  
  # Step 3: XOR operations
  step3 = bxor(rotated_hash, rotated_out)
  IO.puts("  Step 3: #{rotated_hash} XOR #{rotated_out} = #{step3} (0x#{Integer.to_string(step3, 16)})")
  
  final_result = bxor(step3, in_table_value)
  IO.puts("  Step 4: #{step3} XOR #{in_table_value} = #{final_result} (0x#{Integer.to_string(final_result, 16)})")
  
  IO.puts("  Final rolled hash: #{final_result}")
  IO.puts("  Expected:          #{expected_hash}")
  
  if final_result == rolled_hash do
    IO.puts("  ✅ Manual calculation matches our rolling hash function")
  else
    IO.puts("  ❌ Manual calculation differs from our function: #{final_result} vs #{rolled_hash}")
  end
end
