# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaGltf.ExternalFilesTest do
  use ExUnit.Case, async: true

  alias AriaGltf.ExternalFiles

  @tmp_dir System.tmp_dir!()

  describe "parse_uri/1" do
    test "parses data URIs correctly" do
      data_uri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg=="

      assert {:ok, uri_info} = ExternalFiles.parse_uri(data_uri)
      assert uri_info.scheme == "data"
      assert uri_info.is_data_uri == true
      assert uri_info.mime_type == "image/png"
      assert uri_info.encoding == :base64
    end

    test "parses HTTP URLs correctly" do
      url = "https://example.com/texture.png"

      assert {:ok, uri_info} = ExternalFiles.parse_uri(url)
      assert uri_info.scheme == "https"
      assert uri_info.is_data_uri == false
      assert uri_info.mime_type == "image/png"
    end

    test "parses relative file paths correctly" do
      path = "textures/diffuse.jpg"

      assert {:ok, uri_info} = ExternalFiles.parse_uri(path)
      assert uri_info.scheme == nil
      assert uri_info.is_data_uri == false
      assert uri_info.path == path
      assert uri_info.mime_type == "image/jpeg"
    end

    test "parses absolute file paths correctly" do
      path = "/absolute/path/to/texture.png"

      assert {:ok, uri_info} = ExternalFiles.parse_uri(path)
      assert uri_info.scheme == nil
      assert uri_info.is_data_uri == false
      assert uri_info.path == path
      assert uri_info.mime_type == "image/png"
    end
  end

  describe "validate_uri/2" do
    test "allows data URIs" do
      uri_info = %{is_data_uri: true}
      assert :ok = ExternalFiles.validate_uri(uri_info, false)
    end

    test "allows file paths" do
      uri_info = %{is_data_uri: false, scheme: nil}
      assert :ok = ExternalFiles.validate_uri(uri_info, false)
    end

    test "allows HTTP URLs when enabled" do
      uri_info = %{is_data_uri: false, scheme: "https"}
      assert :ok = ExternalFiles.validate_uri(uri_info, true)
    end

    test "rejects HTTP URLs when disabled" do
      uri_info = %{is_data_uri: false, scheme: "https"}
      assert {:error, {:http_not_allowed, _}} = ExternalFiles.validate_uri(uri_info, false)
    end

    test "rejects unsupported schemes" do
      uri_info = %{is_data_uri: false, scheme: "ftp"}
      assert {:error, {:unsupported_scheme, _}} = ExternalFiles.validate_uri(uri_info, false)
    end
  end

  describe "resolve_file_path/2" do
    test "handles data URIs" do
      uri_info = %{is_data_uri: true}
      assert {:ok, :data_uri} = ExternalFiles.resolve_file_path(uri_info, "/base")
    end

    test "resolves relative paths" do
      uri_info = %{is_data_uri: false, scheme: nil, path: "texture.png"}
      base_path = "/models"

      assert {:ok, resolved} = ExternalFiles.resolve_file_path(uri_info, base_path)
      assert resolved == "/models/texture.png"
    end

    test "handles absolute paths" do
      uri_info = %{is_data_uri: false, scheme: nil, path: "/absolute/texture.png"}
      base_path = "/models"

      assert {:ok, resolved} = ExternalFiles.resolve_file_path(uri_info, base_path)
      assert resolved == "/absolute/texture.png"
    end

    test "rejects path escape attempts" do
      uri_info = %{is_data_uri: false, scheme: nil, path: "../../../etc/passwd"}
      base_path = "/safe/models"

      assert {:error, {:path_escape_attempt, _}} = ExternalFiles.resolve_file_path(uri_info, base_path)
    end

    test "rejects external URLs in file path resolution" do
      uri_info = %{is_data_uri: false, scheme: "https", path: "/texture.png"}
      base_path = "/models"

      assert {:error, {:external_url, _}} = ExternalFiles.resolve_file_path(uri_info, base_path)
    end
  end

  describe "load_file/2" do
    setup do
      # Create test files
      test_dir = Path.join(@tmp_dir, "gltf_external_test")
      File.mkdir_p!(test_dir)

      # Create a small test image (1x1 PNG)
      png_data = <<0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
                   0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
                   0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, 0xDE, 0x00, 0x00, 0x00,
                   0x0C, 0x49, 0x44, 0x41, 0x54, 0x08, 0xD7, 0x63, 0xF8, 0x0F, 0x00, 0x01,
                   0x01, 0x01, 0x00, 0x18, 0xDD, 0x8D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
                   0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82>>

      test_image = Path.join(test_dir, "test.png")
      :ok = File.write(test_image, png_data)

      # Create a simple binary file
      bin_data = <<1, 2, 3, 4, 5, 6, 7, 8>>
      test_bin = Path.join(test_dir, "test.bin")
      :ok = File.write(test_bin, bin_data)

      on_exit(fn ->
        File.rm_rf(test_dir)
      end)

      %{
        test_dir: test_dir,
        test_image: test_image,
        test_bin: test_bin,
        png_data: png_data,
        bin_data: bin_data
      }
    end

    test "loads regular files", %{test_dir: test_dir, test_image: _test_image, png_data: png_data} do
      assert {:ok, loaded_data} = ExternalFiles.load_file("test.png", base_path: test_dir)
      assert loaded_data == png_data
    end

    test "loads data URIs" do
      # Base64 encoded "hello"
      data_uri = "data:text/plain;base64,aGVsbG8="

      assert {:ok, loaded_data} = ExternalFiles.load_file(data_uri)
      assert loaded_data == "hello"
    end

    test "handles file not found errors", %{test_dir: test_dir} do
      assert {:error, {:file_stat_error, :enoent}} = ExternalFiles.load_file("nonexistent.png", base_path: test_dir)
    end

    test "enforces file size limits", %{test_dir: test_dir} do
      assert {:error, {:file_too_large, _}} = ExternalFiles.load_file("test.png", base_path: test_dir, max_file_size: 10)
    end

    test "rejects HTTP URLs by default" do
      assert {:error, {:http_not_allowed, _}} = ExternalFiles.load_file("https://example.com/image.png")
    end

    test "handles malformed data URIs" do
      assert {:error, {:invalid_data_uri, _}} = ExternalFiles.load_file("data:invalid")
      assert {:error, {:base64_decode_error, _}} = ExternalFiles.load_file("data:text/plain;base64,invalid_base64!")
    end
  end

  describe "load_image/2" do
    setup do
      test_dir = Path.join(@tmp_dir, "gltf_image_test")
      File.mkdir_p!(test_dir)

      # Create a minimal 1x1 PNG
      png_data = <<0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
                   0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
                   0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, 0xDE, 0x00, 0x00, 0x00,
                   0x0C, 0x49, 0x44, 0x41, 0x54, 0x08, 0xD7, 0x63, 0xF8, 0x0F, 0x00, 0x01,
                   0x01, 0x01, 0x00, 0x18, 0xDD, 0x8D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
                   0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82>>

      # Create a minimal JPEG (just header)
      jpeg_data = <<0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
                    0xFF, 0xC0, 0x00, 0x11, 0x08, 0x00, 0x01, 0x00, 0x01, 0x01, 0x01, 0x11,
                    0x00, 0x02, 0x11, 0x01, 0x03, 0x11, 0x01, 0xFF, 0xD9>>

      test_png = Path.join(test_dir, "test.png")
      test_jpg = Path.join(test_dir, "test.jpg")
      :ok = File.write(test_png, png_data)
      :ok = File.write(test_jpg, jpeg_data)

      on_exit(fn ->
        File.rm_rf(test_dir)
      end)

      %{test_dir: test_dir, png_data: png_data, jpeg_data: jpeg_data}
    end

    test "loads and validates PNG images", %{test_dir: test_dir, png_data: png_data} do
      assert {:ok, image_info} = ExternalFiles.load_image("test.png", base_path: test_dir)
      assert image_info.data == png_data
      assert image_info.mime_type == "image/png"
      assert image_info.width == 1
      assert image_info.height == 1
      assert image_info.validated == true
    end

    test "loads and validates JPEG images", %{test_dir: test_dir, jpeg_data: jpeg_data} do
      assert {:ok, image_info} = ExternalFiles.load_image("test.jpg", base_path: test_dir)
      assert image_info.data == jpeg_data
      assert image_info.mime_type == "image/jpeg"
      assert image_info.width == 1
      assert image_info.height == 1
      assert image_info.validated == true
    end

    test "skips validation when disabled", %{test_dir: test_dir, png_data: png_data} do
      assert {:ok, image_info} = ExternalFiles.load_image("test.png",
        base_path: test_dir,
        validate_format: false
      )
      assert image_info.data == png_data
      assert image_info.mime_type == "application/octet-stream"
      assert image_info.width == nil
      assert image_info.height == nil
      assert image_info.validated == false
    end

    test "rejects unsupported formats", %{test_dir: test_dir} do
      # Create a file with unsupported content
      unsupported_file = Path.join(test_dir, "test.txt")
      :ok = File.write(unsupported_file, "not an image")

      assert {:error, {:unknown_image_format, _}} = ExternalFiles.load_image("test.txt", base_path: test_dir)
    end

    test "enforces supported format restrictions", %{test_dir: test_dir} do
      # Restrict to only JPEG
      assert {:error, {:unsupported_format, _}} = ExternalFiles.load_image("test.png",
        base_path: test_dir,
        supported_formats: ["image/jpeg"]
      )
    end

    test "loads images from data URIs" do
      # Base64 encoded 1x1 PNG
      data_uri = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg=="

      assert {:ok, image_info} = ExternalFiles.load_image(data_uri)
      assert image_info.mime_type == "image/png"
      assert image_info.width == 1
      assert image_info.height == 1
      assert image_info.validated == true
    end
  end

  describe "load_buffer/2" do
    setup do
      test_dir = Path.join(@tmp_dir, "gltf_buffer_test")
      File.mkdir_p!(test_dir)

      buffer_data = <<0, 1, 2, 3, 4, 5, 6, 7, 8, 9>>
      test_buffer = Path.join(test_dir, "geometry.bin")
      :ok = File.write(test_buffer, buffer_data)

      on_exit(fn ->
        File.rm_rf(test_dir)
      end)

      %{test_dir: test_dir, buffer_data: buffer_data}
    end

    test "loads buffer files", %{test_dir: test_dir, buffer_data: buffer_data} do
      assert {:ok, loaded_data} = ExternalFiles.load_buffer("geometry.bin", base_path: test_dir)
      assert loaded_data == buffer_data
    end

    test "loads buffers from data URIs" do
      # Base64 encoded binary data
      data_uri = "data:application/octet-stream;base64,AAECAwQFBgcICQ=="
      expected_data = <<0, 1, 2, 3, 4, 5, 6, 7, 8, 9>>

      assert {:ok, loaded_data} = ExternalFiles.load_buffer(data_uri)
      assert loaded_data == expected_data
    end
  end

  describe "image format detection" do
    test "detects JPEG format" do
      jpeg_header = <<0xFF, 0xD8, 0xFF, 0xE0>>
      _uri_info = %{path: "test.jpg", is_data_uri: false, scheme: nil, mime_type: "image/jpeg"}

      # We'll test this indirectly through load_image since detect_image_format is private
      # but we can test the public interface behavior
      assert match?({:ok, %{mime_type: "image/jpeg"}},
        AriaGltf.ExternalFiles.analyze_image_data(jpeg_header <> <<0::size(800)>>, true, ["image/jpeg", "image/png"]))
    end

    test "detects PNG format" do
      png_header = <<0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A>>

      # Test through the public interface
      assert match?({:ok, %{mime_type: "image/png"}},
        AriaGltf.ExternalFiles.analyze_image_data(png_header <> <<0::size(800)>>, true, ["image/jpeg", "image/png"]))
    end

    test "rejects unknown formats" do
      unknown_data = <<0x00, 0x00, 0x00, 0x00>>

      assert match?({:error, {:unknown_image_format, _}},
        AriaGltf.ExternalFiles.analyze_image_data(unknown_data, true, ["image/jpeg", "image/png"]))
    end
  end

  # Test the private analyze_image_data function through a module function
  # since it's used in load_image
  def analyze_image_data(data, validate, supported_formats) do
    case AriaGltf.ExternalFiles.load_image("dummy", validate_format: validate, supported_formats: supported_formats) do
      {:ok, %{data: ^data} = info} -> {:ok, Map.delete(info, :data)}
      {:error, _} = _error ->
        # Simulate the analyze_image_data call directly
        if validate do
          case data do
            <<0xFF, 0xD8, 0xFF, _rest::binary>> ->
              if "image/jpeg" in supported_formats do
                {:ok, %{mime_type: "image/jpeg", width: nil, height: nil, validated: true}}
              else
                {:error, {:unsupported_format, "Format image/jpeg not in supported list"}}
              end
            <<0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, _rest::binary>> ->
              if "image/png" in supported_formats do
                {:ok, %{mime_type: "image/png", width: nil, height: nil, validated: true}}
              else
                {:error, {:unsupported_format, "Format image/png not in supported list"}}
              end
            _ ->
              {:error, {:unknown_image_format, "Could not detect image format"}}
          end
        else
          {:ok, %{mime_type: "application/octet-stream", width: nil, height: nil, validated: false}}
        end
    end
  end
end
