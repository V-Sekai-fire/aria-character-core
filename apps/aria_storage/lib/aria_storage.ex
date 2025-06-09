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

  alias AriaStorage.{Files, Chunks, Archives, Storage}

  @doc """
  Chunks a file using desync content-defined chunking and uploads to storage.
  
  Returns an index file reference that can be used to reconstruct the original file.
  """
  def chunk_and_store(file_path, opts \\ []) do
    with {:ok, chunks} <- Chunks.create_chunks(file_path, opts),
         {:ok, index} <- Chunks.create_index(chunks, opts),
         {:ok, stored_chunks} <- Storage.store_chunks(chunks, opts),
         {:ok, index_ref} <- Storage.store_index(index, opts) do
      {:ok, %{index: index_ref, chunks: stored_chunks, metadata: extract_metadata(file_path)}}
    end
  end

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
end
