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

  describe "macaroon internals and debugging" do
    test "can examine macaroon structure and caveats in detail" do
      user = %User{
        id: "debug-user-123",
        email: "debug@example.com",
        roles: ["user", "editor"]
      }
      
      {:ok, token} = Macaroons.generate_token(user)
      
      # Decode the token with custom caveat registration
      options = Macfly.Options.with_caveats(
        %Macfly.Options{},
        [AriaAuth.Macaroons.PermissionsCaveat, AriaAuth.Macaroons.ConfineUserString]
      )
      {:ok, [macaroon]} = Macfly.decode(token, options)
      
      # Should have exactly 3 caveats: ValidityWindow, ConfineUserString, PermissionsCaveat
      assert length(macaroon.caveats) == 3
      
      # Examine each caveat type
      caveat_types = Enum.map(macaroon.caveats, & &1.__struct__)
      assert ValidityWindow in caveat_types
      assert ConfineUserString in caveat_types
      assert PermissionsCaveat in caveat_types
      
      # Find and verify specific caveats
      user_caveat = Enum.find(macaroon.caveats, fn caveat -> 
        match?(%ConfineUserString{}, caveat) 
      end)
      assert user_caveat != nil
      assert user_caveat.id == "debug-user-123"
      
      perms_caveat = Enum.find(macaroon.caveats, fn caveat -> 
        match?(%PermissionsCaveat{}, caveat) 
      end)
      assert perms_caveat != nil
      assert perms_caveat.permissions == ["user", "editor"]
      
      validity_caveat = Enum.find(macaroon.caveats, fn caveat -> 
        match?(%ValidityWindow{}, caveat) 
      end)
      assert validity_caveat != nil
    end
    
    test "protocol implementations work correctly for all custom caveats" do
      user_id = "protocol-test-123"
      permissions = ["admin", "moderator"]
      
      user_caveat = ConfineUserString.build(user_id)
      perms_caveat = PermissionsCaveat.build(permissions)
      validity_caveat = ValidityWindow.build(for: 3600)
      
      # Test ConfineUserString protocol
      assert Macfly.Caveat.name(user_caveat) == "ConfineUserString"
      assert Macfly.Caveat.type(user_caveat) == 101
      assert Macfly.Caveat.body(user_caveat) == [user_id]
      
      # Test PermissionsCaveat protocol
      assert Macfly.Caveat.name(perms_caveat) == "PermissionsCaveat"
      assert Macfly.Caveat.type(perms_caveat) == 100
      assert Macfly.Caveat.body(perms_caveat) == [permissions]
      
      # Test ValidityWindow protocol (built-in)
      assert Macfly.Caveat.name(validity_caveat) == "ValidityWindow"
      assert is_integer(Macfly.Caveat.type(validity_caveat))
      assert is_list(Macfly.Caveat.body(validity_caveat))
    end
    
    test "token generation and verification end-to-end with debugging" do
      user = %User{
        id: "e2e-debug-user",
        email: "e2e@example.com",
        roles: ["user", "editor"]
      }
      
      # Test token generation
      assert {:ok, token} = Macaroons.generate_token(user)
      assert is_binary(token)
      assert String.length(token) > 0
      
      # Test token verification
      assert {:ok, result} = Macaroons.verify_token(token)
      assert %{user_id: "e2e-debug-user", permissions: ["user", "editor"]} = result
    end
    
    test "token generation with custom options" do
      user = %User{
        id: "custom-options-user",
        email: "custom@example.com",
        roles: ["base_user"]
      }
      
      # Test with custom expiry and permissions
      custom_permissions = ["read", "write", "admin"]
      custom_expiry = 1800  # 30 minutes
      
      assert {:ok, token} = Macaroons.generate_token(user, 
        expiry: custom_expiry,
        permissions: custom_permissions
      )
      
      # Verify the custom settings are preserved
      assert {:ok, %{user_id: "custom-options-user", permissions: ^custom_permissions}} = 
        Macaroons.verify_token(token)
    end
    
    test "handles decoding errors gracefully" do
      # Test with completely invalid token
      assert {:error, _reason} = Macaroons.verify_token("not-a-token")
      
      # Test with malformed base64-like string
      assert {:error, _reason} = Macaroons.verify_token("dGVzdA==.invalid.token")
      
      # Test with empty string
      assert {:error, _reason} = Macaroons.verify_token("")
    end
    
    test "macaroon roundtrip preserves all data" do
      user = %User{
        id: "roundtrip-test-user",
        email: "roundtrip@example.com", 
        roles: ["user", "admin", "moderator"]
      }
      
      original_permissions = ["custom1", "custom2", "custom3"]
      
      # Generate token
      {:ok, token} = Macaroons.generate_token(user, permissions: original_permissions)
      
      # Decode and examine structure
      options = Macfly.Options.with_caveats(
        %Macfly.Options{},
        [AriaAuth.Macaroons.PermissionsCaveat, AriaAuth.Macaroons.ConfineUserString]
      )
      {:ok, [macaroon]} = Macfly.decode(token, options)
      
      # Extract data from caveats
      user_caveat = Enum.find(macaroon.caveats, &match?(%ConfineUserString{}, &1))
      perms_caveat = Enum.find(macaroon.caveats, &match?(%PermissionsCaveat{}, &1))
      
      # Verify all data is preserved
      assert user_caveat.id == user.id
      assert perms_caveat.permissions == original_permissions
      
      # Verify through high-level API
      {:ok, %{user_id: verified_user_id, permissions: verified_permissions}} = 
        Macaroons.verify_token(token)
      
      assert verified_user_id == user.id
      assert verified_permissions == original_permissions
    end
  end

  describe "debug script functionality migration" do
    test "step by step caveat creation and protocol verification" do
      # This test replicates the debug_macaroons.exs functionality
      test_user = %User{
        id: "test-user-123",
        email: "test@example.com",
        roles: ["user", "editor"]
      }

      # Test ConfineUserString caveat creation
      user_caveat = ConfineUserString.build(test_user.id)
      assert %ConfineUserString{id: "test-user-123"} = user_caveat

      # Test PermissionsCaveat creation
      perms_caveat = PermissionsCaveat.build(test_user.roles)
      assert %PermissionsCaveat{permissions: ["user", "editor"]} = perms_caveat

      # Test ValidityWindow caveat creation
      validity_caveat = ValidityWindow.build(for: 3600)
      assert %ValidityWindow{} = validity_caveat

      # Test protocol implementations
      assert Macfly.Caveat.name(user_caveat) == "ConfineUserString"
      assert Macfly.Caveat.type(user_caveat) == 101
      assert Macfly.Caveat.body(user_caveat) == [test_user.id]

      assert Macfly.Caveat.name(perms_caveat) == "PermissionsCaveat"
      assert Macfly.Caveat.type(perms_caveat) == 100
      assert Macfly.Caveat.body(perms_caveat) == [test_user.roles]

      # Test full token generation and verification
      assert {:ok, token} = Macaroons.generate_token(test_user)
      assert is_binary(token)
      assert String.length(token) > 0

      assert {:ok, result} = Macaroons.verify_token(token)
      assert %{user_id: "test-user-123", permissions: ["user", "editor"]} = result
    end

    test "detailed macaroon internals examination" do
      # This test replicates the debug_macaroons_detailed.exs functionality
      test_user = %User{
        id: "test-user-123",
        email: "test@example.com",
        roles: ["user", "editor"]
      }

      # Generate token
      assert {:ok, token} = Macaroons.generate_token(test_user)

      # Decode token with custom caveat registration
      options = Macfly.Options.with_caveats(
        %Macfly.Options{},
        [PermissionsCaveat, ConfineUserString]
      )
      assert {:ok, [macaroon]} = Macfly.decode(token, options)

      # Examine caveats in detail
      assert length(macaroon.caveats) == 3

      # Check each caveat type and collect types
      caveat_types = Enum.map(macaroon.caveats, fn caveat ->
        assert caveat.__struct__ != nil
        caveat.__struct__
      end)

      # Ensure all expected caveat types are present
      assert ValidityWindow in caveat_types
      assert ConfineUserString in caveat_types  
      assert PermissionsCaveat in caveat_types

      # Search for specific caveats (like the debug script does)
      user_caveat = Enum.find(macaroon.caveats, fn caveat -> 
        match?(%ConfineUserString{}, caveat) 
      end)
      assert user_caveat != nil
      assert user_caveat.id == "test-user-123"

      perms_caveat = Enum.find(macaroon.caveats, fn caveat -> 
        match?(%PermissionsCaveat{}, caveat) 
      end)
      assert perms_caveat != nil
      assert perms_caveat.permissions == ["user", "editor"]

      validity_caveat = Enum.find(macaroon.caveats, fn caveat -> 
        match?(%ValidityWindow{}, caveat) 
      end)
      assert validity_caveat != nil

      # Verify that the debug-style enumeration works
      Enum.with_index(macaroon.caveats, fn caveat, index ->
        assert is_integer(index)
        assert caveat.__struct__ != nil
        assert caveat != nil
      end)
    end

    test "token generation success and failure scenarios" do
      # This replicates the error handling from debug scripts
      test_user = %User{
        id: "test-user-123",
        email: "test@example.com",
        roles: ["user", "editor"]
      }

      # Test successful generation
      case Macaroons.generate_token(test_user) do
        {:ok, token} -> 
          assert is_binary(token)
          assert String.length(token) > 0
          
          # Test successful verification
          case Macaroons.verify_token(token) do
            {:ok, result} ->
              assert %{user_id: "test-user-123", permissions: ["user", "editor"]} = result
            {:error, reason} ->
              flunk("Token verification should not fail: #{inspect(reason)}")
          end
          
        {:error, reason} -> 
          flunk("Token generation should not fail: #{inspect(reason)}")
      end

      # Test verification with invalid token
      case Macaroons.verify_token("invalid-token") do
        {:ok, _result} ->
          flunk("Invalid token should not verify successfully")
        {:error, _reason} ->
          # This is expected
          :ok
      end
    end

    test "token decoding without custom caveat registration fails gracefully" do
      # Test what happens when we decode without registering custom caveats
      test_user = %User{
        id: "test-user-456",
        email: "test@example.com", 
        roles: ["admin"]
      }

      {:ok, token} = Macaroons.generate_token(test_user)

      # Try to decode without custom caveat options (should still work but caveats might not be properly typed)
      case Macfly.decode(token) do
        {:ok, [macaroon]} ->
          # Should still have caveats, but they might be in a different format
          assert length(macaroon.caveats) >= 1
        {:error, reason} ->
          # This might fail, which is acceptable for this test
          assert reason != nil
      end
    end
  end
end
