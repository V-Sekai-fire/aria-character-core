# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaStorage.Chunks do
  @moduledoc """
  Content-defined chunking implementation compatible with desync/casync.

  This module provides a unified interface for content-defined chunking using a rolling hash 
  algorithm (buzhash) that's fully compatible with the Go implementation of desync/casync. 
  It delegates to specialized modules for different aspects of chunking functionality.

  Features:
  - Content-defined chunking using rolling hash (buzhash implementation)
  - SHA512/256 chunk identification (same as desync)
  - Configurable chunk size parameters (min, average, max)
  - Optional compression of chunks (zstd)
  - Chunk boundary detection that matches desync exactly
  - File assembly from chunks with verification

  The chunking algorithm works by:
  1. Computing a rolling hash (buzhash) over a sliding window of data
  2. Detecting chunk boundaries when hash % discriminator == discriminator - 1
  3. Creating chunks according to defined min/avg/max size constraints
  4. Calculating a SHA512/256 hash for each chunk as its unique ID

  ## Specialized Modules

  - `AriaStorage.Chunks.Core` - Main chunking algorithms and chunk creation
  - `AriaStorage.Chunks.RollingHash` - Rolling hash implementation (buzhash)
  - `AriaStorage.Chunks.Compression` - Compression and decompression utilities
  - `AriaStorage.Chunks.Assembly` - File assembly from chunks
  """

  alias AriaStorage.Index
  alias AriaStorage.Utils
  alias AriaStorage.Chunks.Core
  alias AriaStorage.Chunks.RollingHash
  alias AriaStorage.Chunks.Compression
  alias AriaStorage.Chunks.Assembly

  defstruct [
    # SHA512/256 hash of chunk content
    :id,
    # Raw chunk data
    :data,
    # Size in bytes
    :size,
    # Compressed data (zstd)
    :compressed,
    # Offset in original file
    :offset,
    # Additional checksum for verification
    :checksum
  ]

  @type t :: %__MODULE__{
          id: binary(),
          data: binary(),
          size: non_neg_integer(),
          compressed: binary(),
          offset: non_neg_integer(),
          checksum: binary()
        }

  @doc """
  Creates content-defined chunks from a file using rolling hash algorithm.

  Delegates to `AriaStorage.Chunks.Core.create_chunks/2`.

  Options:
  - `:min_size` - Minimum chunk size (default: 16KB)
  - `:avg_size` - Average chunk size (default: 64KB)
  - `:max_size` - Maximum chunk size (default: 256KB)
  - `:parallel` - Number of parallel chunking processes (default: CPU count)
  - `:compression` - Compression algorithm (:zstd, :none) (default: :zstd)
  """
  defdelegate create_chunks(file_path, opts \\ []), to: Core

  @doc """
  Creates an index file from chunks.

  The index contains metadata about chunk locations and can be used
  to reconstruct the original file.
  """
  def create_index(chunks, opts \\ []) do
    format = Keyword.get(opts, :format, :caibx)

    index_data = %Index{
      format: format,
      chunks: chunks,
      total_size: Enum.sum(Enum.map(chunks, & &1.size)),
      chunk_count: length(chunks),
      created_at: DateTime.utc_now(),
      checksum: Utils.calculate_index_checksum(chunks)
    }

    {:ok, index_data}
  end

  @doc """
  Assembles a file from chunks using an index.

  Delegates to `AriaStorage.Chunks.Assembly.assemble_file/4`.

  Options:
  - `:seeds` - List of seed files for efficient reconstruction
  - `:verify` - Verify chunk checksums during assembly (default: true)
  - `:reflink` - Use reflinks/CoW when possible (default: true)
  """
  defdelegate assemble_file(chunks, index, output_path, opts \\ []), to: Assembly

  @doc """
  Calculates SHA512/256 hash for chunk identification.
  """
  def calculate_chunk_id(data) when is_binary(data) do
    :crypto.hash(:sha512, data)
    # Use first 256 bits for SHA512/256
    |> binary_part(0, 32)
  end

  @doc """
  Compresses chunk data using the specified compression algorithm.

  Delegates to `AriaStorage.Chunks.Compression.compress_chunk/2`.
  """
  defdelegate compress_chunk(data, algorithm \\ :zstd), to: Compression

  @doc """
  Decompresses chunk data that was previously compressed with compress_chunk/2.

  Delegates to `AriaStorage.Chunks.Compression.decompress_chunk/2`.
  """
  defdelegate decompress_chunk(compressed_data, algorithm \\ :zstd), to: Compression

  # Delegated functions for rolling hash operations
  @doc """
  Calculates the discriminator value from the average chunk size.

  Delegates to `AriaStorage.Chunks.RollingHash.discriminator_from_avg/1`.
  """
  defdelegate discriminator_from_avg(avg), to: RollingHash

  @doc """
  Finds all chunks in a binary data using the rolling hash algorithm.

  Delegates to `AriaStorage.Chunks.Core.find_all_chunks_in_data/5`.
  """
  defdelegate find_all_chunks_in_data(data, min_size, max_size, discriminator, compression), to: Core

  @doc """
  Test function to expose buzhash calculation for debugging.

  Delegates to `AriaStorage.Chunks.RollingHash.calculate_buzhash/1`.
  """
  defdelegate calculate_buzhash_test(window_data), to: RollingHash, as: :calculate_buzhash

  @doc """
  Test function to expose buzhash update for debugging.

  Delegates to `AriaStorage.Chunks.RollingHash.update_buzhash/3`.
  """
  defdelegate update_buzhash_test(hash, out_byte, in_byte), to: RollingHash, as: :update_buzhash
end
