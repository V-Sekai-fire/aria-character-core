# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaSecurity.SecretsTest do
  use ExUnit.Case, async: true
  
  alias AriaSecurity.Secrets
  
  describe "Security Service - OpenBao integration via Vaultex" do
    test "can initialize connection to OpenBao" do
      # Given: OpenBao is configured via valid_config (uses ENV variables)
      config = valid_config()
      
      # When: We attempt to initialize the connection
      result = Secrets.init(config)
      
      # Then: The connection should be established successfully
      assert {:ok, _status} = result
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
    # Try multiple paths to find the token file
    token_paths = [
      "../../.ci/openbao_root_token.txt",
      ".ci/openbao_root_token.txt",
      "/tmp/openbao_root_token.txt"
    ]
    
    token = Enum.find_value(token_paths, fn path ->
      case File.read(path) do
        {:ok, content} -> 
          IO.puts("DEBUG: Found token file at #{path}")
          IO.puts("DEBUG: Token file content: #{inspect(content)}")
          
          # Extract token from "openbao-1  | Root Token: root" format
          extracted = content
          |> String.trim()
          |> String.split("Root Token: ")
          |> List.last()
          |> String.trim()
          
          IO.puts("DEBUG: Extracted token: #{inspect(extracted)}")
          extracted
        {:error, reason} -> 
          IO.puts("DEBUG: Failed to read #{path}: #{inspect(reason)}")
          nil
      end
    end)
    
    # Fallback to environment variable or default
    final_token = token || System.get_env("OPENBAO_TOKEN", "dev-token")
    IO.puts("DEBUG: Final token to use: #{inspect(final_token)}")
    
    config = %{
      host: System.get_env("OPENBAO_HOST", "localhost"),
      port: String.to_integer(System.get_env("OPENBAO_PORT", "8200")),
      scheme: System.get_env("OPENBAO_SCHEME", "http"),
      auth: %{
        method: :token, 
        credentials: %{
          token: final_token
        }
      }
    }
    
    IO.puts("DEBUG: Final config: #{inspect(config)}")
    config
  end
end