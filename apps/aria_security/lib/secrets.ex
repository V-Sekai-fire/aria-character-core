# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaSecurity.Secrets do
  @moduledoc "Security service for managing secrets using OpenBao (open-source Vault alternative).\n\nThis module provides a secure interface for storing and retrieving secrets\nusing OpenBao as the backend. It uses the Vaultex library for communication\nwith OpenBao.\n\n## Configuration\n\nThe module expects OpenBao to be configured with:\n- Host: The OpenBao server hostname\n- Port: The OpenBao server port\n- Scheme: The protocol scheme (http/https)\n- Auth: Authentication configuration with token method\n\n## Examples\n\n    # Initialize connection to OpenBao\n    config = %{\n      host: \"localhost\",\n      port: 8200,\n      scheme: \"http\",\n      auth: %{\n        method: :token,\n        credentials: %{token: \"your-token\"}\n      }\n    }\n    \n    {:ok, status} = AriaSecurity.Secrets.init(config)\n    \n    # Store a secret\n    {:ok, _} = AriaSecurity.Secrets.write(\"secret/myapp\", %{password: \"secret123\"})\n    \n    # Retrieve a secret\n    {:ok, data} = AriaSecurity.Secrets.read(\"secret/myapp\")\n"
  require Logger

  @doc "Initialize connection to OpenBao.\n\n## Parameters\n\n- `config` - A map containing OpenBao configuration:\n  - `:host` - OpenBao server hostname\n  - `:port` - OpenBao server port\n  - `:scheme` - Protocol scheme (\"http\" or \"https\")\n  - `:auth` - Authentication configuration with `:method` and `:credentials`\n\n## Returns\n\n- `{:ok, status}` - Connection successful, returns OpenBao status\n- `{:error, reason}` - Connection failed\n\n## Examples\n\n    config = %{\n      host: \"localhost\",\n      port: 8200,\n      scheme: \"http\",\n      auth: %{\n        method: :token,\n        credentials: %{token: \"dev-token\"}\n      }\n    }\n    \n    {:ok, status} = AriaSecurity.Secrets.init(config)\n"
  def init(config) do
    vault_addr =
      case config do
        %{host: host, port: port, scheme: scheme} -> "#{scheme}://#{host}:#{port}"
        _ -> System.get_env("VAULT_ADDR", "http://localhost:8200")
      end

    case check_vault_health(vault_addr) do
      {:ok, :healthy} ->
        Logger.debug("Vault is healthy")

      {:error, reason} ->
        Logger.debug("Vault health check failed: #{inspect(reason)}")
        Logger.error("Vault health check failed: #{inspect(reason)}")
        {:error, {:vault_unhealthy, reason}}
    end

    vault_token =
      case config do
        %{auth: %{credentials: %{token: token}}} when is_binary(token) -> token
        _ -> System.get_env("VAULT_TOKEN", "")
      end

    Logger.debug("Vault address: #{vault_addr}")
    Logger.debug("Vault token length: #{String.length(vault_token)}")
    Logger.debug("Vault token: #{vault_token}")

    case check_vault_health(vault_addr) do
      {:ok, :healthy} ->
        Logger.debug("OpenBao health check passed")

      {:error, reason} ->
        Logger.debug("OpenBao health check failed: #{inspect(reason)}")
        {:error, {:health_check_failed, reason}}
    end

    Application.put_env(:vaultex, :vault_addr, vault_addr)

    case Application.ensure_all_started(:vaultex) do
      {:ok, apps} ->
        Logger.debug("Started Vaultex apps: #{inspect(apps)}")

        if vault_token != "" do
          Logger.debug("Attempting authentication with token...")

          case Vaultex.Client.auth(:token, {vault_token}) do
            {:ok, response} ->
              Logger.debug("Authentication successful: #{inspect(response)}")
              Logger.info("Successfully authenticated with OpenBao")
              Process.put(:vault_token, vault_token)
              {:ok, %{vault_connected: true}}

            {:error, reason} ->
              Logger.debug("Authentication failed: #{inspect(reason)}")
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

  @doc "Store a secret in OpenBao.\n\n## Parameters\n\n- `path` - The path where the secret will be stored\n- `data` - A map containing the secret data\n\n## Returns\n\n- `{:ok, response}` - Secret stored successfully\n- `{:error, reason}` - Failed to store secret\n\n## Examples\n\n    {:ok, _} = AriaSecurity.Secrets.write(\"secret/myapp\", %{\n      password: \"secret123\",\n      api_key: \"key456\"\n    })\n"
  def write(path, data) when is_binary(path) and is_map(data) do
    vault_token =
      case Process.get(:vault_token) do
        nil -> System.get_env("VAULT_TOKEN", "")
        token -> token
      end

    if vault_token == "" do
      {:error, :no_token}
    else
      kv_path = convert_to_kv2_write_path(path)
      kv_data = %{"data" => data}

      case Vaultex.Client.write(kv_path, kv_data, :token, {vault_token}) do
        :ok -> {:ok, :ok}
        {:ok, response} -> {:ok, response}
        {:error, reason} -> {:error, {:write_failed, reason}}
      end
    end
  rescue
    error -> {:error, {:write_error, error}}
  end

  @doc "Retrieve a secret from OpenBao.\n\n## Parameters\n\n- `path` - The path of the secret to retrieve\n\n## Returns\n\n- `{:ok, data}` - Secret retrieved successfully, returns the secret data\n- `{:error, reason}` - Failed to retrieve secret (e.g., not found)\n\n## Examples\n\n    {:ok, data} = AriaSecurity.Secrets.read(\"secret/myapp\")\n    password = data[\"password\"]\n"
  def read(path) when is_binary(path) do
    vault_token =
      case Process.get(:vault_token) do
        nil -> System.get_env("VAULT_TOKEN", "")
        token -> token
      end

    if vault_token == "" do
      {:error, :no_token}
    else
      kv_path = convert_to_kv2_read_path(path)

      case Vaultex.Client.read(kv_path, :token, {vault_token}) do
        {:ok, nil} ->
          {:error, :not_found}

        {:ok, response} ->
          case response do
            %{"data" => data} when is_map(data) -> {:ok, data}
            _ -> {:ok, response}
          end

        {:error, reason} ->
          {:error, {:read_failed, reason}}
      end
    end
  rescue
    error -> {:error, {:read_error, error}}
  end

  defp check_vault_health(vault_addr) do
    case HTTPoison.get("#{vault_addr}/v1/sys/health") do
      {:ok, %HTTPoison.Response{status_code: status}} when status in [200, 429, 472, 473, 503] ->
        {:ok, :healthy}

      {:ok, response} ->
        Logger.debug("Unexpected health check response: #{inspect(response)}")
        {:error, {:unexpected_response, response}}

      {:error, reason} ->
        Logger.debug("Health check failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp convert_to_kv2_write_path(path) do
    case String.split(path, "/", parts: 2) do
      [mount] -> "#{mount}/data/"
      [mount, rest] -> "#{mount}/data/#{rest}"
    end
  end

  defp convert_to_kv2_read_path(path) do
    case String.split(path, "/", parts: 2) do
      [mount] -> "#{mount}/data/"
      [mount, rest] -> "#{mount}/data/#{rest}"
    end
  end
end
