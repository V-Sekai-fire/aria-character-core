#!/usr/bin/env elixir

# Script to verify all chunk hashes against the expected values from desync/casync
# This compares our implementation with the expected hash values from the desync tool

# Load and start the Aria application to have access to all modules
Mix.start()
Application.put_env(:elixir, :ansi_enabled, true)
Application.ensure_all_started(:aria_storage)

# Import the necessary modules
alias AriaStorage.Chunks
alias AriaStorage.Parsers.CasyncFormat

defmodule ChunkHashVerification do
  @input_file "/Users/setup/Developer/aria-character-core/thirdparty/desync/testdata/chunker.input"
  @index_file "/Users/setup/Developer/aria-character-core/thirdparty/desync/testdata/chunker.index"

  def run do
    IO.puts("=== CHUNKING HASH VERIFICATION ===")
    IO.puts("Input file: #{@input_file}")
    IO.puts("Index file: #{@index_file}")

    # Read the desync index file to get expected chunks
    {:ok, index_data} = File.read(@index_file)
    {:ok, expected_index} = AriaStorage.Parsers.CasyncFormat.parse_index(index_data)
    expected_chunks = expected_index.chunks

    # Generate chunks with our implementation
    {:ok, file_data} = File.read(@input_file)

    # Use our chunking algorithm
    min_size = 16 * 1024   # 16KB
    avg_size = 64 * 1024   # 64KB
    max_size = 256 * 1024  # 256KB
    discriminator = AriaStorage.Chunks.discriminator_from_avg(avg_size)

    actual_chunks = AriaStorage.Chunks.find_all_chunks_in_data(
      file_data, min_size, max_size, discriminator, :none
    )

    IO.puts("\n=== RESULTS ===")
    IO.puts("Expected chunks: #{length(expected_chunks)}")
    IO.puts("Actual chunks: #{length(actual_chunks)}")

    # Compare chunk counts
    if length(expected_chunks) == length(actual_chunks) do
      IO.puts("\n✅ CHUNK COUNT MATCHES: #{length(actual_chunks)}")
    else
      IO.puts("\n❌ CHUNK COUNT MISMATCH: Expected #{length(expected_chunks)}, got #{length(actual_chunks)}")
    end

    # Compare each chunk ID and size
    IO.puts("\n=== CHUNK COMPARISON ===")

    result = expected_chunks
    |> Enum.zip(actual_chunks)
    |> Enum.with_index()
    |> Enum.map(fn {{expected, actual}, idx} ->
      expected_id_hex = Base.encode16(expected.id, case: :lower)
      actual_id_hex = Base.encode16(actual.id, case: :lower)

      id_match = expected.id == actual.id
      size_match = expected.size == actual.size
      offset_match = expected.offset == actual.offset

      result = if id_match and size_match and offset_match, do: "✅", else: "❌"

      # Print detailed info for each chunk
      IO.puts("Chunk #{idx + 1}:")
      IO.puts("  Offset: #{expected.offset} #{if offset_match, do: "✅", else: "❌ (actual: #{actual.offset})"}")
      IO.puts("  Size: #{expected.size} #{if size_match, do: "✅", else: "❌ (actual: #{actual.size})"}")
      IO.puts("  ID (expected): #{String.slice(expected_id_hex, 0, 16)}...")
      IO.puts("  ID (actual):   #{String.slice(actual_id_hex, 0, 16)}...")
      IO.puts("  Match: #{result}")
      IO.puts("")

      {id_match, size_match, offset_match}
    end)

    # Calculate overall success rate
    {id_matches, size_matches, offset_matches} = result
    |> Enum.reduce({0, 0, 0}, fn {id, size, offset}, {id_acc, size_acc, offset_acc} ->
      {
        id_acc + (if id, do: 1, else: 0),
        size_acc + (if size, do: 1, else: 0),
        offset_acc + (if offset, do: 1, else: 0)
      }
    end)

    total = length(result)

    IO.puts("\n=== SUMMARY ===")
    IO.puts("ID matches: #{id_matches}/#{total} (#{round(id_matches/total*100)}%)")
    IO.puts("Size matches: #{size_matches}/#{total} (#{round(size_matches/total*100)}%)")
    IO.puts("Offset matches: #{offset_matches}/#{total} (#{round(offset_matches/total*100)}%)")

    if id_matches == total and size_matches == total and offset_matches == total do
      IO.puts("\n✅ VERIFICATION SUCCESS: All chunks match exactly!")
    else
      IO.puts("\n❌ VERIFICATION FAILED: Some chunks don't match")
    end
  end
end

# Run the verification
ChunkHashVerification.run()
