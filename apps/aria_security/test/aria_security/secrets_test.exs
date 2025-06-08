defmodule AriaSecurity.SecretsTest do
  use ExUnit.Case, async: true
  
  alias AriaSecurity.Secrets
  
  describe "Security Service - OpenBao integration" do
    test "can initialize connection to OpenBao" do
      # Given: OpenBao is configured with basic settings
      config = %{
        url: "http://localhost:8200",
        token: "test-token",
        namespace: "aria"
      }
      
      # When: We attempt to initialize the connection
      result = Secrets.init(config)
      
      # Then: The connection should be established successfully
      assert {:ok, %{status: :connected, version: _version}} = result
    end
    
    test "fails gracefully when OpenBao is unavailable" do
      # Given: OpenBao is not running or unreachable
      config = %{
        url: "http://localhost:9999",  # Wrong port
        token: "test-token",
        namespace: "aria"
      }
      
      # When: We attempt to initialize the connection
      result = Secrets.init(config)
      
      # Then: It should return a connection error
      assert {:error, :connection_failed} = result
    end
    
    test "can store and retrieve a secret" do
      # Given: A connected OpenBao instance
      config = valid_config()
      {:ok, _conn} = Secrets.init(config)
      
      secret_path = "aria/test/database"
      secret_data = %{
        username: "test_user",
        password: "super_secret_password"
      }
      
      # When: We store a secret
      store_result = Secrets.put(secret_path, secret_data)
      
      # Then: The secret should be stored successfully
      assert {:ok, _metadata} = store_result
      
      # And When: We retrieve the secret
      get_result = Secrets.get(secret_path)
      
      # Then: We should get back the same data
      assert {:ok, ^secret_data} = get_result
    end
    
    test "returns error for non-existent secret" do
      # Given: A connected OpenBao instance
      config = valid_config()
      {:ok, _conn} = Secrets.init(config)
      
      # When: We try to get a non-existent secret
      result = Secrets.get("aria/nonexistent/secret")
      
      # Then: It should return not found
      assert {:error, :not_found} = result
    end
  end
  
  defp valid_config do
    %{
      url: System.get_env("OPENBAO_URL", "http://localhost:8200"),
      token: System.get_env("OPENBAO_TOKEN", "dev-token"),
      namespace: "aria"
    }
  end
end