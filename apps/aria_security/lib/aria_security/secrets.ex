# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaSecurity.Secrets do
  @moduledoc """
  Public interface for secret management, mimicking the Vaultex API.
  Internally uses an Ecto/SQLite backend.
  """

  alias AriaSecurity.Secrets.EctoBackend
  alias Jason

  @doc """
  Reads a secret from the vault.
  Mimics Vaultex.Client.read/2.
  """
  def read(path, _opts \\ []) do
    case EctoBackend.get(path) do
      {:ok, json_value} ->
        case Jason.decode(json_value) do
          {:ok, map_value} -> {:ok, %{"data" => map_value}}
          {:error, _} -> {:error, :json_decoding_failed}
        end
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Writes a secret to the vault.
  Mimics Vaultex.Client.write/3.
  """
  def write(path, data, _opts \\ []) do
    # Vaultex.Client.write/3 expects a map for data.
    # We'll convert it to a JSON string for storage in our single 'value' field.
    # This assumes 'data' is a map and can be safely encoded to JSON.
    case Jason.encode(data) do
      {:ok, json_value} ->
        EctoBackend.put(path, json_value)
      {:error, _} ->
        {:error, :json_encoding_failed}
    end
  end

  @doc """
  Deletes a secret from the vault.
  Mimics Vaultex.Client.delete/2.
  """
  def delete(path, _opts \\ []) do
    EctoBackend.delete(path)
  end

  @doc """
  Lists secrets in the vault.
  Mimics Vaultex.Client.list/2.
  """
  def list(path, _opts \\ []) do
    # Vaultex.Client.list/2 typically returns a map with "keys"
    # We'll return a similar structure.
    case EctoBackend.list() do
      {:ok, keys} ->
        {:ok, %{"keys" => keys}}
      {:error, reason} ->
        {:error, reason}
    end
  end
end