# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaAuthTest do
  use ExUnit.Case
  doctest AriaAuth

  alias AriaAuth.Accounts.User

  test "can generate and verify macaroon tokens" do
    user = %User{
      id: "test-user-123",
      email: "test@example.com",
      roles: ["user", "admin"]
    }

    # Test basic token generation and verification
    assert {:ok, token} = AriaAuth.generate_token(user)
    assert {:ok, %{user_id: "test-user-123", permissions: ["user", "admin"]}} = 
      AriaAuth.verify_token(token)
  end

  test "can generate tokens with custom permissions" do
    user = %User{
      id: "custom-user-456", 
      email: "custom@example.com",
      roles: ["user"]
    }

    # Generate token with custom permissions
    assert {:ok, token} = AriaAuth.Macaroons.generate_token(user, permissions: ["read", "write"])
    assert {:ok, %{user_id: "custom-user-456", permissions: ["read", "write"]}} = 
      AriaAuth.verify_token(token)
  end
end

