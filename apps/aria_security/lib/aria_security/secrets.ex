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
  def init(config) do
    # Build vault address from config
    vault_addr = case config do
      %{host: host, port: port, scheme: scheme} ->
        "#{scheme}://#{host}:#{port}"
      _ ->
        System.get_env("VAULT_ADDR", "http://localhost:8200")
    end
    
    # Check vault health before proceeding
    case check_vault_health(vault_addr) do
      {:ok, :healthy} ->
        IO.puts("DEBUG: Vault is healthy")
      {:error, reason} ->
        IO.puts("DEBUG: Vault health check failed: #{inspect(reason)}")
        Logger.error("Vault health check failed: #{inspect(reason)}")
        {:error, {:vault_unhealthy, reason}}
    end

    # Get token from config or environment variable
    vault_token = case config do
      %{auth: %{credentials: %{token: token}}} when is_binary(token) -> token
      _ -> System.get_env("VAULT_TOKEN", "")
    end
    
    IO.puts("DEBUG: Vault address: #{vault_addr}")
    IO.puts("DEBUG: Vault token length: #{String.length(vault_token)}")
    IO.puts("DEBUG: Vault token: #{vault_token}")
    
    # First check if OpenBao is reachable
    case check_vault_health(vault_addr) do
      {:ok, :healthy} ->
        IO.puts("DEBUG: OpenBao health check passed")
      {:error, reason} ->
        IO.puts("DEBUG: OpenBao health check failed: #{inspect(reason)}")
        {:error, {:health_check_failed, reason}}
    end
    
    # Configure Vaultex through application environment
    Application.put_env(:vaultex, :vault_addr, vault_addr)
    
    # Start the Vaultex application if not already started
    case Application.ensure_all_started(:vaultex) do
      {:ok, apps} ->
        IO.puts("DEBUG: Started Vaultex apps: #{inspect(apps)}")
        # Authenticate with the token if provided
        if vault_token != "" do
          IO.puts("DEBUG: Attempting authentication with token...")
          case Vaultex.Client.auth(:token, {vault_token}) do
            {:ok, response} ->
              IO.puts("DEBUG: Authentication successful: #{inspect(response)}")
              Logger.info("Successfully authenticated with OpenBao")
              # Store token for later use
              Process.put(:vault_token, vault_token)
              {:ok, %{vault_connected: true}}
            {:error, reason} ->
              IO.puts("DEBUG: Authentication failed: #{inspect(reason)}")
              Logger.error("Failed to authenticate with OpenBao: #{inspect(reason)}")
              {:error, {:auth_failed, reason}}
          end
        else
          Logger.warning("No VAULT_TOKEN provided, connection may be limited")
          {:error, :no_token}
        end
      {:error, reason} ->
        Logger.error("Failed to start Vaultex application: #{inspect(reason)}")
        {:error, {:vaultex_start_failed, reason}}
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
    # Get stored token from process dictionary or environment
    vault_token = case Process.get(:vault_token) do
      nil -> System.get_env("VAULT_TOKEN", "")
      token -> token
    end
    
    if vault_token == "" do
      {:error, :no_token}
    else
      # Convert path for KV v2 engine (add /data/ and wrap data)
      kv_path = convert_to_kv2_write_path(path)
      kv_data = %{"data" => data}
      
      case Vaultex.Client.write(kv_path, kv_data, :token, {vault_token}) do
        :ok ->
          {:ok, :ok}
        {:ok, response} ->
          {:ok, response}
        {:error, reason} ->
          {:error, {:write_failed, reason}}
      end
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
    # Get stored token from process dictionary or environment
    vault_token = case Process.get(:vault_token) do
      nil -> System.get_env("VAULT_TOKEN", "")
      token -> token
    end
    
    if vault_token == "" do
      {:error, :no_token}
    else
      # Convert path for KV v2 engine (add /data/)
      kv_path = convert_to_kv2_read_path(path)
      
      case Vaultex.Client.read(kv_path, :token, {vault_token}) do
        {:ok, nil} ->
          {:error, :not_found}
        {:ok, response} ->
          # Extract data from KV v2 response (data.data)
          case response do
            %{"data" => data} when is_map(data) -> {:ok, data}
            _ -> {:ok, response}
          end
        {:error, reason} ->
          {:error, {:read_failed, reason}}
      end
    end
  rescue
    error ->
      {:error, {:read_error, error}}
  end

  defp check_vault_health(vault_addr) do
    # Use HTTPoison to check the /v1/sys/health endpoint
    case HTTPoison.get("#{vault_addr}/v1/sys/health") do
      {:ok, %HTTPoison.Response{status_code: status}} when status in [200, 429, 472, 473, 503] ->
        # These are all valid OpenBao health status codes
        {:ok, :healthy}
      {:ok, response} ->
        IO.puts("DEBUG: Unexpected health check response: #{inspect(response)}")
        {:error, {:unexpected_response, response}}
      {:error, reason} ->
        IO.puts("DEBUG: Health check failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # Helper functions for KV v2 path conversion
  defp convert_to_kv2_write_path(path) do
    # Convert "secret/path" to "secret/data/path" for KV v2
    case String.split(path, "/", parts: 2) do
      [mount] -> "#{mount}/data/"
      [mount, rest] -> "#{mount}/data/#{rest}"
    end
  end

  defp convert_to_kv2_read_path(path) do
    # Convert "secret/path" to "secret/data/path" for KV v2
    case String.split(path, "/", parts: 2) do
      [mount] -> "#{mount}/data/"
      [mount, rest] -> "#{mount}/data/#{rest}"
    end
  end
end