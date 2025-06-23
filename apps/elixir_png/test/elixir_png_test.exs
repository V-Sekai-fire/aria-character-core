# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule ElixirPngTest do
  use ExUnit.Case
  doctest ElixirPng

  @png_signature <<137, 80, 78, 71, 13, 10, 26, 10>>

  describe "create_png/4" do
    test "creates valid PNG binary" do
      pixel_data = [
        {255, 0, 0}, {0, 255, 0}, {0, 0, 255}
      ]

      png_binary = ElixirPng.create_png(3, 1, pixel_data)

      assert is_binary(png_binary)
      assert String.starts_with?(png_binary, @png_signature)
    end

    test "handles empty pixel data" do
      pixel_data = []

      png_binary = ElixirPng.create_png(0, 0, pixel_data)

      assert is_binary(png_binary)
      assert String.starts_with?(png_binary, @png_signature)
    end

    test "uses custom palette when provided" do
      pixel_data = [{255, 255, 255}]
      custom_palette = [{255, 255, 255}, {0, 0, 0}]

      png_binary = ElixirPng.create_png(1, 1, pixel_data, palette: custom_palette)

      assert is_binary(png_binary)
      assert String.starts_with?(png_binary, @png_signature)
    end
  end

  describe "create_default_palette/0" do
    test "returns list of RGB tuples" do
      palette = ElixirPng.create_default_palette()

      assert is_list(palette)
      assert length(palette) == 10

      Enum.each(palette, fn {r, g, b} ->
        assert is_integer(r) and r >= 0 and r <= 255
        assert is_integer(g) and g >= 0 and g <= 255
        assert is_integer(b) and b >= 0 and b <= 255
      end)
    end
  end

  describe "find_palette_index/2" do
    test "finds correct index for existing color" do
      palette = [{255, 255, 255}, {0, 0, 0}, {255, 0, 0}]

      assert ElixirPng.find_palette_index({255, 255, 255}, palette) == 0
      assert ElixirPng.find_palette_index({0, 0, 0}, palette) == 1
      assert ElixirPng.find_palette_index({255, 0, 0}, palette) == 2
    end

    test "returns 0 for non-existing color" do
      palette = [{255, 255, 255}, {0, 0, 0}]

      assert ElixirPng.find_palette_index({128, 128, 128}, palette) == 0
    end
  end
end
