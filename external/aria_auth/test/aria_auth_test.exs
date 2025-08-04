# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaAuthTest do
  use ExUnit.Case

  # Create a test user struct that matches what the Macaroons module expects
  defp create_test_user(id, email, roles) do
    %{
      __struct__: AriaAuth.Accounts.User,
      id: id,
      email: email,
      roles: roles
    }
  end

  test "can generate and verify macaroon tokens" do
    user = create_test_user("test-user-123", "test@example.com", ["user", "admin"])
    assert {:ok, token} = AriaAuth.generate_token(user)

    assert {:ok, %{user_id: "test-user-123", permissions: ["user", "admin"]}} =
             AriaAuth.verify_token(token)
  end

  test "can generate tokens with custom permissions" do
    user = create_test_user("custom-user-456", "custom@example.com", ["user"])
    assert {:ok, token} = AriaAuth.Macaroons.generate_token(user, permissions: ["read", "write"])

    assert {:ok, %{user_id: "custom-user-456", permissions: ["read", "write"]}} =
             AriaAuth.verify_token(token)
  end
end
