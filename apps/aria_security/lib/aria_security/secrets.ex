# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaSecurity.Secrets do
  @moduledoc """
  Security service for managing secrets using OpenBao (open-source Vault alternative).
  
  This module provides a secure interface for storing and retrieving secrets
  using OpenBao as the backend. It uses the Vaultex library for communication
  with OpenBao.
  
  ## Configuration
  
  The module expects OpenBao to be configured with:
  - Host: The OpenBao server hostname
  - Port: The OpenBao server port
  - Scheme: The protocol scheme (http/https)
  - Auth: Authentication configuration with token method
  
  ## Examples
  
      # Initialize connection to OpenBao
      config = %{
        host: "localhost",
        port: 8200,
        scheme: "http",
        auth: %{
          method: :token,
          credentials: %{token: "your-token"}
        }
      }
      
      {:ok, status} = AriaSecurity.Secrets.init(config)
      
      # Store a secret
      {:ok, _} = AriaSecurity.Secrets.write("secret/myapp", %{password: "secret123"})
      
      # Retrieve a secret
      {:ok, data} = AriaSecurity.Secrets.read("secret/myapp")
  """

  require Logger

  @doc """
  Initialize connection to OpenBao.
  
  ## Parameters
  
  - `config` - A map containing OpenBao configuration:
    - `:host` - OpenBao server hostname
    - `:port` - OpenBao server port
    - `:scheme` - Protocol scheme ("http" or "https")
    - `:auth` - Authentication configuration with `:method` and `:credentials`
  
  ## Returns
  
  - `{:ok, status}` - Connection successful, returns OpenBao status
  - `{:error, reason}` - Connection failed
  
  ## Examples
  
      config = %{
        host: "localhost",
        port: 8200,
        scheme: "http",
        auth: %{
          method: :token,
          credentials: %{token: "dev-token"}
        }
      }
      
      {:ok, status} = AriaSecurity.Secrets.init(config)
  """
  def init(_) do
    # Initialize OpenBao/Vault connection using Vaultex
    vault_addr = System.get_env("VAULT_ADDR", "http://localhost:8200")
    vault_token = System.get_env("VAULT_TOKEN", "")
    
    # Configure Vaultex through application environment
    Application.put_env(:vaultex, :vault_addr, vault_addr)
    
    # Start the Vaultex application if not already started
    case Application.ensure_all_started(:vaultex) do
      {:ok, _} ->
        # Authenticate with the token if provided
        if vault_token != "" do
          case Vaultex.Client.auth(:token, {vault_token}) do
            {:ok, _} ->
              Logger.info("Successfully authenticated with OpenBao")
              {:ok, %{vault_connected: true}}
            {:error, reason} ->
              Logger.error("Failed to authenticate with OpenBao: #{inspect(reason)}")
              {:ok, %{vault_connected: false}}
          end
        else
          Logger.warning("No VAULT_TOKEN provided, connection may be limited")
          {:ok, %{vault_connected: false}}
        end
      {:error, reason} ->
        Logger.error("Failed to start Vaultex application: #{inspect(reason)}")
        {:ok, %{vault_connected: false}}
    end
  end

  @doc """
  Store a secret in OpenBao.
  
  ## Parameters
  
  - `path` - The path where the secret will be stored
  - `data` - A map containing the secret data
  
  ## Returns
  
  - `{:ok, response}` - Secret stored successfully
  - `{:error, reason}` - Failed to store secret
  
  ## Examples
  
      {:ok, _} = AriaSecurity.Secrets.write("secret/myapp", %{
        password: "secret123",
        api_key: "key456"
      })
  """
  def write(path, data) when is_binary(path) and is_map(data) do
    case Vaultex.Client.write(:client, path, data, %{}) do
      {:ok, response} ->
        {:ok, response}
      {:error, reason} ->
        {:error, {:write_failed, reason}}
    end
  rescue
    error ->
      {:error, {:write_error, error}}
  end

  @doc """
  Retrieve a secret from OpenBao.
  
  ## Parameters
  
  - `path` - The path of the secret to retrieve
  
  ## Returns
  
  - `{:ok, data}` - Secret retrieved successfully, returns the secret data
  - `{:error, reason}` - Failed to retrieve secret (e.g., not found)
  
  ## Examples
  
      {:ok, data} = AriaSecurity.Secrets.read("secret/myapp")
      password = data["password"]
  """
  def read(path) when is_binary(path) do
    case Vaultex.Client.read(:client, path, %{}) do
      {:ok, nil} ->
        {:error, :not_found}
      {:ok, data} ->
        {:ok, data}
      {:error, reason} ->
        {:error, {:read_failed, reason}}
    end
  rescue
    error ->
      {:error, {:read_error, error}}
  end
end