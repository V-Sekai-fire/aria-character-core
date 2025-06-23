# ElixirPng

Pure Elixir PNG encoding library that creates PNG files without external dependencies.

## Features

- Pure Elixir implementation using only standard library
- Indexed color mode for efficient file sizes
- Custom palette support
- No external dependencies beyond Erlang/OTP

## Installation

Add `elixir_png` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:elixir_png, path: "../elixir_png"}
  ]
end
```

## Usage

### Basic PNG Creation

```elixir
# Define a color palette
palette = [
  {255, 255, 255},  # White
  {255, 0, 0},      # Red
  {0, 255, 0},      # Green
  {0, 0, 255}       # Blue
]

# Create pixel data (2x2 image)
pixels = [
  {255, 255, 255}, {255, 0, 0},
  {0, 255, 0}, {0, 0, 255}
]

# Generate PNG binary
png_binary = ElixirPng.create_png_binary(2, 2, pixels, palette)

# Write to file
{:ok, filepath} = ElixirPng.write_png_file(png_binary, "output.png")
```

### API Reference

#### `create_png_binary/4`

Creates a PNG binary from pixel data and palette.

**Parameters:**
- `width` - Image width in pixels
- `height` - Image height in pixels  
- `pixel_data` - List of RGB tuples representing pixel colors
- `palette` - List of RGB tuples defining the color palette

**Returns:** Binary PNG data

#### `write_png_file/2`

Writes PNG binary data to a file.

**Parameters:**
- `png_binary` - PNG binary data from `create_png_binary/4`
- `filepath` - Path where the PNG file should be written

**Returns:** `{:ok, filepath}` on success, `{:error, reason}` on failure

#### `find_palette_index/2`

Finds the index of a color in the palette.

**Parameters:**
- `color` - RGB tuple to find
- `palette` - List of RGB tuples

**Returns:** Index of color in palette (0 if not found)

## Technical Details

This library implements the PNG specification using:

- **IHDR chunk**: Image header with dimensions and color type
- **PLTE chunk**: Color palette for indexed color mode
- **IDAT chunk**: Compressed image data using zlib
- **IEND chunk**: End of image marker

The implementation uses indexed color mode (color type 3) which is efficient for images with limited color palettes.

## Configuration

The library can be configured in your application's config files:

```elixir
config :elixir_png,
  default_output_dir: "priv/images"
```

## License

This project is licensed under the same terms as the parent project.
