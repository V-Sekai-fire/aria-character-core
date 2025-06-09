# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaStorage.WaffleAdapter do
  @moduledoc """
  Waffle adapter for integrating desync chunk storage with existing chunk stores.

  This adapter allows seamless integration between Waffle's file upload system
  and our desync-compatible chunk storage backends (local, S3, SFTP, HTTP).
  """

  alias AriaStorage.{ChunkStore, ChunkUploader, Chunks}
  alias AriaStorage.Parsers.CasyncFormat

  @behaviour AriaStorage.ChunkStore.Behaviour

  defstruct [
    :backend,      # The Waffle storage backend (:local, :s3, etc.)
    :config,       # Backend-specific configuration
    :uploader,     # Waffle uploader module
    :fallback      # Fallback chunk store for reads
  ]

  @type t :: %__MODULE__{
    backend: atom(),
    config: map(),
    uploader: module(),
    fallback: ChunkStore.t() | nil
  }

  @doc """
  Creates a new Waffle adapter.

  Options:
  - `:backend` - Waffle backend (:local, :s3, etc.)
  - `:config` - Backend configuration
  - `:uploader` - Waffle uploader module (defaults to ChunkUploader)
  - `:fallback` - Fallback chunk store for reads
  """
  def new(opts \\ []) do
    %__MODULE__{
      backend: Keyword.get(opts, :backend, :local),
      config: Keyword.get(opts, :config, %{}),
      uploader: Keyword.get(opts, :uploader, ChunkUploader),
      fallback: Keyword.get(opts, :fallback)
    }
  end

  @doc """
  Configures Waffle for the specified backend.
  """
  def configure_waffle(backend, config) do
    case backend do
      :local ->
        configure_local_storage(config)

      :s3 ->
        configure_s3_storage(config)

      :gcs ->
        configure_gcs_storage(config)

      _ ->
        {:error, {:unsupported_backend, backend}}
    end
  end

  # ChunkStore.Behaviour implementation

  @impl true
  def store_chunk(%__MODULE__{} = adapter, %Chunks{} = chunk) do
    case upload_chunk_with_waffle(adapter, chunk) do
      {:ok, urls} ->
        # Store metadata about the uploaded chunk
        metadata = %{
          chunk_id: chunk.id,
          size: chunk.size,
          backend: adapter.backend,
          urls: urls,
          stored_at: DateTime.utc_now()
        }
        {:ok, metadata}

      {:error, reason} ->
        # Try fallback store if available
        case adapter.fallback do
          nil -> {:error, reason}
          fallback -> ChunkStore.store_chunk(fallback, chunk)
        end
    end
  end

  @impl true
  def get_chunk(%__MODULE__{} = adapter, chunk_id) do
    case download_chunk_with_waffle(adapter, chunk_id) do
      {:ok, binary_data} ->
        # Parse the chunk data using our casync parser
        case CasyncFormat.parse_chunk(binary_data) do
          {:ok, %{header: header, data: data}} ->
            # Decompress if needed
            case header.compression do
              :zstd ->
                case Chunks.decompress_chunk(data, :zstd) do
                  {:ok, decompressed} -> create_chunk_from_data(chunk_id, decompressed, data)
                  decompressed when is_binary(decompressed) -> create_chunk_from_data(chunk_id, decompressed, data)
                  {:error, _} -> create_chunk_from_data(chunk_id, data, data)
                end

              :none ->
                create_chunk_from_data(chunk_id, data, data)

              _ ->
                {:error, {:unsupported_compression, header.compression}}
            end

          {:error, _} ->
            # Fallback: treat as raw chunk data
            create_chunk_from_data(chunk_id, binary_data, binary_data)
        end

      {:error, reason} ->
        # Try fallback store if available
        case adapter.fallback do
          nil -> {:error, reason}
          fallback -> ChunkStore.get_chunk(fallback, chunk_id)
        end
    end
  end

  @impl true
  def chunk_exists?(%__MODULE__{} = adapter, chunk_id) do
    chunk_url = build_chunk_url(adapter, chunk_id)
    case adapter.backend do
      :local ->
        File.exists?(chunk_url)

      :s3 ->
        check_s3_object_exists(adapter, chunk_id)

      _ ->
        # For other backends, try to get the chunk
        case get_chunk(adapter, chunk_id) do
          {:ok, _} -> true
          {:error, _} -> false
        end
    end
  end

  @impl true
  def delete_chunk(%__MODULE__{} = adapter, chunk_id) do
    case adapter.uploader.delete({chunk_id, %{chunk_id: chunk_id}}) do
      :ok -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  def list_chunks(%__MODULE__{} = adapter, opts \\ []) do
    # This would depend on the backend implementation
    # For now, return empty list with a warning
    require Logger
    Logger.warning("list_chunks not fully implemented for Waffle adapter")
    {:ok, []}
  end

  @impl true
  def get_stats(%__MODULE__{} = adapter) do
    # Basic stats - could be enhanced with backend-specific implementations
    %{
      backend: adapter.backend,
      type: :waffle_adapter,
      configured: true
    }
  end

  # Private functions

  defp upload_chunk_with_waffle(adapter, chunk) do
    scope = %{chunk_id: chunk.id}

    case adapter.uploader.store({chunk, scope}) do
      {:ok, filename} ->
        urls = adapter.uploader.urls({filename, scope})
        {:ok, urls}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp download_chunk_with_waffle(adapter, chunk_id) do
    chunk_filename = build_chunk_filename(chunk_id)
    scope = %{chunk_id: chunk_id}

    case adapter.uploader.url({chunk_filename, scope}, :original) do
      url when is_binary(url) ->
        download_from_url(url)

      _ ->
        {:error, :chunk_not_found}
    end
  end

  defp download_from_url(url) do
    case HTTPoison.get(url) do
      {:ok, %{status_code: 200, body: body}} ->
        {:ok, body}

      {:ok, %{status_code: status}} ->
        {:error, {:http_error, status}}

      {:error, reason} ->
        {:error, {:http_request_failed, reason}}
    end
  end

  defp build_chunk_url(adapter, chunk_id) do
    chunk_filename = build_chunk_filename(chunk_id)
    scope = %{chunk_id: chunk_id}
    adapter.uploader.url({chunk_filename, scope}, :original)
  end

  defp build_chunk_filename(chunk_id) do
    chunk_id
    |> Base.encode16(case: :lower)
    |> Kernel.<>(".cacnk")
  end

  defp create_chunk_from_data(chunk_id, data, compressed_data) do
    chunk = %Chunks{
      id: chunk_id,
      data: data,
      size: byte_size(data),
      compressed: compressed_data,
      offset: 0,
      checksum: :crypto.hash(:sha256, data)
    }
    {:ok, chunk}
  end

  defp check_s3_object_exists(adapter, chunk_id) do
    # This would use ExAws to check if S3 object exists
    # Implementation depends on S3 configuration
    bucket = adapter.config[:bucket]
    key = build_s3_key(chunk_id)

    case ExAws.S3.head_object(bucket, key) |> ExAws.request() do
      {:ok, _} -> true
      {:error, _} -> false
    end
  end

  defp build_s3_key(chunk_id) do
    chunk_id_hex = Base.encode16(chunk_id, case: :lower)
    <<a::binary-size(2), b::binary-size(2), rest::binary>> = chunk_id_hex
    "chunks/#{a}/#{b}/#{chunk_id_hex}.cacnk"
  end

  defp configure_local_storage(config) do
    storage_path = Map.get(config, :storage_path, "priv/static/chunks")

    Application.put_env(:waffle, :storage, Waffle.Storage.Local)
    Application.put_env(:waffle, :storage_dir_prefix, storage_path)

    # Ensure directory exists
    File.mkdir_p!(storage_path)
    {:ok, :configured}
  end

  defp configure_s3_storage(config) do
    required_keys = [:bucket, :region]

    case validate_s3_config(config, required_keys) do
      :ok ->
        Application.put_env(:waffle, :storage, Waffle.Storage.S3)
        Application.put_env(:waffle, :bucket, config.bucket)

        # Configure ExAws
        Application.put_env(:ex_aws, :region, config.region)
        if config[:access_key_id] do
          Application.put_env(:ex_aws, :access_key_id, config.access_key_id)
        end
        if config[:secret_access_key] do
          Application.put_env(:ex_aws, :secret_access_key, config.secret_access_key)
        end

        {:ok, :configured}

      {:error, missing_keys} ->
        {:error, {:missing_s3_config, missing_keys}}
    end
  end

  defp configure_gcs_storage(config) do
    # Google Cloud Storage configuration
    required_keys = [:bucket]

    case validate_config(config, required_keys) do
      :ok ->
        Application.put_env(:waffle, :storage, Waffle.Storage.GoogleCloudStorage)
        Application.put_env(:waffle, :bucket, config.bucket)
        {:ok, :configured}

      {:error, missing_keys} ->
        {:error, {:missing_gcs_config, missing_keys}}
    end
  end

  defp validate_s3_config(config, required_keys) do
    missing_keys = Enum.filter(required_keys, fn key ->
      not Map.has_key?(config, key)
    end)

    if Enum.empty?(missing_keys) do
      :ok
    else
      {:error, missing_keys}
    end
  end

  defp validate_config(config, required_keys) do
    missing_keys = Enum.filter(required_keys, fn key ->
      not Map.has_key?(config, key)
    end)

    if Enum.empty?(missing_keys) do
      :ok
    else
      {:error, missing_keys}
    end
  end
end
