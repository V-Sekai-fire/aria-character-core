# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaAuth.MacaroonsTest do
  use ExUnit.Case, async: true
  
  alias AriaAuth.Macaroons
  alias AriaAuth.Accounts.User
  alias Macaroons.{PermissionsCaveat, ConfineUserString}
  alias Macfly.Caveat.ValidityWindow
  
  describe "ConfineUserString caveat" do
    test "can build caveat with string user ID" do
      user_id = "test-user-123"
      caveat = ConfineUserString.build(user_id)
      
      assert %ConfineUserString{id: ^user_id} = caveat
    end
    
    test "implements Macfly.Caveat protocol correctly" do
      user_id = "protocol-test-user"
      caveat = ConfineUserString.build(user_id)
      
      assert Macfly.Caveat.name(caveat) == "ConfineUserString"
      assert Macfly.Caveat.type(caveat) == 101
      assert Macfly.Caveat.body(caveat) == [user_id]
    end
    
    test "can roundtrip through protocol body/from_body" do
      user_id = "roundtrip-user"
      caveat = ConfineUserString.build(user_id)
      
      body = Macfly.Caveat.body(caveat)
      assert {:ok, reconstructed} = Macfly.Caveat.from_body(caveat, body, nil)
      assert reconstructed == caveat
    end
    
    test "from_body handles invalid format" do
      caveat = ConfineUserString.build("test")
      assert {:error, "bad ConfineUserString format"} = 
        Macfly.Caveat.from_body(caveat, ["invalid", "format"], nil)
    end
  end
  
  describe "PermissionsCaveat" do
    test "can build permissions caveat with list of permissions" do
      permissions = ["read", "write", "admin"]
      caveat = PermissionsCaveat.build(permissions)
      
      assert %PermissionsCaveat{permissions: ^permissions} = caveat
    end
    
    test "can build permissions caveat with empty list" do
      permissions = []
      caveat = PermissionsCaveat.build(permissions)
      
      assert %PermissionsCaveat{permissions: []} = caveat
    end
    
    test "implements Macfly.Caveat protocol correctly" do
      permissions = ["user", "editor"]
      caveat = PermissionsCaveat.build(permissions)
      
      assert Macfly.Caveat.name(caveat) == "PermissionsCaveat"
      assert Macfly.Caveat.type(caveat) == 100
      assert Macfly.Caveat.body(caveat) == [permissions]
    end
    
    test "can roundtrip through protocol body/from_body" do
      permissions = ["admin", "moderator"]
      caveat = PermissionsCaveat.build(permissions)
      
      body = Macfly.Caveat.body(caveat)
      assert {:ok, reconstructed} = Macfly.Caveat.from_body(caveat, body, nil)
      assert reconstructed == caveat
    end
    
    test "from_body handles invalid format" do
      caveat = PermissionsCaveat.build(["test"])
      assert {:error, "bad PermissionsCaveat format"} = 
        Macfly.Caveat.from_body(caveat, "invalid", nil)
    end
  end
  
  describe "custom caveat serialization and deserialization" do
    test "custom caveats survive macaroon encoding/decoding cycle" do
      user = %User{
        id: "caveat-test-user",
        email: "caveat@example.com",
        roles: ["user", "editor"]
      }
      
      {:ok, token} = Macaroons.generate_token(user)
      
      # Decode the token to examine caveats - need to register custom caveats
      options = Macfly.Options.with_caveats(
        %Macfly.Options{},
        [AriaAuth.Macaroons.PermissionsCaveat, AriaAuth.Macaroons.ConfineUserString]
      )
      {:ok, [macaroon]} = Macfly.decode(token, options)
      
      # Check that our custom caveats are present
      user_caveat = Enum.find(macaroon.caveats, fn caveat ->
        match?(%ConfineUserString{}, caveat)
      end)
      
      perms_caveat = Enum.find(macaroon.caveats, fn caveat ->
        match?(%PermissionsCaveat{}, caveat)
      end)
      
      validity_caveat = Enum.find(macaroon.caveats, fn caveat ->
        match?(%ValidityWindow{}, caveat)
      end)
      
      assert user_caveat != nil, "ConfineUserString caveat should be present"
      assert perms_caveat != nil, "PermissionsCaveat should be present"
      assert validity_caveat != nil, "ValidityWindow caveat should be present"
      
      assert user_caveat.id == "caveat-test-user"
      assert perms_caveat.permissions == ["user", "editor"]
    end
    
    test "can verify tokens with custom caveats" do
      user = %User{
        id: "verification-test-user",
        email: "verification@example.com",
        roles: ["admin", "user"]
      }
      
      {:ok, token} = Macaroons.generate_token(user, permissions: ["read", "write"])
      
      assert {:ok, %{user_id: "verification-test-user", permissions: ["read", "write"]}} = 
        Macaroons.verify_token(token)
    end
  end
  
  describe "generate_token/2" do
    test "generates token with default user roles as permissions" do
      user = %User{
        id: "user-123",
        email: "test@example.com", 
        roles: ["user", "editor"]
      }
      
      assert {:ok, token} = Macaroons.generate_token(user)
      assert is_binary(token)
      
      # Verify the token contains the expected permissions
      assert {:ok, %{user_id: "user-123", permissions: ["user", "editor"]}} = 
        Macaroons.verify_token(token)
    end
    
    test "generates token with custom permissions" do
      user = %User{
        id: "user-456",
        email: "test@example.com",
        roles: ["user", "editor"]
      }
      
      custom_permissions = ["read", "write"]
      assert {:ok, token} = Macaroons.generate_token(user, permissions: custom_permissions)
      
      # Verify the token contains the custom permissions
      assert {:ok, %{user_id: "user-456", permissions: ["read", "write"]}} = 
        Macaroons.verify_token(token)
    end
    
    test "generates token with empty permissions list" do
      user = %User{
        id: "user-789",
        email: "test@example.com",
        roles: ["user"]
      }
      
      assert {:ok, token} = Macaroons.generate_token(user, permissions: [])
      
      # Verify the token contains empty permissions
      assert {:ok, %{user_id: "user-789", permissions: []}} = 
        Macaroons.verify_token(token)
    end
    
    test "generates token with custom expiry and permissions" do
      user = %User{
        id: "user-abc",
        email: "test@example.com",
        roles: ["admin"]
      }
      
      assert {:ok, token} = Macaroons.generate_token(user, 
        expiry: 900, 
        permissions: ["admin", "superuser"]
      )
      
      assert {:ok, %{user_id: "user-abc", permissions: ["admin", "superuser"]}} = 
        Macaroons.verify_token(token)
    end
  end
  
  describe "verify_token/1" do
    test "returns user_id and permissions from valid token" do
      user = %User{
        id: "verify-user-123",
        email: "verify@example.com",
        roles: ["user", "moderator"]
      }
      
      {:ok, token} = Macaroons.generate_token(user)
      
      assert {:ok, %{user_id: "verify-user-123", permissions: ["user", "moderator"]}} = 
        Macaroons.verify_token(token)
    end
    
    test "handles token with no permissions caveat gracefully" do
      user = %User{
        id: "no-perms-user",
        email: "noperms@example.com",
        roles: ["user"]
      }
      
      {:ok, token} = Macaroons.generate_token(user, permissions: [])
      
      assert {:ok, %{user_id: "no-perms-user", permissions: []}} = 
        Macaroons.verify_token(token)
    end
    
    test "returns error for invalid token" do
      assert {:error, _reason} = Macaroons.verify_token("invalid-token")
    end
    
    test "returns error for malformed token" do
      assert {:error, _reason} = Macaroons.verify_token("malformed.token.data")
    end
  end
  
  describe "verify_token_and_get_user/1" do
    # Note: These tests focus on the token verification part
    # Full integration tests would require database setup
    
    test "token verification succeeds but user lookup depends on database" do
      # Use a proper binary UUID instead of a string to match User schema
      user_id = Ecto.UUID.generate()
      mock_user = %User{
        id: user_id,
        email: "mock@example.com",
        roles: ["user", "tester"]
      }
      
      {:ok, token} = Macaroons.generate_token(mock_user)
      
      # First verify that the token can be decoded and contains correct user_id
      assert {:ok, %{user_id: ^user_id, permissions: ["user", "tester"]}} = 
        Macaroons.verify_token(token)
      
      # The verify_token_and_get_user function will fail because it tries to query
      # the database, but that's expected in unit tests without database setup
      # In a full integration test, this would work with proper test database
      result = Macaroons.verify_token_and_get_user(token)
      
      # We expect this to fail with a database-related error since we don't have
      # the user in the test database, but the token verification part should work
      assert match?({:error, _}, result)
    end
    
    test "returns error for invalid token" do
      result = Macaroons.verify_token_and_get_user("invalid-token")
      assert match?({:error, _}, result)
    end
  end
  
  describe "attenuate_token/2" do
    test "can attenuate token with additional permissions restrictions" do
      user = %User{
        id: "attenuate-user",
        email: "attenuate@example.com",
        roles: ["admin", "user", "editor"]
      }
      
      {:ok, original_token} = Macaroons.generate_token(user)
      
      # Create a restricted permissions caveat
      restricted_permissions = Macaroons.PermissionsCaveat.build(["user"])
      
      assert {:ok, attenuated_token} = 
        Macaroons.attenuate_token(original_token, [restricted_permissions])
      
      # The attenuated token should have additional restriction
      # Note: In a full implementation, we'd need caveat satisfaction logic
      # For now, we just verify the token can be decoded
      assert {:ok, _result} = Macaroons.verify_token(attenuated_token)
    end
    
    test "returns error for invalid token during attenuation" do
      restricted_permissions = Macaroons.PermissionsCaveat.build(["user"])
      
      assert {:error, _reason} = 
        Macaroons.attenuate_token("invalid-token", [restricted_permissions])
    end
  end
  
  describe "generate_token_pair/1" do
    test "generates access and refresh tokens with different permissions" do
      user = %User{
        id: "pair-user",
        email: "pair@example.com",
        roles: ["user"]
      }
      
      assert {:ok, %{access_token: access_token, refresh_token: refresh_token}} = 
        Macaroons.generate_token_pair(user)
      
      # Both tokens should be valid but have different permissions
      assert {:ok, %{permissions: ["access"]}} = Macaroons.verify_token(access_token)
      assert {:ok, %{permissions: ["refresh"]}} = Macaroons.verify_token(refresh_token)
    end
  end
end
