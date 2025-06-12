#!/usr/bin/env elixir

Mix.install([
  {:aria_storage, path: "apps/aria_storage"}
])

alias AriaStorage.Parsers.CasyncFormat

# Test data paths
index_path = "apps/aria_storage/test/support/testdata/chunker.index"

# Load and parse reference data to extract the actual parameters
case File.read(index_path) do
  {:ok, expected_index} ->
    case CasyncFormat.parse_index(expected_index) do
      {:ok, index_info} ->

        IO.puts("=== EXTRACTED INDEX INFORMATION ===")
        IO.puts("Format: #{index_info.format}")
        IO.puts("Feature flags: #{index_info.feature_flags}")
        IO.puts("Chunk size min: #{index_info.chunk_size_min}")
        IO.puts("Chunk size avg: #{index_info.chunk_size_avg}")
        IO.puts("Chunk size max: #{index_info.chunk_size_max}")
        IO.puts("Number of expected chunks: #{length(index_info.chunks)}")
        IO.puts("")

        # Calculate discriminator using the exact parameters from the index file
        discriminator = AriaStorage.Chunks.discriminator_from_avg(index_info.chunk_size_avg)
        IO.puts("Calculated discriminator: #{discriminator}")
        
      {:error, reason} ->
        IO.puts("Failed to parse index: #{inspect(reason)}")
    end
  {:error, reason} ->
    IO.puts("Failed to read index file: #{inspect(reason)}")
end
