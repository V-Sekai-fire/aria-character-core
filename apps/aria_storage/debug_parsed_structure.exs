# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

# Debug script to examine parsed data structure

defmodule DebugParser do
  def find_first_difference(binary1, binary2, pos) do
    case {binary1, binary2} do
      {<<b1, rest1::binary>>, <<b2, rest2::binary>>} ->
        if b1 == b2 do
          find_first_difference(rest1, rest2, pos + 1)
        else
          pos
        end
      _ ->
        pos
    end
  end
end

alias AriaStorage.Parsers.CasyncFormat

testdata_path = Path.join([__DIR__, "test", "support", "testdata"])
blob1_path = Path.join(testdata_path, "blob1.caibx")

case File.read(blob1_path) do
  {:ok, binary_data} ->
    case CasyncFormat.parse_index(binary_data) do
      {:ok, parsed} ->
        IO.puts("Parsed structure:")
        IO.inspect(parsed, pretty: true, limit: :infinity)

        IO.puts("\nChunks structure:")
        IO.inspect(parsed.chunks |> Enum.take(2), pretty: true, limit: :infinity)

        IO.puts("\nHeader structure:")
        IO.inspect(parsed.header, pretty: true, limit: :infinity)

        # Test encoding
        case CasyncFormat.encode_index(parsed) do
          {:ok, encoded_data} ->
            IO.puts("\nOriginal size: #{byte_size(binary_data)}")
            IO.puts("Encoded size: #{byte_size(encoded_data)}")

            # Find first difference
            diff_pos = DebugParser.find_first_difference(binary_data, encoded_data, 0)
            IO.puts("First difference at byte: #{diff_pos}")

            if diff_pos < 100 do
              IO.puts("\nOriginal bytes around position #{diff_pos}:")
              IO.inspect(binary_slice(binary_data, max(0, diff_pos - 5), 10))
              IO.puts("Encoded bytes around position #{diff_pos}:")
              IO.inspect(binary_slice(encoded_data, max(0, diff_pos - 5), 10))
            end

          {:error, reason} ->
            IO.puts("Failed to encode: #{reason}")
        end

      {:error, reason} ->
        IO.puts("Failed to parse: #{reason}")
    end

  {:error, reason} ->
    IO.puts("Failed to read file: #{reason}")
end
