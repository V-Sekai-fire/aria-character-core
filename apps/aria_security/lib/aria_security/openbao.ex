# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaSecurity.OpenBao do
  @moduledoc """
  OpenBao integration module with SoftHSM PKCS#11 seal support.

  This module provides high-level operations for managing OpenBao with
  Hardware Security Module (HSM) seal integration using SoftHSM.
  """

  require Logger
  alias AriaSecurity.SoftHSM

  defstruct [
    :address,
    :token,
    :hsm_config,
    :seal_config,
    :client_config
  ]

  @type t :: %__MODULE__{
    address: String.t(),
    token: String.t() | nil,
    hsm_config: SoftHSM.t(),
    seal_config: map(),
    client_config: map()
  }

  @default_address "http://localhost:8200"
  @default_seal_config %{
    lib: "/usr/lib64/pkcs11/libsofthsm2.so",
    slot: "0",
    pin: "1234",
    key_label: "openbao-seal-key",
    mechanism: "0x00000009"  # CKM_RSA_PKCS
  }

  @doc """
  Creates a new OpenBao client configuration with SoftHSM integration.

  ## Options

  * `:address` - OpenBao server address (default: #{@default_address})
  * `:token` - OpenBao authentication token
  * `:hsm_config` - SoftHSM configuration struct
  * `:seal_config` - PKCS#11 seal configuration

  ## Examples

      iex> hsm = AriaSecurity.SoftHSM.new()
      iex> AriaSecurity.OpenBao.new(hsm_config: hsm)
      %AriaSecurity.OpenBao{address: "http://localhost:8200", ...}
  """
  def new(opts \\ []) do
    hsm_config = Keyword.get(opts, :hsm_config, SoftHSM.new())

    %__MODULE__{
      address: Keyword.get(opts, :address, @default_address),
      token: Keyword.get(opts, :token),
      hsm_config: hsm_config,
      seal_config: Keyword.get(opts, :seal_config, @default_seal_config),
      client_config: %{
        vault_addr: Keyword.get(opts, :address, @default_address),
        vault_token: Keyword.get(opts, :token)
      }
    }
  end

  @doc """
  Initializes OpenBao with SoftHSM seal support.

  This sets up both the SoftHSM token and initializes OpenBao to use it for seal operations.

  ## Examples

      iex> bao = AriaSecurity.OpenBao.new()
      iex> AriaSecurity.OpenBao.initialize_with_hsm(bao)
      {:ok, %{root_token: "...", unseal_keys: [...], hsm_slot: 0}}
  """
  def initialize_with_hsm(%__MODULE__{} = bao) do
    Logger.info("Initializing OpenBao with SoftHSM seal")

    with {:ok, hsm_result} <- SoftHSM.initialize_token(bao.hsm_config),
         {:ok, _keypair_result} <- SoftHSM.generate_rsa_keypair(bao.hsm_config),
         {:ok, init_result} <- initialize_openbao(bao) do

      Logger.info("OpenBao initialized successfully with HSM seal")

      {:ok, %{
        root_token: init_result.root_token,
        unseal_keys: init_result.unseal_keys,
        hsm_slot: hsm_result.slot,
        recovery_keys: init_result.recovery_keys
      }}
    else
      {:error, reason} ->
        Logger.error("Failed to initialize OpenBao with HSM: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Checks if OpenBao is initialized.

  ## Examples

      iex> bao = AriaSecurity.OpenBao.new()
      iex> AriaSecurity.OpenBao.initialized?(bao)
      {:ok, true}
  """
  def initialized?(%__MODULE__{} = bao) do
    case HTTPoison.get("#{bao.address}/v1/sys/init") do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"initialized" => initialized}} ->
            {:ok, initialized}
          {:error, reason} ->
            {:error, {:json_decode_error, reason}}
        end

      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        {:error, {:http_error, status_code}}

      {:error, reason} ->
        {:error, {:network_error, reason}}
    end
  end

  @doc """
  Checks if OpenBao is sealed.

  ## Examples

      iex> bao = AriaSecurity.OpenBao.new()
      iex> AriaSecurity.OpenBao.sealed?(bao)
      {:ok, false}
  """
  def sealed?(%__MODULE__{} = bao) do
    case HTTPoison.get("#{bao.address}/v1/sys/seal-status") do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"sealed" => sealed}} ->
            {:ok, sealed}
          {:error, reason} ->
            {:error, {:json_decode_error, reason}}
        end

      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        {:error, {:http_error, status_code}}

      {:error, reason} ->
        {:error, {:network_error, reason}}
    end
  end

  @doc """
  Gets OpenBao health status.

  ## Examples

      iex> bao = AriaSecurity.OpenBao.new()
      iex> AriaSecurity.OpenBao.health(bao)
      {:ok, %{"initialized" => true, "sealed" => false, ...}}
  """
  def health(%__MODULE__{} = bao) do
    case HTTPoison.get("#{bao.address}/v1/sys/health") do
      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} when status_code in [200, 429, 472, 473, 501] ->
        case Jason.decode(body) do
          {:ok, health_data} ->
            {:ok, health_data}
          {:error, reason} ->
            {:error, {:json_decode_error, reason}}
        end

      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        {:error, {:http_error, status_code}}

      {:error, reason} ->
        {:error, {:network_error, reason}}
    end
  end

  @doc """
  Stores a secret in OpenBao.

  ## Examples

      iex> bao = AriaSecurity.OpenBao.new(token: "root")
      iex> AriaSecurity.OpenBao.write_secret(bao, "secret/mykey", %{"password" => "secret"})
      {:ok, %{"data" => %{"password" => "secret"}}}
  """
  def write_secret(%__MODULE__{token: nil}, _path, _data) do
    {:error, :no_token}
  end

  def write_secret(%__MODULE__{} = bao, path, data) do
    headers = [
      {"X-Vault-Token", bao.token},
      {"Content-Type", "application/json"}
    ]

    # OpenBao KV v2 format
    payload = %{"data" => data}

    case HTTPoison.post("#{bao.address}/v1/#{path}", Jason.encode!(payload), headers) do
      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} when status_code in [200, 204] ->
        case Jason.decode(body) do
          {:ok, response_data} ->
            {:ok, response_data}
          {:error, _} ->
            {:ok, %{}}  # No response body for some writes
        end

      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        Logger.error("Failed to write secret: #{status_code} - #{body}")
        {:error, {:http_error, status_code, body}}

      {:error, reason} ->
        {:error, {:network_error, reason}}
    end
  end

  @doc """
  Reads a secret from OpenBao.

  ## Examples

      iex> bao = AriaSecurity.OpenBao.new(token: "root")
      iex> AriaSecurity.OpenBao.read_secret(bao, "secret/data/mykey")
      {:ok, %{"data" => %{"data" => %{"password" => "secret"}}}}
  """
  def read_secret(%__MODULE__{token: nil}, _path) do
    {:error, :no_token}
  end

  def read_secret(%__MODULE__{} = bao, path) do
    headers = [{"X-Vault-Token", bao.token}]

    case HTTPoison.get("#{bao.address}/v1/#{path}", headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, response_data} ->
            {:ok, response_data}
          {:error, reason} ->
            {:error, {:json_decode_error, reason}}
        end

      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {:error, :not_found}

      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        Logger.error("Failed to read secret: #{status_code} - #{body}")
        {:error, {:http_error, status_code, body}}

      {:error, reason} ->
        {:error, {:network_error, reason}}
    end
  end

  @doc """
  Retrieves the OpenBao root token from container storage.

  This is useful when OpenBao has been initialized and the token is stored
  in the container's persistent volume.

  ## Examples

      iex> bao = AriaSecurity.OpenBao.new()
      iex> AriaSecurity.OpenBao.get_root_token(bao)
      {:ok, "hvs.1234567890"}
  """
  def get_root_token(%__MODULE__{} = bao) do
    # Try to get token from container storage
    case System.cmd("docker", ["exec", "aria-character-core-openbao-1", "cat", "/vault/data/root_token.txt"], stderr_to_stdout: true) do
      {token, 0} ->
        clean_token = String.trim(token)
        if String.length(clean_token) > 0 do
          Logger.info("Retrieved OpenBao root token from container storage")
          {:ok, clean_token}
        else
          {:error, :empty_token}
        end

      {error, exit_code} ->
        Logger.warn("Could not retrieve token from container: #{error}")
        {:error, {:container_access_failed, exit_code, error}}
    end
  end

  @doc """
  Updates the OpenBao client with a new token.

  ## Examples

      iex> bao = AriaSecurity.OpenBao.new()
      iex> AriaSecurity.OpenBao.set_token(bao, "hvs.1234567890")
      %AriaSecurity.OpenBao{token: "hvs.1234567890", ...}
  """
  def set_token(%__MODULE__{} = bao, token) do
    %{bao |
      token: token,
      client_config: Map.put(bao.client_config, :vault_token, token)
    }
  end

  # Private helper functions

  defp initialize_openbao(%__MODULE__{} = bao) do
    # Initialize OpenBao with recovery keys (for HSM seal)
    payload = %{
      recovery_shares: 5,
      recovery_threshold: 3
    }

    headers = [{"Content-Type", "application/json"}]

    case HTTPoison.put("#{bao.address}/v1/sys/init", Jason.encode!(payload), headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"root_token" => root_token, "recovery_keys" => recovery_keys} = response} ->
            Logger.info("OpenBao initialized with HSM seal successfully")

            {:ok, %{
              root_token: root_token,
              recovery_keys: recovery_keys,
              unseal_keys: []  # Not needed with HSM seal
            }}

          {:error, reason} ->
            {:error, {:json_decode_error, reason}}
        end

      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        Logger.error("Failed to initialize OpenBao: #{status_code} - #{body}")
        {:error, {:initialization_failed, status_code, body}}

      {:error, reason} ->
        {:error, {:network_error, reason}}
    end
  end
end
