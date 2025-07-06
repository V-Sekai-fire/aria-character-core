# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaStorage.WaffleConfig do
  @moduledoc "Configuration module for Waffle integration with desync chunk storage.\n\nThis module provides helpers for configuring Waffle with different storage\nbackends and integrating with the aria-character-core configuration system.\n"
  @doc "Configures Waffle for use with different storage backends.\n\nSupports:\n- `:local` - Local filesystem storage\n- `:s3` - Amazon S3 storage\n- `:gcs` - Google Cloud Storage\n"
  def configure_storage(backend, opts \\ []) do
    case backend do
      :local -> configure_local(opts)
      :s3 -> configure_s3(opts)
      :gcs -> configure_gcs(opts)
      _ -> {:error, {:unsupported_backend, backend}}
    end
  end

  @doc "Gets the current Waffle configuration for chunk storage.\n"
  def get_config do
    %{
      storage: Application.get_env(:waffle, :storage),
      bucket: Application.get_env(:waffle, :bucket),
      storage_dir: Application.get_env(:waffle, :storage_dir_prefix),
      asset_host: Application.get_env(:waffle, :asset_host)
    }
  end

  @doc "Creates a Waffle adapter with the given configuration.\n"
  def create_adapter(backend, config \\ %{}) do
    case configure_storage(backend, config) do
      {:ok, _} ->
        AriaStorage.WaffleAdapter.new(
          backend: backend,
          config: config,
          uploader: AriaStorage.ChunkUploader
        )

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp configure_local(opts) do
    storage_dir = Keyword.get(opts, :storage_dir, "priv/static/chunks")
    asset_host = Keyword.get(opts, :asset_host)
    Application.put_env(:waffle, :storage, Waffle.Storage.Local)
    Application.put_env(:waffle, :storage_dir_prefix, storage_dir)

    if asset_host do
      Application.put_env(:waffle, :asset_host, asset_host)
    end

    case File.mkdir_p(storage_dir) do
      :ok -> {:ok, :local_configured}
      {:error, reason} -> {:error, {:mkdir_failed, reason}}
    end
  end

  defp configure_s3(opts) do
    bucket = Keyword.fetch!(opts, :bucket)
    region = Keyword.get(opts, :region, "us-east-1")
    access_key_id = Keyword.get(opts, :access_key_id)
    secret_access_key = Keyword.get(opts, :secret_access_key)
    asset_host = Keyword.get(opts, :asset_host)
    Application.put_env(:waffle, :storage, Waffle.Storage.S3)
    Application.put_env(:waffle, :bucket, bucket)

    if asset_host do
      Application.put_env(:waffle, :asset_host, asset_host)
    end

    Application.put_env(:ex_aws, :region, region)

    if access_key_id do
      Application.put_env(:ex_aws, :access_key_id, access_key_id)
    end

    if secret_access_key do
      Application.put_env(:ex_aws, :secret_access_key, secret_access_key)
    end

    {:ok, :s3_configured}
  end

  defp configure_gcs(opts) do
    bucket = Keyword.fetch!(opts, :bucket)
    keyfile = Keyword.get(opts, :keyfile)
    asset_host = Keyword.get(opts, :asset_host)
    Application.put_env(:waffle, :storage, Waffle.Storage.GoogleCloudStorage)
    Application.put_env(:waffle, :bucket, bucket)

    if asset_host do
      Application.put_env(:waffle, :asset_host, asset_host)
    end

    if keyfile do
      Application.put_env(:goth, :json, keyfile)
    end

    {:ok, :gcs_configured}
  end
end
