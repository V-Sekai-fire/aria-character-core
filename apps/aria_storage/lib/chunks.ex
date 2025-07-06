# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaStorage.Chunks do
  @moduledoc "Content-defined chunking implementation compatible with desync/casync.\n\nThis module provides a unified interface for content-defined chunking using a rolling hash \nalgorithm (buzhash) that's fully compatible with the Go implementation of desync/casync. \nIt delegates to specialized modules for different aspects of chunking functionality.\n\nFeatures:\n- Content-defined chunking using rolling hash (buzhash implementation)\n- SHA512/256 chunk identification (same as desync)\n- Configurable chunk size parameters (min, average, max)\n- Optional compression of chunks (zstd)\n- Chunk boundary detection that matches desync exactly\n- File assembly from chunks with verification\n\nThe chunking algorithm works by:\n1. Computing a rolling hash (buzhash) over a sliding window of data\n2. Detecting chunk boundaries when hash % discriminator == discriminator - 1\n3. Creating chunks according to defined min/avg/max size constraints\n4. Calculating a SHA512/256 hash for each chunk as its unique ID\n\n## Specialized Modules\n\n- `AriaStorage.Chunks.Core` - Main chunking algorithms and chunk creation\n- `AriaStorage.Chunks.RollingHash` - Rolling hash implementation (buzhash)\n- `AriaStorage.Chunks.Compression` - Compression and decompression utilities\n- `AriaStorage.Chunks.Assembly` - File assembly from chunks\n"
  alias AriaStorage.Index
  alias AriaStorage.Utils
  alias AriaStorage.Chunks.Core
  alias AriaStorage.Chunks.RollingHash
  alias AriaStorage.Chunks.Compression
  alias AriaStorage.Chunks.Assembly
  defstruct [:id, :data, :size, :compressed, :offset, :checksum]

  @type t :: %__MODULE__{
          id: binary(),
          data: binary(),
          size: non_neg_integer(),
          compressed: binary(),
          offset: non_neg_integer(),
          checksum: binary()
        }
  @doc "Creates content-defined chunks from a file using rolling hash algorithm.\n\nDelegates to `AriaStorage.Chunks.Core.create_chunks/2`.\n\nOptions:\n- `:min_size` - Minimum chunk size (default: 16KB)\n- `:avg_size` - Average chunk size (default: 64KB)\n- `:max_size` - Maximum chunk size (default: 256KB)\n- `:parallel` - Number of parallel chunking processes (default: CPU count)\n- `:compression` - Compression algorithm (:zstd, :none) (default: :zstd)\n"
  defdelegate create_chunks(file_path, opts \\ []), to: Core

  @doc "Creates an index file from chunks.\n\nThe index contains metadata about chunk locations and can be used\nto reconstruct the original file.\n"
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

  @doc "Assembles a file from chunks using an index.\n\nDelegates to `AriaStorage.Chunks.Assembly.assemble_file/4`.\n\nOptions:\n- `:seeds` - List of seed files for efficient reconstruction\n- `:verify` - Verify chunk checksums during assembly (default: true)\n- `:reflink` - Use reflinks/CoW when possible (default: true)\n"
  defdelegate assemble_file(chunks, index, output_path, opts \\ []), to: Assembly
  @doc "Calculates SHA512/256 hash for chunk identification.\n"
  def calculate_chunk_id(data) when is_binary(data) do
    :crypto.hash(:sha512, data) |> binary_part(0, 32)
  end

  @doc "Compresses chunk data using the specified compression algorithm.\n\nDelegates to `AriaStorage.Chunks.Compression.compress_chunk/2`.\n"
  defdelegate compress_chunk(data, algorithm \\ :zstd), to: Compression

  @doc "Decompresses chunk data that was previously compressed with compress_chunk/2.\n\nDelegates to `AriaStorage.Chunks.Compression.decompress_chunk/2`.\n"
  defdelegate decompress_chunk(compressed_data, algorithm \\ :zstd), to: Compression

  @doc "Calculates the discriminator value from the average chunk size.\n\nDelegates to `AriaStorage.Chunks.RollingHash.discriminator_from_avg/1`.\n"
  defdelegate discriminator_from_avg(avg), to: RollingHash

  @doc "Finds all chunks in a binary data using the rolling hash algorithm.\n\nDelegates to `AriaStorage.Chunks.Core.find_all_chunks_in_data/5`.\n"
  defdelegate find_all_chunks_in_data(data, min_size, max_size, discriminator, compression),
    to: Core

  @doc "Test function to expose buzhash calculation for debugging.\n\nDelegates to `AriaStorage.Chunks.RollingHash.calculate_buzhash/1`.\n"
  defdelegate calculate_buzhash_test(window_data), to: RollingHash, as: :calculate_buzhash

  @doc "Test function to expose buzhash update for debugging.\n\nDelegates to `AriaStorage.Chunks.RollingHash.update_buzhash/3`.\n"
  defdelegate update_buzhash_test(hash, out_byte, in_byte), to: RollingHash, as: :update_buzhash
end
