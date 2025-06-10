# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaSecurity.SecretsTest do
  use ExUnit.Case, async: true

  alias AriaSecurity.Secrets
  alias AriaSecurity.SecretsRepo
  alias AriaSecurity.Secret
  alias Jason # Needed for encoding/decoding test data

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(SecretsRepo)
    on_exit fn -> Ecto.Adapters.SQL.Sandbox.checkin(SecretsRepo) end
  end

  describe "Secret management with EctoBackend mimicking Vaultex API" do
    test "can write and read a secret" do
      path = "secret/data/my_app/api_key"
      data = %{api_key: "mock_api_key", other_data: "value"}

      # Write the secret
      assert :ok = Secrets.write(path, data)

      # Read the secret
      assert {:ok, %{"data" => ^data}} = Secrets.read(path)
    end

    test "returns :not_found for a non-existent secret" do
      assert {:error, :not_found} = Secrets.read("non_existent_path")
    end

    test "can update an existing secret" do
      path = "secret/data/update_key"
      initial_data = %{field1: "initial_value"}
      updated_data = %{field1: "new_value", field2: "added"}

      # Write initial secret
      assert :ok = Secrets.write(path, initial_data)
      assert {:ok, %{"data" => ^initial_data}} = Secrets.read(path)

      # Update the secret
      assert :ok = Secrets.write(path, updated_data)
      assert {:ok, %{"data" => ^updated_data}} = Secrets.read(path)
    end

    test "can delete a secret" do
      path = "secret/data/delete_key"
      data = %{to_delete: "value"}

      # Write the secret
      assert :ok = Secrets.write(path, data)
      assert {:ok, %{"data" => ^data}} = Secrets.read(path)

      # Delete the secret
      assert :ok = Secrets.delete(path)
      assert {:error, :not_found} = Secrets.read(path)
    end

    test "returns :not_found when deleting a non-existent secret" do
      assert {:error, :not_found} = Secrets.delete("non_existent_delete_path")
    end

    test "can list secrets" do
      # Clear existing secrets for a clean test
      SecretsRepo.delete_all(Secret)

      assert :ok = Secrets.write("secret/data/key1", %{val: 1})
      assert :ok = Secrets.write("secret/data/key2", %{val: 2})
      assert :ok = Secrets.write("secret/data/key3", %{val: 3})

      {:ok, %{"keys" => listed_keys}} = Secrets.list("secret/data")
      assert Enum.sort(listed_keys) == ["secret/data/key1", "secret/data/key2", "secret/data/key3"]
    end
  end
end