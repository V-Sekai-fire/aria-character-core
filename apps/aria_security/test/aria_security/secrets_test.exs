# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaSecurity.SecretsTest do
  use ExUnit.Case, async: true

  alias AriaSecurity.SecretsInterface, as: Secrets
  alias AriaSecurity.SecretsMock

  setup do
    # Start the mock for each test if not already running
    case GenServer.whereis(SecretsMock) do
      nil -> SecretsMock.start_link()
      _pid -> :ok
    end

    # Clear any existing data
    SecretsMock.clear_all()

    on_exit(fn ->
      # Only stop if the process exists and is alive
      case GenServer.whereis(SecretsMock) do
        nil -> :ok
        pid when is_pid(pid) -> 
          if Process.alive?(pid) do
            SecretsMock.stop()
          end
        _ -> :ok
      end
    end)

    :ok
  end

  describe "Security Service - OpenBao integration via Vaultex" do
    test "can initialize connection to OpenBao" do
      # Given: OpenBao is configured via valid_config
      config = valid_config()

      # When: We attempt to initialize the connection
      result = Secrets.init(config)

      # Then: The connection should be established successfully
      assert {:ok, _status} = result
    end

    test "fails gracefully when OpenBao is unavailable" do
      # Given: Invalid configuration
      config = %{
        # Missing required fields to test failure
      }

      # When: We attempt to initialize the connection
      result = Secrets.init(config)

      # Then: It should return a connection error
      assert {:error, _reason} = result
    end

    test "can store and retrieve a secret" do
      # Given: A connected OpenBao instance
      config = valid_config()
      {:ok, _status} = Secrets.init(config)

      secret_path = "secret/aria/test/database"
      secret_data = %{
        username: "test_user",
        password: "super_secret_password"
      }

      # When: We store a secret
      store_result = Secrets.write(secret_path, secret_data)

      # Then: The secret should be stored successfully
      assert {:ok, _response} = store_result

      # And When: We retrieve the secret
      get_result = Secrets.read(secret_path)

      # Then: We should get back the same data
      assert {:ok, retrieved_data} = get_result
      assert retrieved_data["username"] == "test_user"
      assert retrieved_data["password"] == "super_secret_password"
    end

    test "returns error for non-existent secret" do
      # Given: A connected OpenBao instance
      config = valid_config()
      {:ok, _status} = Secrets.init(config)

      # When: We try to get a non-existent secret
      result = Secrets.read("secret/aria/nonexistent/secret")

      # Then: It should return not found
      assert {:error, _reason} = result
    end
  end

  defp valid_config do
    # Simple mock configuration
    %{
      host: "localhost",
      port: 8200,
      scheme: "http",
      auth: %{
        method: :token,
        credentials: %{
          token: "mock-token"
        }
      }
    }
  end
end
