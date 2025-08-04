# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaSecurity.OpenBao do
  @moduledoc "OpenBao integration module with SoftHSM PKCS#11 seal support.\n\nThis module provides high-level operations for managing OpenBao with\nHardware Security Module (HSM) seal integration using SoftHSM.\n"
  require Logger
  alias AriaSecurity.SoftHSM
  defstruct [:address, :token, :hsm_config, :seal_config, :client_config]

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
    mechanism: "0x00000009"
  }
  @doc "Creates a new OpenBao client configuration with SoftHSM integration.

## Options

* `:address` - OpenBao server address (default: #{@default_address})
* `:token` - OpenBao authentication token
* `:hsm_config` - SoftHSM configuration struct
* `:seal_config` - PKCS#11 seal configuration

## Examples

    iex> hsm = AriaSecurity.SoftHSM.new()
    iex> AriaSecurity.OpenBao.new(hsm_config: hsm)
    %AriaSecurity.OpenBao{address: \"http://localhost:8200\", ...}
"
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

  @doc "Initializes OpenBao with SoftHSM seal support.\n\nThis sets up both the SoftHSM token and initializes OpenBao to use it for seal operations.\n\n## Examples\n\n    iex> bao = AriaSecurity.OpenBao.new()\n    iex> AriaSecurity.OpenBao.initialize_with_hsm(bao)\n    {:ok, %{root_token: \"...\", unseal_keys: [...], hsm_slot: 0}}\n"
  def initialize_with_hsm(%__MODULE__{} = bao) do
    Logger.info("Initializing OpenBao with SoftHSM seal")

    with {:ok, hsm_result} <- SoftHSM.initialize_token(bao.hsm_config),
         {:ok, _keypair_result} <- SoftHSM.generate_rsa_keypair(bao.hsm_config),
         {:ok, init_result} <- initialize_openbao(bao) do
      Logger.info("OpenBao initialized successfully with HSM seal")

      {:ok,
       %{
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

  @doc "Checks if OpenBao is initialized.\n\n## Examples\n\n    iex> bao = AriaSecurity.OpenBao.new()\n    iex> AriaSecurity.OpenBao.initialized?(bao)\n    {:ok, true}\n"
  def initialized?(%__MODULE__{} = bao) do
    case HTTPoison.get("#{bao.address}/v1/sys/init") do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"initialized" => initialized}} -> {:ok, initialized}
          {:error, reason} -> {:error, {:json_decode_error, reason}}
        end

      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        {:error, {:http_error, status_code}}

      {:error, reason} ->
        {:error, {:network_error, reason}}
    end
  end

  @doc "Checks if OpenBao is sealed.\n\n## Examples\n\n    iex> bao = AriaSecurity.OpenBao.new()\n    iex> AriaSecurity.OpenBao.sealed?(bao)\n    {:ok, false}\n"
  def sealed?(%__MODULE__{} = bao) do
    case HTTPoison.get("#{bao.address}/v1/sys/seal-status") do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"sealed" => sealed}} -> {:ok, sealed}
          {:error, reason} -> {:error, {:json_decode_error, reason}}
        end

      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        {:error, {:http_error, status_code}}

      {:error, reason} ->
        {:error, {:network_error, reason}}
    end
  end

  @doc "Gets OpenBao health status.\n\n## Examples\n\n    iex> bao = AriaSecurity.OpenBao.new()\n    iex> AriaSecurity.OpenBao.health(bao)\n    {:ok, %{\"initialized\" => true, \"sealed\" => false, ...}}\n"
  def health(%__MODULE__{} = bao) do
    case HTTPoison.get("#{bao.address}/v1/sys/health") do
      {:ok, %HTTPoison.Response{status_code: status_code, body: body}}
      when status_code in [200, 429, 472, 473, 501] ->
        case Jason.decode(body) do
          {:ok, health_data} -> {:ok, health_data}
          {:error, reason} -> {:error, {:json_decode_error, reason}}
        end

      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        {:error, {:http_error, status_code}}

      {:error, reason} ->
        {:error, {:network_error, reason}}
    end
  end

  @doc "Stores a secret in OpenBao.\n\n## Examples\n\n    iex> bao = AriaSecurity.OpenBao.new(token: \"root\")\n    iex> AriaSecurity.OpenBao.write_secret(bao, \"secret/mykey\", %{\"password\" => \"secret\"})\n    {:ok, %{\"data\" => %{\"password\" => \"secret\"}}}\n"
  def write_secret(%__MODULE__{token: nil}, _path, _data) do
    {:error, :no_token}
  end

  def write_secret(%__MODULE__{} = bao, path, data) do
    headers = [{"X-Vault-Token", bao.token}, {"Content-Type", "application/json"}]
    payload = %{"data" => data}

    case HTTPoison.post("#{bao.address}/v1/#{path}", Jason.encode!(payload), headers) do
      {:ok, %HTTPoison.Response{status_code: status_code, body: body}}
      when status_code in [200, 204] ->
        case Jason.decode(body) do
          {:ok, response_data} -> {:ok, response_data}
          {:error, _} -> {:ok, %{}}
        end

      {:ok, %HTTPoison.Response{status_code: status_code, body: body}} ->
        Logger.error("Failed to write secret: #{status_code} - #{body}")
        {:error, {:http_error, status_code, body}}

      {:error, reason} ->
        {:error, {:network_error, reason}}
    end
  end

  @doc "Reads a secret from OpenBao.\n\n## Examples\n\n    iex> bao = AriaSecurity.OpenBao.new(token: \"root\")\n    iex> AriaSecurity.OpenBao.read_secret(bao, \"secret/data/mykey\")\n    {:ok, %{\"data\" => %{\"data\" => %{\"password\" => \"secret\"}}}}\n"
  def read_secret(%__MODULE__{token: nil}, _path) do
    {:error, :no_token}
  end

  def read_secret(%__MODULE__{} = bao, path) do
    headers = [{"X-Vault-Token", bao.token}]

    case HTTPoison.get("#{bao.address}/v1/#{path}", headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, response_data} -> {:ok, response_data}
          {:error, reason} -> {:error, {:json_decode_error, reason}}
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

  @doc "Retrieves the OpenBao root token from container storage.\n\nThis is useful when OpenBao has been initialized and the token is stored\nin the container's persistent volume.\n\n## Examples\n\n    iex> bao = AriaSecurity.OpenBao.new()\n    iex> AriaSecurity.OpenBao.get_root_token(bao)\n    {:ok, \"hvs.1234567890\"}\n"
  def get_root_token(%__MODULE__{} = _bao) do
    token_file = "/opt/bao/data/root_token.txt"

    case File.read(token_file) do
      {:ok, token} ->
        clean_token = String.trim(token)

        if String.length(clean_token) > 0 do
          Logger.info("Retrieved OpenBao root token from native storage")
          {:ok, clean_token}
        else
          {:error, :empty_token}
        end

      {:error, reason} ->
        Logger.warning("Could not retrieve token from file #{token_file}: #{reason}")
        {:error, {:file_access_failed, reason}}
    end
  end

  @doc "Updates the OpenBao client with a new token.\n\n## Examples\n\n    iex> bao = AriaSecurity.OpenBao.new()\n    iex> AriaSecurity.OpenBao.set_token(bao, \"hvs.1234567890\")\n    %AriaSecurity.OpenBao{token: \"hvs.1234567890\", ...}\n"
  def set_token(%__MODULE__{} = bao, token) do
    %{bao | token: token, client_config: Map.put(bao.client_config, :vault_token, token)}
  end

  defp initialize_openbao(%__MODULE__{} = bao) do
    payload = %{recovery_shares: 5, recovery_threshold: 3}
    headers = [{"Content-Type", "application/json"}]

    case HTTPoison.put("#{bao.address}/v1/sys/init", Jason.encode!(payload), headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"root_token" => root_token, "recovery_keys" => recovery_keys} = _response} ->
            Logger.info("OpenBao initialized with HSM seal successfully")
            {:ok, %{root_token: root_token, recovery_keys: recovery_keys, unseal_keys: []}}

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
