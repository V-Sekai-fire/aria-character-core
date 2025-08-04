# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaSecurityTest do
  use ExUnit.Case
  doctest AriaSecurity

  test "module delegates to AriaSecurity.Secrets" do
    # Test that the main module properly delegates to the Secrets module
    # We'll use a mock config that should fail gracefully
    config = %{
      host: "nonexistent",
      port: 8200,
      scheme: "http",
      auth: %{
        method: :token,
        credentials: %{token: "test-token"}
      }
    }

    # This should return an error since we're not connecting to a real vault
    result = AriaSecurity.init(config)
    assert {:error, _reason} = result
  end

  test "read and write functions are available" do
    # Test that the functions are properly delegated
    assert function_exported?(AriaSecurity, :read, 1)
    assert function_exported?(AriaSecurity, :write, 2)
    assert function_exported?(AriaSecurity, :init, 1)
  end
end
