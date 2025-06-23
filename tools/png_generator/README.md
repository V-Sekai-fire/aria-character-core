# PNG Generator

Pure Elixir PNG generation for timeline and Gantt chart visualization.

## Overview

This standalone tool generates PNG images from schedule data without requiring any external dependencies. It creates timeline visualizations with color-coded activities and time grids using pure Elixir code.

## Features

- **Pure Elixir implementation** - No external image libraries required
- **Timeline visualization** - Generates Gantt chart-style timelines
- **Color-coded activities** - Different colors for different activity types
- **Configurable output** - Customizable file names and output directories
- **Standalone tool** - Can be used independently of the main project

## Installation

```bash
cd tools/png_generator
mix deps.get
```

## Usage

```elixir
# Basic usage
schedule = [
  %{"id" => "A1", "start_time" => 0, "duration" => 3},
  %{"id" => "B1", "start_time" => 2, "duration" => 4},
  %{"id" => "C1", "start_time" => 5, "duration" => 2}
]

{:ok, path} = PngGenerator.generate_timeline_png(schedule)
IO.puts("Timeline saved to: #{path}")

# Custom filename
{:ok, path} = PngGenerator.generate_timeline_png(schedule, "my_timeline.png")
```

## Configuration

The tool uses environment-specific configuration:

- **Development**: Images saved to `priv/dev_images/`
- **Test**: Images saved to `tmp/test_images/`
- **Production**: Images saved to `priv/images/`

## Activity Color Coding

Activities are automatically color-coded based on their ID prefix:

- **A-prefix**: Blue (`#3498db`)
- **B-prefix**: Green (`#2ecc71`)
- **C-prefix**: Orange (`#e67e22`)
- **D-prefix**: Purple (`#9b59b6`)
- **E-prefix**: Red (`#e74c3c`)
- **Other**: Gray (`#95a5a6`)

## Output Format

Generated PNG files include:

- Time grid with unit markers
- Color-coded activity bars
- Automatic sizing based on schedule duration
- Timestamp-based filenames for uniqueness

## Development

```bash
# Run tests
mix test

# Check code quality
mix credo

# Generate documentation
mix docs
```

## License

MIT License - see LICENSE file for details.
