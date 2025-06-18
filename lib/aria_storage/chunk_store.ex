# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaStorage.ChunkStore do
  @moduledoc """
  Chunk storage backend interface for AriaStorage.

  This module provides a unified interface for storing and retrieving
  chunks across different storage backends (local, S3, SFTP, etc.).
  Currently contains stubs for future implementation.
  """

  defmodule Behaviour do
    @moduledoc """
    Behaviour for chunk store implementations.
    """

    @callback store_chunk(adapter :: term(), chunk :: AriaStorage.Chunks.t()) :: {:ok, term()} | {:error, term()}
    @callback get_chunk(adapter :: term(), chunk_id :: binary()) :: {:ok, AriaStorage.Chunks.t()} | {:error, term()}
    @callback chunk_exists?(adapter :: term(), chunk_id :: binary()) :: boolean()
    @callback delete_chunk(adapter :: term(), chunk_id :: binary()) :: :ok | {:error, term()}
    @callback list_chunks(adapter :: term(), opts :: keyword()) :: {:ok, [binary()]} | {:error, term()}
    @callback get_stats(adapter :: term()) :: {:ok, map()} | {:error, term()}
  end

  @doc """
  Creates a new chunk store instance.

  ## Parameters
  - config: Configuration for the chunk store backend

  ## Returns
  - {:ok, store} on success
  - {:error, reason} on failure
  """
  def new(config) do
    # TODO: Implement chunk store initialization
    _ = config
    {:ok, %{backend: :stub, config: config}}
  end

  @doc """
  Stores a chunk in the backend.

  ## Parameters
  - chunk: The chunk to store
  - store: The chunk store instance

  ## Returns
  - :ok on success
  - {:error, reason} on failure
  """
  def store_chunk(chunk, store) do
    # TODO: Implement chunk storage logic
    _ = chunk
    _ = store
    :ok
  end

  @doc """
  Retrieves a chunk from the backend.

  ## Parameters
  - chunk_id: The unique identifier of the chunk
  - store: The chunk store instance

  ## Returns
  - {:ok, chunk} on success
  - {:error, reason} on failure
  """
  def get_chunk(chunk_id, store) do
    # TODO: Implement chunk retrieval logic
    _ = chunk_id
    _ = store
    {:error, :not_found}
  end

  @doc """
  Deletes a chunk from the backend.

  ## Parameters
  - chunk_id: The unique identifier of the chunk
  - store: The chunk store instance

  ## Returns
  - :ok on success
  - {:error, reason} on failure
  """
  def delete_chunk(chunk_id, store) do
    # TODO: Implement chunk deletion logic
    _ = chunk_id
    _ = store
    :ok
  end

  @doc """
  Stores arbitrary data in the backend.

  ## Parameters
  - key: The storage key
  - data: The data to store
  - store: The chunk store instance

  ## Returns
  - :ok on success
  - {:error, reason} on failure
  """
  def store_data(key, data, store) do
    # TODO: Implement data storage logic
    _ = key
    _ = data
    _ = store
    :ok
  end

  @doc """
  Retrieves arbitrary data from the backend.

  ## Parameters
  - key: The storage key
  - store: The chunk store instance

  ## Returns
  - {:ok, data} on success
  - {:error, reason} on failure
  """
  def get_data(key, store) do
    # TODO: Implement data retrieval logic
    _ = key
    _ = store
    {:error, :not_found}
  end

  @doc """
  Deletes arbitrary data from the backend.

  ## Parameters
  - key: The storage key
  - store: The chunk store instance

  ## Returns
  - :ok on success
  - {:error, reason} on failure
  """
  def delete_data(key, store) do
    # TODO: Implement data deletion logic
    _ = key
    _ = store
    :ok
  end
end
