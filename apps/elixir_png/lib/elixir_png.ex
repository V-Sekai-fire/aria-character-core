# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule ElixirPng do
  @moduledoc """
  Pure Elixir PNG binary format generation library.

  Provides low-level PNG file creation capabilities without external dependencies.
  Handles PNG chunk creation, compression, and binary format specification.
  """

  @png_signature <<137, 80, 78, 71, 13, 10, 26, 10>>

  @doc """
  Creates a PNG binary from pixel data.

  ## Parameters
  - width: Image width in pixels
  - height: Image height in pixels
  - pixel_data: List of {r, g, b} tuples representing pixel colors
  - options: Optional configuration (palette, color_type, etc.)

  ## Returns
  Binary PNG data ready to be written to file
  """
  def create_png(width, height, pixel_data, options \\ []) do
    palette = Keyword.get(options, :palette, create_default_palette())

    indexed_data =
      Enum.map(pixel_data, fn {r, g, b} -> find_palette_index({r, g, b}, palette) end)

    ihdr = create_ihdr_chunk(width, height)
    plte = create_plte_chunk(palette)
    idat = create_idat_chunk(indexed_data, width)
    iend = create_iend_chunk()

    @png_signature <> ihdr <> plte <> idat <> iend
  end

  @doc """
  Creates a default color palette for indexed PNG images.
  """
  def create_default_palette do
    [
      {255, 255, 255},  # background/white
      {200, 200, 200},  # grid/light gray
      {0, 0, 0},        # text/black
      {52, 152, 219},   # blue
      {46, 204, 113},   # green
      {230, 126, 34},   # orange
      {155, 89, 182},   # purple
      {231, 76, 60},    # red
      {192, 57, 43},    # dark red
      {149, 165, 166}   # gray
    ]
  end

  @doc """
  Finds the index of a color in the palette.
  """
  def find_palette_index(color, palette) do
    case Enum.find_index(palette, fn pal_color -> pal_color == color end) do
      nil -> 0
      index -> index
    end
  end

  # Private functions for PNG chunk creation

  defp create_ihdr_chunk(width, height) do
    # PNG IHDR chunk: width, height, bit_depth=8, color_type=3 (indexed),
    # compression=0, filter=0, interlace=0
    data = <<width::32, height::32, 8::8, 3::8, 0::8, 0::8, 0::8>>
    create_chunk("IHDR", data)
  end

  defp create_plte_chunk(palette) do
    # PNG PLTE chunk: RGB values for each palette entry
    data = Enum.map_join(palette, "", fn {r, g, b} -> <<r::8, g::8, b::8>> end)
    create_chunk("PLTE", data)
  end

  defp create_idat_chunk(indexed_data, width) do
    # PNG IDAT chunk: compressed image data with filter bytes
    rows = if width > 0 and length(indexed_data) > 0 do
      indexed_data
      |> Enum.chunk_every(width)
      |> Enum.map(fn row -> [0 | row] end)  # Add filter byte (0 = None filter)
      |> List.flatten()
      |> Enum.map_join("", &<<&1::8>>)
    else
      ""
    end

    compressed = :zlib.compress(rows)
    create_chunk("IDAT", compressed)
  end

  defp create_iend_chunk do
    # PNG IEND chunk: marks end of PNG file
    create_chunk("IEND", "")
  end

  defp create_chunk(type, data) do
    # PNG chunk format: length (4 bytes) + type (4 bytes) + data + CRC (4 bytes)
    length = byte_size(data)
    crc = :erlang.crc32(type <> data)
    <<length::32, type::binary, data::binary, crc::32>>
  end
end
