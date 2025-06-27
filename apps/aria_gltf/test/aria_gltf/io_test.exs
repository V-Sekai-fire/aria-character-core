# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaGltf.IOTest do
  use ExUnit.Case, async: true

  alias AriaGltf.{IO, Document, Asset}

  @tmp_dir System.tmp_dir!()

  describe "export_to_file/2" do
    test "exports a minimal document successfully" do
      document = IO.create_minimal_document()
      file_path = Path.join(@tmp_dir, "test_minimal.gltf")

      # Clean up any existing file
      File.rm(file_path)

      assert {:ok, ^file_path} = IO.export_to_file(document, file_path)
      assert File.exists?(file_path)

      # Verify the file contains valid JSON
      {:ok, content} = File.read(file_path)
      {:ok, parsed} = Jason.decode(content)

      assert parsed["asset"]["version"] == "2.0"
      assert parsed["asset"]["generator"] == "aria_gltf"

      # Clean up
      File.rm(file_path)
    end

    test "creates directory if it doesn't exist" do
      document = IO.create_minimal_document()
      nested_dir = Path.join([@tmp_dir, "nested", "test", "dir"])
      file_path = Path.join(nested_dir, "test.gltf")

      # Ensure directory doesn't exist
      File.rm_rf(Path.join(@tmp_dir, "nested"))

      assert {:ok, ^file_path} = IO.export_to_file(document, file_path)
      assert File.exists?(file_path)

      # Clean up
      File.rm_rf(Path.join(@tmp_dir, "nested"))
    end

    test "returns error for invalid arguments" do
      assert {:error, :invalid_arguments} = IO.export_to_file("not a document", "path")
      assert {:error, :invalid_arguments} = IO.export_to_file(IO.create_minimal_document(), 123)
    end

    test "returns error for document without asset" do
      # Create a document and manually set asset to nil to test validation
      document = IO.create_minimal_document()
      document_with_nil_asset = %{document | asset: nil}
      file_path = Path.join(@tmp_dir, "test_no_asset.gltf")

      assert {:error, :missing_asset} = IO.export_to_file(document_with_nil_asset, file_path)
    end

    test "returns error for unsupported version" do
      document = IO.create_minimal_document()
      document_with_old_version = %{document | asset: %Asset{version: "1.0"}}
      file_path = Path.join(@tmp_dir, "test_old_version.gltf")

      assert {:error, {:unsupported_version, "1.0"}} = IO.export_to_file(document_with_old_version, file_path)
    end

    test "handles file write errors gracefully" do
      document = IO.create_minimal_document()
      # Try to write to a path that should fail (root directory without permissions)
      invalid_path = "/root/test.gltf"

      case IO.export_to_file(document, invalid_path) do
        {:error, {:directory_creation_failed, _}} -> :ok
        {:error, {:file_write_failed, _}} -> :ok
        other -> flunk("Expected directory or file write error, got: #{inspect(other)}")
      end
    end
  end

  describe "validate_document/1" do
    test "validates document with proper asset" do
      document = IO.create_minimal_document()

      assert :ok = IO.validate_document(document)
    end

    test "rejects document without asset" do
      document = IO.create_minimal_document()
      document_with_nil_asset = %{document | asset: nil}

      assert {:error, :missing_asset} = IO.validate_document(document_with_nil_asset)
    end

    test "rejects document with wrong version" do
      document = IO.create_minimal_document()
      document_with_old_version = %{document | asset: %Asset{version: "1.0"}}

      assert {:error, {:unsupported_version, "1.0"}} = IO.validate_document(document_with_old_version)
    end
  end

  describe "create_minimal_document/0" do
    test "creates a valid minimal document" do
      document = IO.create_minimal_document()

      assert %Document{} = document
      assert document.asset.version == "2.0"
      assert document.asset.generator == "aria_gltf"
      assert is_list(document.scenes)
      assert is_list(document.nodes)
      assert is_list(document.meshes)
    end

    test "minimal document passes validation" do
      document = IO.create_minimal_document()

      assert :ok = IO.validate_document(document)
    end
  end

  describe "serialize_document/1" do
    test "serializes minimal document to JSON" do
      document = IO.create_minimal_document()

      assert {:ok, json_string} = IO.serialize_document(document)
      assert is_binary(json_string)

      # Verify it's valid JSON
      {:ok, parsed} = Jason.decode(json_string)
      assert parsed["asset"]["version"] == "2.0"
    end
  end

  describe "ensure_directory_exists/1" do
    test "creates nested directories" do
      nested_path = Path.join([@tmp_dir, "test_nested", "deep", "path", "file.gltf"])

      # Clean up first
      File.rm_rf(Path.join(@tmp_dir, "test_nested"))

      assert :ok = IO.ensure_directory_exists(nested_path)
      assert File.dir?(Path.dirname(nested_path))

      # Clean up
      File.rm_rf(Path.join(@tmp_dir, "test_nested"))
    end

    test "succeeds when directory already exists" do
      existing_path = Path.join(@tmp_dir, "file.gltf")

      assert :ok = IO.ensure_directory_exists(existing_path)
    end
  end
end
