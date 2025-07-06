# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaStorage.Storage do
  @moduledoc "Main storage interface for Aria Storage system.\n\nThis module provides high-level functions for file storage operations\nusing various backends including Waffle integration.\n"
  alias AriaStorage.{WaffleAdapter, WaffleChunkStore}
  @doc "Store a file using Waffle backend.\n"
  def store_file_with_waffle(file_path, opts \\ []) do
    backend = Keyword.get(opts, :backend, :local)
    config = Keyword.get(opts, :config, %{})

    with {:ok, :configured} <- WaffleAdapter.configure_waffle(backend, config),
         {:ok, result} <- do_store_file_with_waffle(file_path, opts) do
      {:ok, result}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc "Retrieve a file using Waffle backend.\n"
  def get_file_with_waffle(file_ref, opts \\ []) do
    case WaffleChunkStore.retrieve_chunk(file_ref, opts) do
      {:ok, chunk} -> {:ok, chunk}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc "Configure Waffle storage backend.\n"
  def configure_waffle_storage(config) do
    backend = Map.get(config, :backend, :local)
    WaffleAdapter.configure_waffle(backend, config)
  end

  @doc "Migrate existing storage to Waffle backend.\n"
  def migrate_to_waffle(target_backend, opts \\ []) do
    require Logger
    Logger.info("Migration to #{target_backend} requested with options: #{inspect(opts)}")
    {:ok, :migration_started}
  end

  @doc "Test Waffle storage configuration.\n"
  def test_waffle_storage(backend, _opts \\ []) do
    case configure_waffle_storage(%{backend: backend}) do
      {:ok, :configured} ->
        test_file = create_test_file()

        case store_file_with_waffle(test_file, backend: backend) do
          {:ok, _result} ->
            File.rm(test_file)
            {:ok, :test_passed}

          {:error, reason} ->
            File.rm(test_file)
            {:error, {:test_failed, reason}}
        end

      {:error, reason} ->
        {:error, {:config_failed, reason}}
    end
  end

  @doc "Get current Waffle configuration.\n"
  def get_waffle_config do
    %{
      storage: Application.get_env(:waffle, :storage),
      bucket: Application.get_env(:waffle, :bucket),
      storage_dir: Application.get_env(:waffle, :storage_dir_prefix)
    }
  end

  @doc "List files stored via Waffle.\n"
  def list_waffle_files(opts \\ []) do
    _backend = Keyword.get(opts, :backend, :local)
    limit = Keyword.get(opts, :limit, 100)

    case WaffleChunkStore.list_chunks(limit: limit) do
      {:ok, chunks} -> {:ok, Enum.take(chunks, limit)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp do_store_file_with_waffle(file_path, opts) do
    case File.read(file_path) do
      {:ok, data} ->
        chunk_id = :crypto.hash(:sha256, data) |> Base.encode16(case: :lower)

        chunk = %AriaStorage.Chunks{
          id: chunk_id,
          data: data,
          size: byte_size(data),
          checksum: :crypto.hash(:sha256, data)
        }

        case WaffleChunkStore.store_chunk(chunk, opts) do
          {:ok, result} -> {:ok, Map.put(result, :chunk_id, chunk_id)}
          {:error, reason} -> {:error, reason}
        end

      {:error, reason} ->
        {:error, {:file_read_failed, reason}}
    end
  end

  defp create_test_file do
    test_data = "Test file for Waffle storage verification"

    temp_path =
      System.tmp_dir!() |> Path.join("waffle_test_#{System.unique_integer([:positive])}.txt")

    File.write!(temp_path, test_data)
    temp_path
  end
end
