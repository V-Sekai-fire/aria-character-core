# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

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

  describe "import_from_file/2" do
    setup do
      # Create a valid test file
      document = IO.create_minimal_document()
      test_file = Path.join(@tmp_dir, "test_import.gltf")
      {:ok, json_content} = IO.serialize_document(document)
      :ok = File.write(test_file, json_content)

      # Create an invalid JSON file
      invalid_file = Path.join(@tmp_dir, "test_invalid.gltf")
      :ok = File.write(invalid_file, "{invalid json")

      # Create a malformed but recoverable JSON file
      recoverable_file = Path.join(@tmp_dir, "test_recoverable.gltf")
      recoverable_content = """
      {
        "asset": {
          "version": "2.0",
          "generator": "test",
        },
        "scenes": [],
      }
      """
      :ok = File.write(recoverable_file, recoverable_content)

      on_exit(fn ->
        File.rm(test_file)
        File.rm(invalid_file)
        File.rm(recoverable_file)
      end)

      %{
        test_file: test_file,
        invalid_file: invalid_file,
        recoverable_file: recoverable_file
      }
    end

    test "imports valid glTF file successfully", %{test_file: test_file} do
      assert {:ok, document} = IO.import_from_file(test_file)
      assert %Document{} = document
      assert document.asset.version == "2.0"
      assert document.asset.generator == "aria_gltf"
    end

    test "imports with different validation modes", %{test_file: test_file} do
      assert {:ok, _document} = IO.import_from_file(test_file, validation_mode: :strict)
      assert {:ok, _document} = IO.import_from_file(test_file, validation_mode: :permissive)
      assert {:ok, _document} = IO.import_from_file(test_file, validation_mode: :warning_only)
    end

    test "handles file not found error" do
      non_existent = Path.join(@tmp_dir, "does_not_exist.gltf")
      assert {:error, {:file_not_found, ^non_existent}} = IO.import_from_file(non_existent)
    end

    test "handles invalid JSON without recovery", %{invalid_file: invalid_file} do
      assert {:error, {:json_parse_failed, _}} = IO.import_from_file(invalid_file)
    end

    test "attempts JSON recovery when enabled", %{recoverable_file: recoverable_file} do
      # Without recovery - should fail
      assert {:error, {:json_parse_failed, _}} = IO.import_from_file(recoverable_file)

      # With recovery - should succeed
      assert {:ok, _document} = IO.import_from_file(recoverable_file, continue_on_errors: true)
    end

    test "handles validation errors in strict mode", %{test_file: _test_file} do
      # Create a file with validation issues - missing required asset version
      invalid_document = %{
        "asset" => %{"generator" => "test"},  # Missing required version field
        "scenes" => []
      }

      invalid_content = Jason.encode!(invalid_document, pretty: true)
      invalid_file = Path.join(@tmp_dir, "validation_test.gltf")
      :ok = File.write(invalid_file, invalid_content)

      # Strict mode should fail validation
      result = IO.import_from_file(invalid_file, validation_mode: :strict)

      case result do
        {:error, %AriaGltf.Validation.Report{}} -> :ok
        {:error, _other} -> :ok  # Other validation errors are also acceptable
        {:ok, _} -> flunk("Expected validation to fail in strict mode")
      end

      File.rm(invalid_file)
    end

    test "permissive mode allows validation warnings", %{test_file: test_file} do
      # Should succeed even with potential validation issues
      assert {:ok, _document} = IO.import_from_file(test_file, validation_mode: :permissive)
    end
  end

  describe "load_file/1 (legacy)" do
    test "loads file using legacy interface" do
      # Create test file
      document = IO.create_minimal_document()
      test_file = Path.join(@tmp_dir, "legacy_test.gltf")
      {:ok, json_content} = IO.serialize_document(document)
      :ok = File.write(test_file, json_content)

      assert {:ok, loaded_document} = IO.load_file(test_file)
      assert %Document{} = loaded_document
      assert loaded_document.asset.version == "2.0"

      # Clean up
      File.rm(test_file)
    end
  end

  describe "save_file/2" do
    test "saves document to file" do
      document = IO.create_minimal_document()
      file_path = Path.join(@tmp_dir, "test_save.gltf")

      assert :ok = IO.save_file(document, file_path)
      assert File.exists?(file_path)

      # Verify content
      {:ok, content} = File.read(file_path)
      {:ok, parsed} = Jason.decode(content)
      assert parsed["asset"]["version"] == "2.0"

      File.rm(file_path)
    end
  end

  describe "binary glTF support (stubs)" do
    test "load_binary returns not implemented" do
      assert {:error, :not_implemented} = IO.load_binary("test.glb")
    end

    test "save_binary returns not implemented" do
      document = IO.create_minimal_document()
      assert {:error, :not_implemented} = IO.save_binary(document, "test.glb")
    end
  end
end
