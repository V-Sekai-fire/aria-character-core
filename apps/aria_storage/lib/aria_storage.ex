# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaStorage do
  @moduledoc """
  AriaStorage provides content-addressed storage services for the Aria platform.

  This service handles:
  - Desync-based content-defined chunking
  - Content-addressed storage with deduplication
  - Chunk stores (local, remote, S3, etc.)
  - Index files (.caibx/.caidx) for efficient file reconstruction
  - Archive support (.catar) for directory trees
  - Multiple storage backends
  - File metadata management
  - CDN integration and synchronization
  - Efficient delta updates using seeds
  """

  alias AriaStorage.{Chunks, Archives, Storage}
  alias AriaStorage.Files

  @doc """
  Chunks a file using desync content-defined chunking and uploads to storage.

  Returns an index file reference that can be used to reconstruct the original file.
  """
  def chunk_and_store(file_path, opts \\ []) do
    with {:ok, chunks} <- Chunks.create_chunks(file_path, opts),
         {:ok, index} <- Chunks.create_index(chunks, opts),
         {:ok, stored_chunks} <- Storage.store_chunks(chunks, opts),
         {:ok, index_ref} <- Storage.store_index(index, opts) do
      {:ok, %{index: index_ref, chunks: stored_chunks, metadata: %{}}}
    end
  end

  # TODO: Implement metadata extraction
  # defp extract_metadata(_file_path) do
  #   %{}
  # end

  @doc """
  Extracts a file from storage using its index reference.

  Optionally uses seed files for efficient reconstruction.
  """
  def extract_file(index_ref, output_path, opts \\ []) do
    with {:ok, index} <- Storage.get_index(index_ref),
         {:ok, chunks} <- Storage.get_chunks_for_index(index, opts),
         {:ok, _file} <- Chunks.assemble_file(chunks, index, output_path, opts) do
      {:ok, output_path}
    end
  end

  @doc """
  Creates a catar archive from a directory tree.
  """
  def create_archive(directory_path, opts \\ []) do
    Archives.create_catar(directory_path, opts)
  end

  @doc """
  Extracts a catar archive to a directory.
  """
  def extract_archive(archive_ref, output_dir, opts \\ []) do
    Archives.extract_catar(archive_ref, output_dir, opts)
  end
  defdelegate upload_file(file_path, opts \\ []), to: Files

  @doc """
  Downloads a file from storage.
  """
  defdelegate download_file(file_id, opts \\ []), to: Files

  @doc """
  Gets file metadata.
  """
  defdelegate get_file(file_id), to: Files

  @doc """
  Lists files for a user.
  """
  defdelegate list_user_files(user_id, opts \\ []), to: Files

  @doc """
  Deletes a file.
  """
  defdelegate delete_file(file_id), to: Files

  @doc """
  Gets file storage statistics.
  """
  defdelegate get_storage_stats(), to: Storage

  @doc """
  Creates a file snapshot.
  """
  defdelegate create_snapshot(file_id), to: Files

  @doc """
  Lists file versions.
  """
  defdelegate list_file_versions(file_id), to: Files

  # Waffle Integration

  @doc """
  Stores a file using Waffle with chunking and compression.

  Options:
  - `:backend` - Storage backend (:local, :s3, :gcs)
  - `:bucket` - Bucket name for cloud storage
  - `:chunk_size` - Chunk size in bytes
  - `:compress` - Enable compression

  Returns `{:ok, %{index_ref: ref, chunks_stored: count}}` or `{:error, reason}`.
  """
  defdelegate store_with_waffle(file_path, opts \\ []), to: Storage, as: :store_file_with_waffle

  @doc """
  Retrieves a file from Waffle storage using the index reference.
  """
  defdelegate get_with_waffle(index_ref, opts \\ []), to: Storage, as: :get_file_with_waffle

  @doc """
  Lists files stored with Waffle, optionally filtered by backend.
  """
  defdelegate list_waffle_files(opts \\ []), to: Storage

  @doc """
  Configures Waffle storage for the application.
  """
  defdelegate configure_waffle(config \\ %{}), to: Storage, as: :configure_waffle_storage

  @doc """
  Tests Waffle storage connectivity and functionality.
  """
  defdelegate test_waffle(backend \\ :local, opts \\ []), to: Storage, as: :test_waffle_storage

  @doc """
  Migrates existing chunks to Waffle storage.
  """
  defdelegate migrate_to_waffle(target_backend, opts \\ []), to: Storage
end
