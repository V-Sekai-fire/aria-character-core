# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaStorage.ChunkStore do
  @moduledoc "Generic chunk store interface for different storage backends.\n\nThis module provides a unified interface for storing and retrieving chunks\nacross different storage backends (local, S3, Waffle, etc.).\n"
  alias AriaStorage.Chunks
  @type t :: struct()
  @type chunk_id :: binary()
  @type chunk_metadata :: map()
  @doc "Store a chunk in the storage backend.\n"
  @callback store_chunk(store :: t(), chunk :: Chunks.t()) ::
              {:ok, chunk_metadata()} | {:error, term()}
  @doc "Retrieve a chunk from the storage backend.\n"
  @callback get_chunk(store :: t(), chunk_id :: chunk_id()) ::
              {:ok, Chunks.t()} | {:error, term()}
  @doc "Check if a chunk exists in the storage backend.\n"
  @callback chunk_exists?(store :: t(), chunk_id :: chunk_id()) :: boolean()
  @doc "Delete a chunk from the storage backend.\n"
  @callback delete_chunk(store :: t(), chunk_id :: chunk_id()) :: :ok | {:error, term()}
  @doc "List chunks in the storage backend.\n"
  @callback list_chunks(store :: t(), opts :: keyword()) :: {:ok, [chunk_id()]} | {:error, term()}
  @doc "Get storage backend statistics.\n"
  @callback get_stats(store :: t()) :: map()
  @doc "Store a chunk using the appropriate backend.\n"
  @spec store_chunk(t(), Chunks.t()) :: {:ok, chunk_metadata()} | {:error, term()}
  def store_chunk(store, chunk) do
    store.__struct__.store_chunk(store, chunk)
  end

  @doc "Retrieve a chunk using the appropriate backend.\n"
  @spec get_chunk(t(), chunk_id()) :: {:ok, Chunks.t()} | {:error, term()}
  def get_chunk(store, chunk_id) do
    store.__struct__.get_chunk(store, chunk_id)
  end

  @doc "Check if a chunk exists using the appropriate backend.\n"
  @spec chunk_exists?(t(), chunk_id()) :: boolean()
  def chunk_exists?(store, chunk_id) do
    store.__struct__.chunk_exists?(store, chunk_id)
  end

  @doc "Delete a chunk using the appropriate backend.\n"
  @spec delete_chunk(t(), chunk_id()) :: :ok | {:error, term()}
  def delete_chunk(store, chunk_id) do
    store.__struct__.delete_chunk(store, chunk_id)
  end

  @doc "List chunks using the appropriate backend.\n"
  @spec list_chunks(t(), keyword()) :: {:ok, [chunk_id()]} | {:error, term()}
  def list_chunks(store, opts \\ []) do
    store.__struct__.list_chunks(store, opts)
  end

  @doc "Get storage statistics using the appropriate backend.\n"
  @spec get_stats(t()) :: map()
  def get_stats(store) do
    store.__struct__.get_stats(store)
  end
end
