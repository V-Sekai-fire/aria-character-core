# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaStorage do
  @moduledoc """
  External API for AriaStorage - Content-defined chunking and storage system.

  This module provides the public interface for AriaStorage functionality, including:
  - Content-defined chunking compatible with desync/casync
  - Multiple storage backends (local, Waffle, S3)
  - Index file management for efficient file reconstruction
  - Chunk compression and decompression
  - File assembly from chunks
  - Storage backend abstraction

  All cross-app communication should use this external API rather than importing
  internal AriaStorage modules directly.

  ## Content-Defined Chunking

      # Create chunks from a file
      {:ok, chunks} = AriaStorage.create_chunks("large_file.bin")

      # Create an index for the chunks
      {:ok, index} = AriaStorage.create_index(chunks)

      # Save index to file
      {:ok, index_path} = AriaStorage.save_index(index, "large_file.bin.caibx")

  ## Storage Operations

      # Store file with Waffle backend
      {:ok, result} = AriaStorage.store_file("document.pdf", backend: :local)

      # Retrieve file
      {:ok, data} = AriaStorage.get_file(file_ref)

      # List stored files
      {:ok, files} = AriaStorage.list_files(limit: 50)

  ## Chunk Store Operations

      # Store individual chunks
      {:ok, metadata} = AriaStorage.store_chunk(chunk_store, chunk)

      # Retrieve chunks
      {:ok, chunk} = AriaStorage.get_chunk(chunk_store, chunk_id)

      # Check chunk existence
      exists = AriaStorage.chunk_exists?(chunk_store, chunk_id)

  ## File Assembly

      # Assemble file from chunks and index
      {:ok, output_path} = AriaStorage.assemble_file(chunks, index, "reconstructed_file.bin")

  ## Storage Configuration

      # Configure Waffle storage
      {:ok, :configured} = AriaStorage.configure_storage(%{backend: :s3, bucket: "my-bucket"})

      # Test storage configuration
      {:ok, :test_passed} = AriaStorage.test_storage(:s3)
  """

  # Storage Operations API
  defdelegate store_file(file_path, opts \\ []), to: AriaStorage.Storage, as: :store_file_with_waffle
  defdelegate get_file(file_ref, opts \\ []), to: AriaStorage.Storage, as: :get_file_with_waffle
  defdelegate list_files(opts \\ []), to: AriaStorage.Storage, as: :list_waffle_files
  defdelegate configure_storage(config), to: AriaStorage.Storage, as: :configure_waffle_storage
  defdelegate test_storage(backend, opts \\ []), to: AriaStorage.Storage, as: :test_waffle_storage
  defdelegate get_storage_config(), to: AriaStorage.Storage, as: :get_waffle_config
  defdelegate migrate_storage(target_backend, opts \\ []), to: AriaStorage.Storage, as: :migrate_to_waffle

  # Content-Defined Chunking API
  defdelegate create_chunks(file_path, opts \\ []), to: AriaStorage.Chunks
  defdelegate create_index(chunks, opts \\ []), to: AriaStorage.Chunks
  defdelegate assemble_file(chunks, index, output_path, opts \\ []), to: AriaStorage.Chunks
  defdelegate calculate_chunk_id(data), to: AriaStorage.Chunks
  defdelegate compress_chunk(data, algorithm \\ :zstd), to: AriaStorage.Chunks
  defdelegate decompress_chunk(compressed_data, algorithm \\ :zstd), to: AriaStorage.Chunks
  defdelegate discriminator_from_avg(avg), to: AriaStorage.Chunks
  defdelegate find_chunks_in_data(data, min_size, max_size, discriminator, compression), to: AriaStorage.Chunks, as: :find_all_chunks_in_data

  # Index Management API
  defdelegate create_index_from_chunks(chunks, opts \\ []), to: AriaStorage.Index, as: :create_index
  defdelegate serialize_index(index), to: AriaStorage.Index, as: :serialize
  defdelegate deserialize_index(binary_data), to: AriaStorage.Index, as: :deserialize
  defdelegate load_index(file_path), to: AriaStorage.Index, as: :load_from_file
  defdelegate save_index(index, file_path), to: AriaStorage.Index, as: :save_to_file
  defdelegate validate_index(index), to: AriaStorage.Index, as: :validate
  defdelegate create_index_filename(original_file, format), to: AriaStorage.Index, as: :create_filename
  defdelegate get_chunk_by_id(index, chunk_id), to: AriaStorage.Index
  defdelegate get_chunks_in_range(index, start_offset, end_offset), to: AriaStorage.Index
  defdelegate total_compressed_size(index), to: AriaStorage.Index
  defdelegate compression_ratio(index), to: AriaStorage.Index

  # Chunk Store API
  defdelegate store_chunk(store, chunk), to: AriaStorage.ChunkStore
  defdelegate get_chunk(store, chunk_id), to: AriaStorage.ChunkStore
  defdelegate chunk_exists?(store, chunk_id), to: AriaStorage.ChunkStore
  defdelegate delete_chunk(store, chunk_id), to: AriaStorage.ChunkStore
  defdelegate list_chunks(store, opts \\ []), to: AriaStorage.ChunkStore
  defdelegate get_store_stats(store), to: AriaStorage.ChunkStore, as: :get_stats

  # File Schema API
  defdelegate file_changeset(file, attrs), to: AriaStorage.File, as: :changeset
  defdelegate store_changeset(file, index_ref), to: AriaStorage.File
  defdelegate fail_changeset(file, reason), to: AriaStorage.File

  @doc """
  Processes a file through the complete chunking and storage pipeline.

  This convenience function combines chunking, index creation, and storage
  in a single operation.

  ## Parameters

  - `file_path`: Path to the file to process
  - `options`: Configuration options
    - `:backend`: Storage backend (:local, :s3, etc.)
    - `:compression`: Compression algorithm (:zstd, :none)
    - `:chunk_options`: Options for chunking (min_size, avg_size, max_size)
    - `:index_format`: Index format (:caibx, :caidx)

  ## Examples

      iex> result = AriaStorage.process_file("large_document.pdf",
      ...>   backend: :s3,
      ...>   compression: :zstd,
      ...>   chunk_options: [avg_size: 64 * 1024]
      ...> )
      iex> {:ok, %{chunks: chunks, index: index, storage_result: storage_result}} = result
  """
  def process_file(file_path, options \\ []) do
    backend = Keyword.get(options, :backend, :local)
    compression = Keyword.get(options, :compression, :zstd)
    chunk_options = Keyword.get(options, :chunk_options, [])
    index_format = Keyword.get(options, :index_format, :caibx)

    with {:ok, chunks} <- create_chunks(file_path, Keyword.put(chunk_options, :compression, compression)),
         {:ok, index} <- create_index_from_chunks(chunks, format: index_format),
         {:ok, storage_result} <- store_file(file_path, backend: backend) do
      {:ok, %{
        chunks: chunks,
        index: index,
        storage_result: storage_result,
        file_path: file_path
      }}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Reconstructs a file from stored chunks and index.

  This convenience function handles the complete file reconstruction process
  from chunks and index data.

  ## Parameters

  - `index_path`: Path to the index file
  - `output_path`: Where to write the reconstructed file
  - `options`: Configuration options
    - `:chunk_store`: Chunk store instance for retrieving chunks
    - `:verify`: Verify chunk checksums during assembly (default: true)
    - `:seeds`: List of seed files for efficient reconstruction

  ## Examples

      iex> result = AriaStorage.reconstruct_file("document.pdf.caibx", "reconstructed.pdf",
      ...>   chunk_store: my_store,
      ...>   verify: true
      ...> )
      iex> {:ok, "reconstructed.pdf"} = result
  """
  def reconstruct_file(index_path, output_path, options \\ []) do
    chunk_store = Keyword.get(options, :chunk_store)
    verify = Keyword.get(options, :verify, true)
    seeds = Keyword.get(options, :seeds, [])

    with {:ok, index} <- load_index(index_path),
         {:ok, chunks} <- retrieve_chunks_for_index(index, chunk_store),
         {:ok, ^output_path} <- assemble_file(chunks, index, output_path, verify: verify, seeds: seeds) do
      {:ok, output_path}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Analyzes a file and returns chunking statistics.

  This function provides insights into how a file would be chunked
  without actually performing the chunking operation.

  ## Parameters

  - `file_path`: Path to the file to analyze
  - `options`: Chunking options for analysis

  ## Examples

      iex> stats = AriaStorage.analyze_file("large_file.bin")
      iex> {:ok, %{estimated_chunks: 42, estimated_compression: 0.65}} = stats
  """
  def analyze_file(file_path, options \\ []) do
    case File.stat(file_path) do
      {:ok, %{size: file_size}} ->
        avg_size = Keyword.get(options, :avg_size, 64 * 1024)
        min_size = Keyword.get(options, :min_size, 16 * 1024)
        max_size = Keyword.get(options, :max_size, 256 * 1024)

        estimated_chunks = max(1, div(file_size, avg_size))

        # Rough compression estimate based on file type
        estimated_compression = case Path.extname(file_path) do
          ext when ext in [".jpg", ".jpeg", ".png", ".gif", ".mp4", ".zip", ".gz"] -> 0.95
          ext when ext in [".pdf", ".doc", ".docx"] -> 0.70
          ext when ext in [".txt", ".csv", ".json", ".xml", ".html"] -> 0.30
          _ -> 0.65
        end

        {:ok, %{
          file_size: file_size,
          estimated_chunks: estimated_chunks,
          estimated_compression: estimated_compression,
          avg_chunk_size: avg_size,
          min_chunk_size: min_size,
          max_chunk_size: max_size
        }}

      {:error, reason} ->
        {:error, {:file_stat_failed, reason}}
    end
  end

  @doc """
  Validates the integrity of stored chunks against an index.

  This function checks that all chunks referenced in an index are available
  and have correct checksums.

  ## Parameters

  - `index`: Index structure or path to index file
  - `chunk_store`: Chunk store instance to check against
  - `options`: Validation options

  ## Examples

      iex> result = AriaStorage.validate_chunks(index, chunk_store)
      iex> {:ok, %{valid: 42, invalid: 0, missing: 0}} = result
  """
  def validate_chunks(index, chunk_store, options \\ []) do
    parallel = Keyword.get(options, :parallel, System.schedulers_online())

    index_struct = case index do
      %AriaStorage.Index{} = idx -> idx
      path when is_binary(path) ->
        case load_index(path) do
          {:ok, idx} -> idx
          {:error, reason} -> return {:error, reason}
        end
    end

    chunks = index_struct.chunks

    # Validate chunks in parallel
    chunk_results = chunks
    |> Enum.chunk_every(max(1, div(length(chunks), parallel)))
    |> Task.async_stream(fn chunk_batch ->
      Enum.map(chunk_batch, fn chunk ->
        case get_chunk(chunk_store, chunk.id) do
          {:ok, stored_chunk} ->
            if stored_chunk.checksum == chunk.checksum do
              {:valid, chunk.id}
            else
              {:invalid, chunk.id}
            end
          {:error, _} ->
            {:missing, chunk.id}
        end
      end)
    end, timeout: 30_000)
    |> Enum.flat_map(fn {:ok, results} -> results end)

    # Aggregate results
    summary = Enum.reduce(chunk_results, %{valid: 0, invalid: 0, missing: 0}, fn
      {:valid, _}, acc -> Map.update!(acc, :valid, &(&1 + 1))
      {:invalid, _}, acc -> Map.update!(acc, :invalid, &(&1 + 1))
      {:missing, _}, acc -> Map.update!(acc, :missing, &(&1 + 1))
    end)

    {:ok, summary}
  end

  @doc """
  Creates a complete storage setup with chunking and indexing.

  This convenience function sets up a complete storage system with
  the specified configuration.

  ## Parameters

  - `options`: Configuration options
    - `:backend`: Storage backend configuration
    - `:chunk_options`: Default chunking options
    - `:compression`: Default compression algorithm

  ## Examples

      iex> setup = AriaStorage.setup_storage(
      ...>   backend: %{type: :s3, bucket: "my-chunks"},
      ...>   chunk_options: [avg_size: 128 * 1024],
      ...>   compression: :zstd
      ...> )
      iex> {:ok, storage_config} = setup
  """
  def setup_storage(options \\ []) do
    backend_config = Keyword.get(options, :backend, %{type: :local})
    chunk_options = Keyword.get(options, :chunk_options, [])
    compression = Keyword.get(options, :compression, :zstd)

    with {:ok, :configured} <- configure_storage(backend_config),
         {:ok, :test_passed} <- test_storage(backend_config.type) do
      {:ok, %{
        backend: backend_config,
        chunk_options: chunk_options,
        compression: compression,
        status: :ready
      }}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  # Private helper functions

  defp retrieve_chunks_for_index(index, chunk_store) when not is_nil(chunk_store) do
    chunks = Enum.map(index.chunks, fn chunk ->
      case get_chunk(chunk_store, chunk.id) do
        {:ok, stored_chunk} -> stored_chunk
        {:error, reason} -> {:error, {:chunk_retrieval_failed, chunk.id, reason}}
      end
    end)

    case Enum.find(chunks, &match?({:error, _}, &1)) do
      nil -> {:ok, chunks}
      {:error, reason} -> {:error, reason}
    end
  end

  defp retrieve_chunks_for_index(_index, nil) do
    {:error, :chunk_store_required}
  end
end
