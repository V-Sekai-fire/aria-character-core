# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaSecurity.SecretsTest do
  use ExUnit.Case, async: true
  
  alias AriaSecurity.Secrets
  
  describe "Security Service - OpenBao integration via Vaultex" do
    test "can initialize connection to OpenBao" do
      # Given: OpenBao is configured with basic settings
      config = %{
        host: "localhost",
        port: 8200,
        scheme: "http",
        auth: %{method: :token, credentials: %{token: "test-token"}}
      }
      
      # When: We attempt to initialize the connection
      result = Secrets.init(config)
      
      # Then: The connection should be established successfully
      assert {:ok, %{authenticated: true}} = result
    end
    
    test "fails gracefully when OpenBao is unavailable" do
      # Given: OpenBao is not running or unreachable
      config = %{
        host: "localhost",
        port: 9999,  # Wrong port
        scheme: "http",
        auth: %{method: :token, credentials: %{token: "test-token"}}
      }
      
      # When: We attempt to initialize the connection
      result = Secrets.init(config)
      
      # Then: It should return a connection error
      assert {:error, :connection_failed} = result
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
      assert {:error, ["Key not found"]} = result
    end
  end
  
  defp valid_config do
    %{
      host: System.get_env("OPENBAO_HOST", "localhost"),
      port: String.to_integer(System.get_env("OPENBAO_PORT", "8200")),
      scheme: System.get_env("OPENBAO_SCHEME", "http"),
      auth: %{
        method: :token, 
        credentials: %{
          token: System.get_env("OPENBAO_TOKEN", "dev-token")
        }
      }
    }
  end
end