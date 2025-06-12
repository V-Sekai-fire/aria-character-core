# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaStorage.Storage do
  @moduledoc """
  Storage context for managing chunk stores and indexes.

  Handles:
  - Multiple chunk store backends (local, S3, SFTP, HTTP)
  - Chunk store routing and failover
  - Index storage and retrieval
  - Cache management
  - Storage optimization and deduplication
  """

  alias AriaStorage.{Chunks, Index, ChunkStore}
  alias AriaData.StorageRepo
  import Ecto.Query

  @doc """
  Stores chunks in the configured chunk stores.

  Options:
  - `:stores` - List of chunk store configurations
  - `:cache` - Cache store configuration
  - `:verify` - Verify chunk integrity after storage
  """
  def store_chunks(chunks, opts \\ []) do
    stores = get_chunk_stores(opts)
    cache = get_cache_store(opts)
    verify = Keyword.get(opts, :verify, true)

    results = Enum.map(chunks, fn chunk ->
      store_single_chunk(chunk, stores, cache, verify)
    end)

    case Enum.find(results, &match?({:error, _}, &1)) do
      nil ->
        stored_chunks = Enum.map(results, fn {:ok, chunk} -> chunk end)
        {:ok, stored_chunks}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Stores an index file in the configured index store.
  """
  def store_index(index, opts \\ []) do
    index_store = get_index_store(opts)

    case generate_index_reference(index) do
      {:ok, index_ref} ->
        case store_index_in_store(index, index_ref, index_store) do
          :ok ->
            # Also store metadata in database
            metadata = %{
              index_ref: index_ref,
              format: index.format,
              chunk_count: index.chunk_count,
              total_size: index.total_size,
              created_at: index.created_at,
              checksum: index.checksum
            }

            # create_file_record always returns {:ok, _} for now (stub implementation)
            {:ok, file_record} = create_file_record(metadata)
            {:ok, %{index_ref: index_ref, file_id: file_record.id}}

          {:error, reason} ->
            {:error, reason}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Retrieves an index from storage.
  """
  def get_index(index_ref) do
    # get_file_record_by_ref always returns {:error, :not_implemented} for now (stub)
    case get_file_record_by_ref(index_ref) do
      {:error, :not_implemented} ->
        # Fall back to direct index store lookup for now
        index_store = get_index_store([])
        get_index_from_store(index_ref, index_store)
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Retrieves chunks for an index.
  """
  def get_chunks_for_index(index, opts \\ []) do
    stores = get_chunk_stores(opts)
    cache = get_cache_store(opts)

    chunk_results = Enum.map(index.chunks, fn chunk ->
      get_single_chunk(chunk.id, stores, cache)
    end)

    case Enum.find(chunk_results, &match?({:error, _}, &1)) do
      nil ->
        chunks = Enum.map(chunk_results, fn {:ok, chunk} -> chunk end)
        {:ok, chunks}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Lists all stored files with their metadata.
  """
  def list_files(opts \\ []) do
    limit = Keyword.get(opts, :limit, 100)
    offset = Keyword.get(opts, :offset, 0)

    query = from f in AriaStorage.FileRecord,
            order_by: [desc: f.inserted_at],
            limit: ^limit,
            offset: ^offset

    case StorageRepo.all(query) do
      files when is_list(files) ->
        {:ok, files}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Deletes a file and its associated chunks.

  Options:
  - `:force` - Force deletion even if chunks are referenced by other files
  """
  def delete_file(path, opts \\ []) do
    stores = get_chunk_stores(opts)
    index_store = get_index_store(opts)
    _force = Keyword.get(opts, :force, false)

    with {:ok, index_ref} <- get_index_ref(path, index_store),
         {:ok, index} <- get_index_from_store(index_store, index_ref) do
      # Implementation for deleting file and associated chunks
    end
  end

  @doc """
  Prunes unreferenced chunks from storage.
  """
  def prune_chunks(opts \\ []) do
    stores = get_chunk_stores(opts)

    # Get all chunk IDs referenced by existing files
    referenced_chunks = get_all_referenced_chunks()

    # Get all chunks in stores
    # get_all_stored_chunks always returns {:ok, []} for now (stub)
    {:ok, stored_chunks} = get_all_stored_chunks(stores)
    unreferenced = MapSet.difference(
      MapSet.new(stored_chunks),
      MapSet.new(referenced_chunks)
    )

    delete_unreferenced_chunks(MapSet.to_list(unreferenced), stores)
  end

  @doc """
  Verifies the integrity of stored chunks.
  """
  def verify_chunks(opts \\ []) do
    stores = get_chunk_stores(opts)
    repair = Keyword.get(opts, :repair, false)

    # get_all_stored_chunks always returns {:ok, []} for now (stub)
    {:ok, chunk_ids} = get_all_stored_chunks(stores)
    results = Enum.map(chunk_ids, fn chunk_id ->
      verify_single_chunk(chunk_id, stores, repair)
    end)

    {valid, invalid} = Enum.split_with(results, &match?({:ok, _}, &1))

    {:ok, %{
      total: length(results),
      valid: length(valid),
      invalid: length(invalid),
      invalid_chunks: Enum.map(invalid, fn {:error, {chunk_id, _}} -> chunk_id end)
    }}
  end

  @doc """
  Gets storage statistics.
  """
  def get_storage_stats do
    with {:ok, file_count} <- count_files(),
         {:ok, total_size} <- calculate_total_size(),
         {:ok, chunk_count} <- count_unique_chunks(),
         {:ok, compressed_size} <- calculate_compressed_size() do

      compression_ratio = if total_size > 0, do: compressed_size / total_size, else: 0.0

      {:ok, %{
        file_count: file_count,
        total_size: total_size,
        compressed_size: compressed_size,
        chunk_count: chunk_count,
        compression_ratio: compression_ratio,
        deduplication_savings: total_size - compressed_size
      }}
    end
  end

  # Private functions

  defp get_chunk_stores(opts) do
    opts[:stores] || Application.get_env(:aria_storage, :chunk_stores) || []
  end

  defp get_cache_store(opts) do
    case Keyword.get(opts, :cache, Application.get_env(:aria_storage, :cache_store)) do
      nil -> nil
      config -> ChunkStore.new(config)
    end
  end

  defp get_index_store(opts) do
    config = Keyword.get(opts, :index_store, Application.get_env(:aria_storage, :index_store))
    ChunkStore.new(config)
  end

  defp store_single_chunk(chunk, stores, cache, verify) do
    # Try cache first
    result = case cache do
      nil -> store_in_primary_stores(chunk, stores)
      cache_store ->
        case ChunkStore.store_chunk(cache_store, chunk) do
          :ok -> store_in_primary_stores(chunk, stores)
          {:error, _} -> store_in_primary_stores(chunk, stores)
        end
    end

    if verify and result == :ok do
      verify_stored_chunk(chunk, stores)
    else
      result
    end
  end

  defp store_in_primary_stores(chunk, stores) do
    # Store in first available store
    case stores do
      [primary | fallback] ->
        case ChunkStore.store_chunk(primary, chunk) do
          :ok -> {:ok, chunk}
          {:error, _} when fallback != [] ->
            store_in_primary_stores(chunk, fallback)
          {:error, reason} ->
            {:error, reason}
        end

      [] ->
        {:error, :no_stores_available}
    end
  end

  defp verify_stored_chunk(chunk, stores) do
    case get_single_chunk(chunk.id, stores, nil) do
      {:ok, retrieved_chunk} ->
        if retrieved_chunk.id == chunk.id do
          {:ok, chunk}
        else
          {:error, {:verification_failed, chunk.id}}
        end

      {:error, reason} ->
        {:error, {:verification_failed, reason}}
    end
  end

  defp get_single_chunk(chunk_id, stores, cache) do
    # Try cache first
    case cache do
      nil -> get_from_primary_stores(chunk_id, stores)
      cache_store ->
        case ChunkStore.get_chunk(cache_store, chunk_id) do
          {:ok, chunk} -> {:ok, chunk}
          {:error, _} -> get_from_primary_stores(chunk_id, stores)
        end
    end
  end

  defp get_from_primary_stores(chunk_id, stores) do
    case stores do
      [primary | fallback] ->
        case ChunkStore.get_chunk(primary, chunk_id) do
          {:ok, chunk} -> {:ok, chunk}
          {:error, _} when fallback != [] ->
            get_from_primary_stores(chunk_id, fallback)
          {:error, reason} ->
            {:error, reason}
        end

      [] ->
        {:error, :chunk_not_found}
    end
  end

  defp generate_index_reference(index) do
    # Generate a unique reference for the index
    ref = "#{index.format}_#{DateTime.to_unix(index.created_at)}_#{:rand.uniform(1000000)}"
    {:ok, ref}
  end

  defp store_index_in_store(index, index_ref, index_store) do
    case Index.serialize(index) do
      {:ok, binary_data} ->
        ChunkStore.store_data(index_store, index_ref, binary_data)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp get_index_from_store(index_ref, index_store) do
    case ChunkStore.get_data(index_store, index_ref) do
      {:ok, binary_data} ->
        Index.deserialize(binary_data)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp create_file_record(metadata) do
    # TODO: Implement database integration
    # changeset = AriaStorage.File.changeset(%AriaStorage.File{}, metadata)
    # StorageRepo.insert(changeset)
    {:ok, %{id: "stub_file_id", metadata: metadata}}
  end

  defp get_file_record(_file_id) do
    # TODO: Implement database integration
    # case StorageRepo.get(AriaStorage.File, file_id) do
    #   nil -> {:error, :file_not_found}
    #   file -> {:ok, file}
    # end
    {:error, :not_implemented}
  end

  defp get_file_record_by_ref(_index_ref) do
    # TODO: Implement database integration
    # case StorageRepo.get_by(AriaStorage.File, index_ref: index_ref) do
    #   nil -> {:error, :file_not_found}
    #   file -> {:ok, file}
    # end
    {:error, :not_implemented}
  end

  defp maybe_delete_chunks(_chunks, _force) do
    # TODO: Implement chunk deletion with force option
    # For now, this is a no-op
    :ok
  end

  defp delete_index(_index_ref) do
    # TODO: Implement index deletion
    # For now, this is a no-op
    :ok
  end

  defp get_all_referenced_chunks do
    # This would query the database for all chunk IDs referenced by existing files
    # Simplified implementation
    []
  end

  defp get_all_stored_chunks(_stores) do
    # This would list all chunks in the stores
    # Simplified implementation
    {:ok, []}
  end

  defp delete_unreferenced_chunks(chunk_ids, stores) do
    Enum.each(chunk_ids, fn chunk_id ->
      delete_chunk_from_stores(chunk_id, stores)
    end)
    {:ok, length(chunk_ids)}
  end

  defp delete_chunk_from_stores(chunk_id, stores) do
    Enum.each(stores, fn store ->
      ChunkStore.delete_chunk(store, chunk_id)
    end)
  end

  defp verify_single_chunk(chunk_id, stores, repair) do
    case get_single_chunk(chunk_id, stores, nil) do
      {:ok, chunk} ->
        expected_id = Chunks.calculate_chunk_id(chunk.data)
        if expected_id == chunk.id do
          {:ok, chunk_id}
        else
          if repair do
            delete_chunk_from_stores(chunk_id, stores)
          end
          {:error, {chunk_id, :checksum_mismatch}}
        end

      {:error, reason} ->
        {:error, {chunk_id, reason}}
    end
  end

  defp count_files do
    count = StorageRepo.aggregate(AriaStorage.File, :count, :id)
    {:ok, count}
  end

  defp calculate_total_size do
    total = StorageRepo.aggregate(AriaStorage.File, :sum, :total_size) || 0
    {:ok, total}
  end

  defp count_unique_chunks do
    # This would require a more complex query to count unique chunks
    # Simplified implementation
    {:ok, 0}
  end

  defp calculate_compressed_size do
    # This would calculate the total compressed size of all chunks
    # Simplified implementation
    {:ok, 0}
  end

  defp get_index_ref(path, index_store) do
    # For now, we assume a simple mapping from path to index ref
    # In a real system, this would involve a lookup in a database
    # or a specific file naming convention.
    index_ref = :crypto.hash(:sha256, path) |> Base.encode16(case: :lower)
    {:ok, index_ref}
  end
end
