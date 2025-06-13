# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaStorage.WaffleExample do
  @moduledoc """
  Example usage of AriaStorage with Waffle integration.

  This module provides practical examples of how to use the Waffle-based
  storage system for various use cases.
  """

  alias AriaStorage.Storage

  @doc """
  Example: Store a file using local Waffle storage.
  """
  def store_file_locally(file_path, opts \\ []) do
    storage_opts = Keyword.merge([
      backend: :local,
      directory: "/tmp/aria-chunks",
      chunk_size: 64 * 1024,  # 64KB chunks
      compress: true
    ], opts)

    case Storage.store_file_with_waffle(file_path, storage_opts) do
      {:ok, result} ->
        IO.puts("✅ File stored locally")
        IO.puts("   Index: #{result.index_ref}")
        IO.puts("   Chunks: #{result.chunks_stored}")
        IO.puts("   Size: #{result.total_size} bytes")
        {:ok, result}

      {:error, reason} ->
        IO.puts("❌ Failed to store file: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Example: Store a file using S3 Waffle storage.
  """
  def store_file_s3(file_path, bucket, opts \\ []) do
    # Configure AWS credentials (should be set via environment variables)
    storage_opts = Keyword.merge([
      backend: :s3,
      bucket: bucket,
      region: "us-east-1",
      chunk_size: 1024 * 1024,  # 1MB chunks for S3
      compress: true
    ], opts)

    # First configure Waffle for S3
    case Storage.configure_waffle_storage(%{
      storage: :s3,
      bucket: bucket,
      region: storage_opts[:region]
    }) do
      {:ok, _config} ->
        Storage.store_file_with_waffle(file_path, storage_opts)

      error ->
        error
    end
  end

  @doc """
  Example: Retrieve and save a file from Waffle storage.
  """
  def retrieve_and_save(index_ref, output_path, opts \\ []) do
    storage_opts = Keyword.merge([
      backend: :local
    ], opts)

    case Storage.get_file_with_waffle(index_ref, storage_opts) do
      {:ok, result} ->
        case File.write(output_path, result.data) do
          :ok ->
            IO.puts("✅ File retrieved and saved to #{output_path}")
            IO.puts("   Size: #{result.size} bytes")
            IO.puts("   Chunks: #{result.chunks_count}")
            {:ok, output_path}

          {:error, reason} ->
            {:error, {:write_failed, reason}}
        end

      {:error, reason} ->
        IO.puts("❌ Failed to retrieve file: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Example: Batch upload multiple files.
  """
  def batch_upload(file_paths, opts \\ []) do
    storage_opts = Keyword.merge([
      backend: :local,
      chunk_size: 128 * 1024,  # 128KB chunks
      compress: true
    ], opts)

    results = Enum.map(file_paths, fn file_path ->
      case Storage.store_file_with_waffle(file_path, storage_opts) do
        {:ok, result} ->
          {:ok, %{file: file_path, result: result}}
        {:error, reason} ->
          {:error, %{file: file_path, reason: reason}}
      end
    end)

    {successful, failed} = Enum.split_with(results, &match?({:ok, _}, &1))

    IO.puts("📊 Batch upload completed:")
    IO.puts("   Successful: #{length(successful)}")
    IO.puts("   Failed: #{length(failed)}")

    {:ok, %{
      successful: Enum.map(successful, fn {:ok, data} -> data end),
      failed: Enum.map(failed, fn {:error, data} -> data end)
    }}
  end

  @doc """
  Example: Migrate existing storage to Waffle.
  """
  def migrate_to_waffle(target_backend, opts \\ []) do
    migration_opts = Keyword.merge([
      batch_size: 10,
      bucket: "aria-chunks-migrated"
    ], opts)

    IO.puts("🔄 Starting migration to #{target_backend}...")

    case Storage.migrate_to_waffle(target_backend, migration_opts) do
      {:ok, result} ->
        IO.puts("✅ Migration completed successfully")
        IO.puts("   Total chunks: #{result.total_chunks}")
        IO.puts("   Migrated: #{result.migrated}")
        IO.puts("   Failed: #{result.failed}")
        IO.puts("   Target backend: #{result.target_backend}")
        {:ok, result}

      {:error, reason} ->
        IO.puts("❌ Migration failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Example: Storage health check and diagnostics.
  """
  def health_check(backend \\ :local, opts \\ []) do
    IO.puts("🏥 Running storage health check for #{backend}...")

    # Test connectivity
    case Storage.test_waffle_storage(backend, opts) do
      {:ok, result} ->
        IO.puts("✅ Connectivity: #{result.status}")

        # Get configuration
        config = Storage.get_waffle_config()
        IO.puts("📋 Configuration:")
        IO.puts("   Storage: #{config.storage}")
        IO.puts("   Bucket: #{config.bucket}")
        IO.puts("   Directory: #{config.storage_dir_prefix}")

        # List recent files
        case Storage.list_waffle_files(backend: backend, limit: 5) do
          {:ok, files} ->
            IO.puts("📁 Recent files (#{length(files)}):")
            Enum.each(files, fn file ->
              IO.puts("   - #{file.index_ref} (#{format_bytes(file.size)})")
            end)

          {:error, reason} ->
            IO.puts("⚠️  Could not list files: #{inspect(reason)}")
        end

        {:ok, %{status: :healthy, config: config}}

      {:error, result} ->
        IO.puts("❌ Connectivity: #{result.status}")
        IO.puts("   Error: #{inspect(result.error)}")
        {:error, %{status: :unhealthy, error: result.error}}
    end
  end

  @doc """
  Example: Clean up test files and temporary data.
  """
  def cleanup_test_data(pattern \\ "aria_waffle_test_*") do
    temp_dir = System.tmp_dir!()
    
    case File.ls(temp_dir) do
      {:ok, files} ->
        test_files = Enum.filter(files, &String.match?(&1, ~r/#{pattern}/))
        
        Enum.each(test_files, fn file ->
          file_path = Path.join(temp_dir, file)
          File.rm(file_path)
          IO.puts("🗑️  Removed: #{file}")
        end)

        IO.puts("✅ Cleanup completed: #{length(test_files)} files removed")
        {:ok, length(test_files)}

      {:error, reason} ->
        IO.puts("❌ Cleanup failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp format_bytes(bytes) when is_integer(bytes) do
    cond do
      bytes >= 1024 * 1024 * 1024 ->
        "#{Float.round(bytes / (1024 * 1024 * 1024), 2)} GB"
      bytes >= 1024 * 1024 ->
        "#{Float.round(bytes / (1024 * 1024), 2)} MB"
      bytes >= 1024 ->
        "#{Float.round(bytes / 1024, 2)} KB"
      true ->
        "#{bytes} bytes"
    end
  end

  defp format_bytes(_), do: "unknown size"
end
