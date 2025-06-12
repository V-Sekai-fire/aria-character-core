#!/usr/bin/env elixir

# Minimal rolling hash debug

Mix.install([
  {:aria_storage, path: "apps/aria_storage"}
])

alias AriaStorage.Chunks

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
  
  # Get hash table values
  hash_table = [
    0x458be752, 0xc10748cc, 0xfbbcdbb8, 0x6ded5b68,
    0xb10a82b5, 0x20d75648, 0xdfc5665f, 0xa8428801,
    0x7ebf5191, 0x841135c7, 0x65cc53b3, 0x280a597c,
    0x16f60255, 0xc78cbc3e, 0x294415f5, 0xb938d494,
    0x4c548b78, 0x5a2d7f79, 0x5e1b4838, 0x6f4da44c,
    0x7b527a85, 0x4ba5f4d4, 0x6e3d3e5b, 0x49b8c5f0,
    0x2b1b6dbc, 0x3e70ae39, 0x74cec0b4, 0x5f1fa00e,
    0x22d8b5e3, 0x7b8e14b5, 0x5e96cdbd, 0x16b5b7f7,
    0x3c0d5710, 0x4ae7c84b, 0x7f7a8b8e, 0x1b66dfb1,
    0x1b98e6ab, 0x1b518e55, 0x0e7dad40, 0x748ba4b8,
    0x3d70c97d, 0x68aa97e8, 0x22c4c7c4, 0x0c4f05b8,
    0x5bcb9e84, 0x419f3d56, 0x0ad6f3b9, 0x60fe6b16,
    0x6ec7a51a, 0x4b8c64f5, 0x32c64814, 0x5e5c6b3d,
    0x6f5e6cb9, 0x1b6fa85e, 0x334ca2f6, 0x37d8c8ce,
    0x72fd2aeb, 0x3e90f4d0, 0x7329d0f2, 0x5d2ad45b,
    0x3d58cbbf, 0x7f1ec5d4, 0x0d4d4b7e, 0x14edf20e,
    0x41ef9e8d, 0x5b2a5b8f, 0x6dd1e4e5, 0x7c12c0e2,
    0x5d7b8b11, 0x42e0b3ab, 0x53b1b926, 0x51e8ac76,
    0x39e64b5e, 0x5b94d17e, 0x298d6ad3, 0x1e3e1a52,
    0x5d9a35f5, 0x3f14a8c7, 0x14ad9db4, 0x1c0ad39c,
    0x38ad1bb1, 0x2b5d8b0f, 0x7b7738a4, 0x4bdf7b27,
    0x1d9d36ac, 0x4c43bb1f, 0x68f3a86d, 0x6e8a8c64,
    0x2e1a8c1b, 0x0f70e2fb, 0x4c5bb8ec, 0x6a24c5e9,
    0x7e3bd6cb, 0x0d9c3b15, 0x41c6d83e, 0x760c2d8a,
    0x3e1cd2e8, 0x3b0a08ba, 0x15b6c1e7, 0x0db6b8dd,
    0x2dac8adc, 0x3ca8c0f9, 0x23e8bb43, 0x73b4d18e,
    0x6b2c9f5b, 0x22ec3ea1, 0x09d11adb, 0x0f7b4d08,
    0x6d11d6b7, 0x23f31bb5, 0x79da8f62, 0x2c1ba8b7,
    0x23c4bb11, 0x6dfbdaa5, 0x43e5b47a, 0x58a6ecfc,
    0x18e8d3e3, 0x4dc5d9e8, 0x4a9e6b61, 0x7f9a0e4c,
    0x0e4e3fe8, 0x22c2b0e2, 0x73ec4d57, 0x6e2b4b9c,
    0x3e1b2e58, 0x4e8e33cb, 0x23ec9374, 0x26e4c3e1,
    0x3d38eb24, 0x1e8a8cc9, 0x5c5c4b9c, 0x1e9a5fe8,
    0x3c6c9f37, 0x2dd29f8b, 0x5c1bb5a4, 0x7f4b2b49,
    0x6c1b3b8b, 0x1e8c23b4, 0x5c38eb23, 0x6e8c1b49,
    0x1e8a6fe4, 0x6c5c9b37, 0x2dd2dfbb, 0x5c1bb3e4,
    0x7f4b2d09, 0x6c1b3d4b, 0x1e8c2374, 0x5c38ed83,
    0x6e8c1d09, 0x1e8a6de4, 0x6c5c9d97, 0x2dd2dd7b,
    0x5c1bb1a4, 0x7f4b2fc9, 0x6c1b3f0b, 0x1e8c2534,
    0x5c38ef43, 0x6e8c1fc9, 0x1e8a6fa4, 0x6c5c9f57,
    0x2dd2df3b, 0x5c1bb364, 0x7f4b3189, 0x6c1b30cb,
    0x1e8c26f4, 0x5c38f103, 0x6e8c2189, 0x1e8a7164,
    0x6c5ca117, 0x2dd2e0fb, 0x5c1bb524, 0x7f4b3349,
    0x6c1b328b, 0x1e8c28b4, 0x5c38f2c3, 0x6e8c2349,
    0x1e8a7324, 0x6c5ca2d7, 0x2dd2e2bb, 0x5c1bb6e4,
    0x7f4b3509, 0x6c1b344b, 0x1e8c2a74, 0x5c38f483,
    0x6e8c2509, 0x1e8a74e4, 0x6c5ca497, 0x2dd2e47b,
    0x5c1bb8a4, 0x7f4b36c9, 0x6c1b360b, 0x1e8c2c34,
    0x5c38f643, 0x6e8c26c9, 0x1e8a76a4, 0x6c5ca657,
    0x2dd2e63b, 0x5c1bba64, 0x7f4b3889, 0x6c1b37cb,
    0x1e8c2df4, 0x5c38f803, 0x6e8c2889, 0x1e8a7864,
    0x6c5ca817, 0x2dd2e7fb, 0x5c1bbc24, 0x7f4b3a49,
    0x6c1b398b, 0x1e8c2fb4, 0x5c38f9c3, 0x6e8c2a49,
    0x1e8a7a24, 0x6c5ca9d7, 0x2dd2e9bb, 0x5c1bbde4,
    0x7f4b3c09, 0x6c1b3b4b, 0x1e8c3174, 0x5c38fb83,
    0x6e8c2c09, 0x1e8a7be4, 0x6c5cab97, 0x2dd2eb7b,
    0x5c1bbfa4, 0x7f4b3dc9, 0x6c1b3d0b, 0x1e8c3334,
    0x5c38fd43, 0x6e8c2dc9, 0x1e8a7da4, 0x6c5cad57,
    0x2dd2ed3b, 0x5c1bc164, 0x7f4b3f89, 0x6c1b3ecb,
    0x1e8c34f4, 0x5c38ff03, 0x6e8c2f89, 0x1e8a7f64,
    0x6c5caf17, 0x2dd2eefb, 0x5c1bc324, 0x7f4b4149,
    0x6c1b408b, 0x1e8c36b4, 0x5c3900c3, 0x6e8c3149,
    0x1e8a8124, 0x6c5cb0d7, 0x2dd2f0bb, 0x5c1bc4e4
  ]
  
  out_table_value = Enum.at(hash_table, out_byte)
  in_table_value = Enum.at(hash_table, in_byte)
  
  IO.puts("  Hash table[#{out_byte}] = #{out_table_value} (0x#{Integer.to_string(out_table_value, 16)})")
  IO.puts("  Hash table[#{in_byte}] = #{in_table_value} (0x#{Integer.to_string(in_table_value, 16)})")
  
  import Bitwise
  
  # Step 1: Rotate left by 1
  rotated_hash = bor(bsl(initial_hash, 1) &&& 0xFFFFFFFF, bsr(initial_hash, 31))
  IO.puts("  Step 1: rol32(#{initial_hash}, 1) = #{rotated_hash} (0x#{Integer.to_string(rotated_hash, 16)})")
  
  # Step 2: Rotate out value by window size
  shift = rem(window_size, 32)
  rotated_out = bor(bsl(out_table_value, shift) &&& 0xFFFFFFFF, bsr(out_table_value, 32 - shift))
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
