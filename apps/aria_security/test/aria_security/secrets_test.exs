# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaSecurity.SecretsTest do
  use ExUnit.Case, async: true

  alias AriaSecurity.Secrets
  alias AriaSecurity.SecretsRepo
  alias AriaSecurity.Secret

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(SecretsRepo)
    on_exit fn -> Ecto.Adapters.SQL.Sandbox.checkin(SecretsRepo) end
  end

  describe "Secret management with EctoBackend" do
    test "can set and get a secret" do
      key = "my_app_secret_key"
      value = "my_app_secret_value"

      # Set the secret
      assert :ok = Secrets.set_secret(key, value)

      # Get the secret
      assert {:ok, ^value} = Secrets.get_secret(key)
    end

    test "returns :not_found for a non-existent secret" do
      assert {:error, :not_found} = Secrets.get_secret("non_existent_key")
    end

    test "can update an existing secret" do
      key = "update_secret_key"
      initial_value = "initial_value"
      updated_value = "new_value"

      # Set initial secret
      assert :ok = Secrets.set_secret(key, initial_value)
      assert {:ok, ^initial_value} = Secrets.get_secret(key)

      # Update the secret
      assert :ok = Secrets.set_secret(key, updated_value)
      assert {:ok, ^updated_value} = Secrets.get_secret(key)
    end

    test "can delete a secret" do
      key = "delete_secret_key"
      value = "value_to_delete"

      # Set the secret
      assert :ok = Secrets.set_secret(key, value)
      assert {:ok, ^value} = Secrets.get_secret(key)

      # Delete the secret
      assert :ok = Secrets.delete_secret(key)
      assert {:error, :not_found} = Secrets.get_secret(key)
    end

    test "returns :not_found when deleting a non-existent secret" do
      assert {:error, :not_found} = Secrets.delete_secret("non_existent_delete_key")
    end

    test "can list secrets" do
      # Clear existing secrets for a clean test
      SecretsRepo.delete_all(Secret)

      assert :ok = Secrets.set_secret("key1", "value1")
      assert :ok = Secrets.set_secret("key2", "value2")
      assert :ok = Secrets.set_secret("key3", "value3")

      {:ok, listed_keys} = Secrets.list_secrets()
      assert Enum.sort(listed_keys) == ["key1", "key2", "key3"]
    end
  end
end