defmodule ElixirPngTest do
  use ExUnit.Case
  doctest ElixirPng

  @test_palette [
    {255, 255, 255},  # White
    {255, 0, 0},      # Red
    {0, 255, 0},      # Green
    {0, 0, 255}       # Blue
  ]

  @test_pixels [
    {255, 255, 255}, {255, 0, 0},
    {0, 255, 0}, {0, 0, 255}
  ]

  describe "find_palette_index/2" do
    test "finds correct index for existing color" do
      assert ElixirPng.find_palette_index({255, 0, 0}, @test_palette) == 1
      assert ElixirPng.find_palette_index({0, 255, 0}, @test_palette) == 2
      assert ElixirPng.find_palette_index({0, 0, 255}, @test_palette) == 3
    end

    test "returns 0 for non-existing color" do
      assert ElixirPng.find_palette_index({128, 128, 128}, @test_palette) == 0
    end

    test "finds first color at index 0" do
      assert ElixirPng.find_palette_index({255, 255, 255}, @test_palette) == 0
    end
  end

  describe "create_png_binary/4" do
    test "creates valid PNG binary with correct signature" do
      png_binary = ElixirPng.create_png_binary(2, 2, @test_pixels, @test_palette)

      # Check PNG signature
      <<signature::binary-size(8), _rest::binary>> = png_binary
      expected_signature = <<137, 80, 78, 71, 13, 10, 26, 10>>
      assert signature == expected_signature
    end

    test "creates binary with reasonable size" do
      png_binary = ElixirPng.create_png_binary(2, 2, @test_pixels, @test_palette)

      # PNG should be at least 50 bytes (signature + minimal chunks)
      assert byte_size(png_binary) > 50
      # But not unreasonably large for a 2x2 image
      assert byte_size(png_binary) < 500
    end

    test "handles different image sizes" do
      # 1x1 image
      single_pixel = [{255, 255, 255}]
      png_1x1 = ElixirPng.create_png_binary(1, 1, single_pixel, @test_palette)
      assert is_binary(png_1x1)

      # 3x3 image
      nine_pixels = List.duplicate({255, 0, 0}, 9)
      png_3x3 = ElixirPng.create_png_binary(3, 3, nine_pixels, @test_palette)
      assert is_binary(png_3x3)
    end
  end

  describe "write_png_file/2" do
    setup do
      # Create a temporary directory for test files
      test_dir = System.tmp_dir!() |> Path.join("elixir_png_test")
      File.mkdir_p!(test_dir)

      on_exit(fn ->
        File.rm_rf!(test_dir)
      end)

      %{test_dir: test_dir}
    end

    test "writes PNG file successfully", %{test_dir: test_dir} do
      png_binary = ElixirPng.create_png_binary(2, 2, @test_pixels, @test_palette)
      filepath = Path.join(test_dir, "test.png")

      assert {:ok, ^filepath} = ElixirPng.write_png_file(png_binary, filepath)
      assert File.exists?(filepath)

      # Verify file content matches what we wrote
      written_content = File.read!(filepath)
      assert written_content == png_binary
    end

    test "creates directories if they don't exist", %{test_dir: test_dir} do
      png_binary = ElixirPng.create_png_binary(1, 1, [{255, 255, 255}], @test_palette)
      nested_path = Path.join([test_dir, "nested", "dir", "test.png"])

      assert {:ok, ^nested_path} = ElixirPng.write_png_file(png_binary, nested_path)
      assert File.exists?(nested_path)
    end

    test "returns error for invalid path" do
      png_binary = ElixirPng.create_png_binary(1, 1, [{255, 255, 255}], @test_palette)
      # Use a path that would fail during directory creation
      invalid_path = "/dev/null/test.png"

      assert {:error, error_msg} = ElixirPng.write_png_file(png_binary, invalid_path)
      assert String.contains?(error_msg, "Failed to create directory")
    end
  end

  describe "PNG format validation" do
    test "creates PNG with proper chunk structure" do
      png_binary = ElixirPng.create_png_binary(2, 2, @test_pixels, @test_palette)

      # Skip signature and check for IHDR chunk
      <<_signature::binary-size(8), rest::binary>> = png_binary

      # First chunk should be IHDR
      <<_length::32, "IHDR", _ihdr_data::binary-size(13), _ihdr_crc::32, after_ihdr::binary>> = rest

      # Should contain PLTE chunk
      assert String.contains?(after_ihdr, "PLTE")

      # Should contain IDAT chunk
      assert String.contains?(after_ihdr, "IDAT")

      # Should end with IEND chunk
      assert String.ends_with?(png_binary, <<0, 0, 0, 0, "IEND", 0xAE, 0x42, 0x60, 0x82>>)
    end

    test "IHDR chunk contains correct image dimensions" do
      png_binary = ElixirPng.create_png_binary(5, 3, List.duplicate({255, 0, 0}, 15), @test_palette)

      # Extract IHDR data
      <<_signature::binary-size(8), _length::32, "IHDR",
        width::32, height::32, _rest::binary>> = png_binary

      assert width == 5
      assert height == 3
    end
  end
end
