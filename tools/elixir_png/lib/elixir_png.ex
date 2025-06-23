defmodule ElixirPng do
  @moduledoc """
  Pure Elixir PNG encoding library.
  Creates PNG files without external dependencies using only Elixir and Erlang standard library.
  """

  @png_signature <<137, 80, 78, 71, 13, 10, 26, 10>>

  @doc """
  Creates a PNG binary from pixel data and palette.
  """
  @spec create_png_binary(pos_integer(), pos_integer(), [tuple()], [tuple()]) :: binary()
  def create_png_binary(width, height, pixel_data, palette) do
    indexed_data = Enum.map(pixel_data, fn color -> find_palette_index(color, palette) end)

    ihdr = create_ihdr_chunk(width, height)
    plte = create_plte_chunk(palette)
    idat = create_idat_chunk(indexed_data, width)
    iend = create_iend_chunk()

    @png_signature <> ihdr <> plte <> idat <> iend
  end

  @doc """
  Writes PNG binary data to a file.
  """
  @spec write_png_file(binary(), String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def write_png_file(png_binary, filepath) do
    filepath |> Path.dirname() |> File.mkdir_p!()

    case File.write(filepath, png_binary) do
      :ok -> {:ok, filepath}
      {:error, reason} -> {:error, "Failed to write PNG: #{reason}"}
    end
  end

  @doc """
  Finds the index of a color in the palette.
  """
  @spec find_palette_index(tuple(), [tuple()]) :: non_neg_integer()
  def find_palette_index(color, palette) do
    case Enum.find_index(palette, fn pal_color -> pal_color == color end) do
      nil -> 0
      index -> index
    end
  end

  # PNG chunk creation functions

  defp create_ihdr_chunk(width, height) do
    data = <<width::32, height::32, 8::8, 3::8, 0::8, 0::8, 0::8>>
    create_chunk("IHDR", data)
  end

  defp create_plte_chunk(palette) do
    data = Enum.map_join(palette, "", fn {r, g, b} -> <<r::8, g::8, b::8>> end)
    create_chunk("PLTE", data)
  end

  defp create_idat_chunk(indexed_data, width) do
    rows =
      indexed_data
      |> Enum.chunk_every(width)
      |> Enum.map(fn row -> [0 | row] end)
      |> List.flatten()
      |> Enum.map_join("", &<<&1::8>>)

    compressed = :zlib.compress(rows)
    create_chunk("IDAT", compressed)
  end

  defp create_iend_chunk do
    create_chunk("IEND", "")
  end

  defp create_chunk(type, data) do
    length = byte_size(data)
    crc = :erlang.crc32(type <> data)
    <<length::32, type::binary, data::binary, crc::32>>
  end
end
