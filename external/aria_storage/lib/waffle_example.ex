# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaStorage.WaffleExample do
  @moduledoc "Example usage of AriaStorage with Waffle integration.\n\nThis module provides practical examples of how to use the Waffle-based\nstorage system for various use cases.\n"
  require Logger
  alias AriaStorage.Storage
  @doc "Example: Store a file using local Waffle storage.\n"
  def store_file_locally(file_path, opts \\ []) do
    storage_opts =
      Keyword.merge(
        [backend: :local, directory: "/tmp/aria-chunks", chunk_size: 64 * 1024, compress: true],
        opts
      )

    case Storage.store_file_with_waffle(file_path, storage_opts) do
      {:ok, result} ->
        Logger.info("File stored locally")
        Logger.info("  Index: #{result.index_ref}")
        Logger.info("  Chunks: #{result.chunks_stored}")
        Logger.info("  Size: #{result.total_size} bytes")
        {:ok, result}

      {:error, reason} ->
        Logger.error("Failed to store file: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc "Example: Store a file using S3 Waffle storage.\n"
  def store_file_s3(file_path, bucket, opts \\ []) do
    storage_opts =
      Keyword.merge(
        [
          backend: :s3,
          bucket: bucket,
          region: "us-east-1",
          chunk_size: 1024 * 1024,
          compress: true
        ],
        opts
      )

    case Storage.configure_waffle_storage(%{
           storage: :s3,
           bucket: bucket,
           region: storage_opts[:region]
         }) do
      {:ok, _config} -> Storage.store_file_with_waffle(file_path, storage_opts)
      error -> error
    end
  end

  @doc "Example: Retrieve and save a file from Waffle storage.\n"
  def retrieve_and_save(index_ref, output_path, opts \\ []) do
    storage_opts =
      Keyword.merge(
        [backend: :local],
        opts
      )

    case Storage.get_file_with_waffle(index_ref, storage_opts) do
      {:ok, result} ->
        case File.write(output_path, result.data) do
          :ok ->
            Logger.info(" File retrieved and saved to #{output_path}")
            Logger.debug("   Size: #{result.size} bytes")
            Logger.debug("   Chunks: #{result.chunks_count}")
            {:ok, output_path}

          {:error, reason} ->
            {:error, {:write_failed, reason}}
        end

      {:error, reason} ->
        Logger.error(" Failed to retrieve file: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc "Example: Batch upload multiple files.\n"
  def batch_upload(file_paths, opts \\ []) do
    storage_opts =
      Keyword.merge(
        [backend: :local, chunk_size: 128 * 1024, compress: true],
        opts
      )

    results =
      Enum.map(file_paths, fn file_path ->
        case Storage.store_file_with_waffle(file_path, storage_opts) do
          {:ok, result} -> {:ok, %{file: file_path, result: result}}
          {:error, reason} -> {:error, %{file: file_path, reason: reason}}
        end
      end)

    {successful, failed} = Enum.split_with(results, &match?({:ok, _}, &1))
    Logger.info(" Batch upload completed:")
    Logger.debug("   Successful: #{length(successful)}")
    Logger.error("   Failed: #{length(failed)}")

    {:ok,
     %{
       successful: Enum.map(successful, fn {:ok, data} -> data end),
       failed: Enum.map(failed, fn {:error, data} -> data end)
     }}
  end

  @doc "Example: Migrate existing storage to Waffle.\n"
  def migrate_to_waffle(target_backend, opts \\ []) do
    migration_opts =
      Keyword.merge(
        [batch_size: 10, bucket: "aria-chunks-migrated"],
        opts
      )

    Logger.info(" Starting migration to #{target_backend}...")
    {:ok, result} = Storage.migrate_to_waffle(target_backend, migration_opts)
    Logger.info(" Migration completed successfully")
    Logger.debug("   Migration started")
    {:ok, result}
  end

  @doc "Example: Storage health check and diagnostics.\n"
  def health_check(backend \\ :local, opts \\ []) do
    Logger.info(" Running storage health check for #{backend}...")

    case Storage.test_waffle_storage(backend, opts) do
      {:ok, _result} ->
        Logger.info(" Connectivity: test_passed")
        config = Storage.get_waffle_config()
        Logger.info(" Configuration:")
        Logger.debug("   Storage: #{config.storage}")
        Logger.debug("   Bucket: #{config.bucket}")
        Logger.debug("   Directory: #{config.storage_dir}")

        case Storage.list_waffle_files(backend: backend, limit: 5) do
          {:ok, files} ->
            Logger.info(" Recent files (#{length(files)}):")

            Enum.each(files, fn file ->
              Logger.debug("   - #{file.index_ref} (#{format_bytes(file.size)})")
            end)

          {:error, reason} ->
            Logger.warning("  Could not list files: #{inspect(reason)}")
        end

        {:ok, %{status: :healthy, config: config}}

      {:error, result} ->
        Logger.error(" Connectivity: test_failed")
        Logger.error("   Error: #{inspect(result)}")
        {:error, %{status: :unhealthy, error: result}}
    end
  end

  @doc "Example: Clean up test files and temporary data.\n"
  def cleanup_test_data(pattern \\ "aria_waffle_test_*") do
    temp_dir = System.tmp_dir!()

    case File.ls(temp_dir) do
      {:ok, files} ->
        test_files = Enum.filter(files, &String.match?(&1, ~r/#{pattern}/))

        Enum.each(test_files, fn file ->
          file_path = Path.join(temp_dir, file)
          File.rm(file_path)
          Logger.info("  Removed: #{file}")
        end)

        Logger.info(" Cleanup completed: #{length(test_files)} files removed")
        {:ok, length(test_files)}

      {:error, reason} ->
        Logger.error(" Cleanup failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp format_bytes(bytes) when is_integer(bytes) do
    cond do
      bytes >= 1024 * 1024 * 1024 -> "#{Float.round(bytes / (1024 * 1024 * 1024), 2)} GB"
      bytes >= 1024 * 1024 -> "#{Float.round(bytes / (1024 * 1024), 2)} MB"
      bytes >= 1024 -> "#{Float.round(bytes / 1024, 2)} KB"
      true -> "#{bytes} bytes"
    end
  end

  defp format_bytes(_) do
    "unknown size"
  end
end
