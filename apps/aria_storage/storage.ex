# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule MyModule do
  # Helper function to create chunks from binary data
  defp create_chunks_from_binary(data, chunk_size, compress) do
    min_size = div(chunk_size, 4)
    max_size = chunk_size * 4
    discriminator = Chunks.discriminator_from_avg(chunk_size)
    compression = if compress, do: :zstd, else: :none
    
    try do
      chunks = Chunks.find_all_chunks_in_data(data, min_size, max_size, discriminator, compression)
      {:ok, chunks}
    rescue
      error -> {:error, error}
    end
  end
end