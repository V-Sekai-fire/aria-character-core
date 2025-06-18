# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaStorage.ChunksTest do
  use ExUnit.Case
  alias AriaStorage.Chunks

  @moduledoc """
  Test suite for AriaStorage.Chunks module, focusing on compatibility with desync/casync.
  """

  # Not using tags to ensure test always runs
  # @tag :integration

  @input_file_path Path.join([__DIR__, "..", "..", "..", "..", "thirdparty", "desync", "testdata", "chunker.input"])

  @tag :integration
  test "chunking produces the same boundaries as desync/casync" do
    # Read the test input file
    {:ok, input_data} = File.read(@input_file_path)
    assert byte_size(input_data) == 1_048_576  # 1MB test file

    # Use default parameters matching desync
    min_size = 16 * 1024      # 16KB
    avg_size = 64 * 1024      # 64KB
    max_size = 256 * 1024     # 256KB

    # Calculate discriminator using the same formula as desync
    discriminator = Chunks.discriminator_from_avg(avg_size)

    # Generate chunks using our implementation
    chunks = Chunks.find_all_chunks_in_data(input_data, min_size, max_size, discriminator, :none)

    # Expected results from desync
    expected_chunk_count = 20
    expected_first_chunk_size = 81590
    expected_first_chunk_id_prefix = "5e919e60"

    # Verifications
    assert length(chunks) == expected_chunk_count,
      "Expected #{expected_chunk_count} chunks, got #{length(chunks)}"

    first_chunk = List.first(chunks)
    assert first_chunk.size == expected_first_chunk_size,
      "First chunk size mismatch: expected #{expected_first_chunk_size}, got #{first_chunk.size}"

    # Convert binary ID to hex string and check prefix
    first_chunk_id_hex = Base.encode16(first_chunk.id, case: :lower)
    assert String.starts_with?(first_chunk_id_hex, expected_first_chunk_id_prefix),
      "First chunk ID prefix mismatch: expected #{expected_first_chunk_id_prefix}, got #{String.slice(first_chunk_id_hex, 0, 8)}"

    # Check chunk contiguity (no gaps or overlaps)
    check_chunks_contiguity(chunks, byte_size(input_data))

    # Check that chunks contain all the content
    total_chunk_size = Enum.reduce(chunks, 0, fn chunk, acc -> acc + chunk.size end)
    assert total_chunk_size == byte_size(input_data),
      "Total chunk size #{total_chunk_size} doesn't match input data size #{byte_size(input_data)}"
  end

  defp check_chunks_contiguity(chunks, expected_total_size) do
    # Check that all chunks are contiguous and cover the entire input
    chunks_with_index = Enum.with_index(chunks)

    Enum.each(chunks_with_index, fn {chunk, index} ->
      if index > 0 do
        previous_chunk = Enum.at(chunks, index - 1)
        expected_offset = previous_chunk.offset + previous_chunk.size

        assert chunk.offset == expected_offset,
          "Gap or overlap detected between chunks #{index-1} and #{index}: " <>
          "Expected offset #{expected_offset}, got #{chunk.offset}"
      end
    end)

    # Check last chunk reaches the end
    last_chunk = List.last(chunks)
    assert last_chunk.offset + last_chunk.size == expected_total_size,
      "Last chunk doesn't reach the end of input data"
  end
end
