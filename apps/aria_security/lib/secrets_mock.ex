# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaSecurity.SecretsMock do
  @moduledoc "Mock implementation of the Secrets module for testing.\n\nThis module provides the same interface as AriaSecurity.Secrets but stores\nsecrets in memory instead of connecting to an external OpenBao server.\n"
  use Agent
  require Logger
  @doc "Start the mock secrets store.\n"
  def start_link(_opts \\ []) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  @doc "Stop the mock secrets store.\n"
  def stop do
    if Process.whereis(__MODULE__) do
      Agent.stop(__MODULE__)
    end
  end

  @doc "Mock implementation of init/1 that always succeeds.\n"
  def init(config) do
    Logger.info("Mock: Initializing connection to OpenBao with config: #{inspect(config)}")

    case Process.whereis(__MODULE__) do
      nil -> start_link()
      _pid -> :ok
    end

    case config do
      %{host: _host, port: _port, scheme: _scheme, auth: %{credentials: %{token: _token}}} ->
        {:ok, %{vault_connected: true, mock: true}}

      _ ->
        {:error, :invalid_config}
    end
  end

  @doc "Mock implementation of write/2 that stores secrets in memory.\n"
  def write(path, data) when is_binary(path) and is_map(data) do
    Logger.info("Mock: Writing secret to path: #{path}")

    case Process.whereis(__MODULE__) do
      nil ->
        {:error, :not_initialized}

      _pid ->
        Agent.update(__MODULE__, fn store -> Map.put(store, path, data) end)
        {:ok, %{path: path, stored: true}}
    end
  end

  @doc "Mock implementation of read/1 that retrieves secrets from memory.\n"
  def read(path) when is_binary(path) do
    Logger.info("Mock: Reading secret from path: #{path}")

    case Process.whereis(__MODULE__) do
      nil ->
        {:error, :not_initialized}

      _pid ->
        case Agent.get(__MODULE__, fn store -> Map.get(store, path) end) do
          nil ->
            {:error, :not_found}

          data ->
            string_data =
              for {key, value} <- data, into: %{} do
                {to_string(key), value}
              end

            {:ok, string_data}
        end
    end
  end

  @doc "Mock implementation of delete/1 that removes secrets from memory.\n"
  def delete(path) when is_binary(path) do
    Logger.info("Mock: Deleting secret at path: #{path}")

    case Process.whereis(__MODULE__) do
      nil ->
        {:error, :not_initialized}

      _pid ->
        existed = Agent.get(__MODULE__, fn store -> Map.has_key?(store, path) end)
        Agent.update(__MODULE__, fn store -> Map.delete(store, path) end)

        if existed do
          {:ok, %{path: path, deleted: true}}
        else
          {:error, :not_found}
        end
    end
  end

  @doc "Mock implementation of list/1 that lists secrets from memory.\n"
  def list(path_prefix \\ "") when is_binary(path_prefix) do
    Logger.info("Mock: Listing secrets with prefix: #{path_prefix}")

    case Process.whereis(__MODULE__) do
      nil ->
        {:error, :not_initialized}

      _pid ->
        keys =
          Agent.get(__MODULE__, fn store ->
            store
            |> Map.keys()
            |> Enum.filter(fn key -> String.starts_with?(key, path_prefix) end)
          end)

        {:ok, %{keys: keys}}
    end
  end

  @doc "Clear all stored secrets (for testing).\n"
  def clear_all do
    case Process.whereis(__MODULE__) do
      nil ->
        :ok

      _pid ->
        Agent.update(__MODULE__, fn _store -> %{} end)
        :ok
    end
  end
end
