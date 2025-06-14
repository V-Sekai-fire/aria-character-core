# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaTui.Display.Grid do
  @moduledoc """
  Responsive grid system for the Aria TUI display.
  Handles layout calculations, breakpoints, and responsive design.
  """

  # Responsive Grid System Constants
  @grid %{
    # Responsive breakpoints (terminal widths)
    breakpoints: %{
      xs: 70,   # Extra small (mobile-like) - changed from 60
      sm: 80,   # Small (narrow desktop)
      md: 100,  # Medium (standard desktop)
      lg: 120,  # Large (wide desktop)
      xl: 140   # Extra large (ultra-wide)
    },

    # Layout configurations per breakpoint
    layouts: %{
      xs: %{
        columns: 1,
        header_height: 3,
        footer_height: 3,
        content_padding: 1,
        show_borders: true,
        show_controls_help: false
      },
      sm: %{
        columns: 1,
        header_height: 4,
        footer_height: 4,
        content_padding: 1,
        show_borders: true,
        show_controls_help: true
      },
      md: %{
        columns: 2,
        header_height: 4,
        footer_height: 4,
        content_padding: 1,
        show_borders: true,
        show_controls_help: true
      },
      lg: %{
        columns: 2,
        header_height: 5,
        footer_height: 5,
        content_padding: 2,
        show_borders: true,
        show_controls_help: true
      },
      xl: %{
        columns: 2,
        header_height: 5,
        footer_height: 5,
        content_padding: 2,
        show_borders: true,
        show_controls_help: true
      }
    }
  }

  # Minimum terminal size constraints
  @min_width 40
  @min_height 12

  @doc """
  Get the current terminal size.
  """
  def get_terminal_size do
    case System.cmd("tput", ["cols"]) do
      {width_str, 0} ->
        case System.cmd("tput", ["lines"]) do
          {height_str, 0} ->
            width = String.trim(width_str) |> String.to_integer()
            height = String.trim(height_str) |> String.to_integer()
            {max(width, @min_width), max(height, @min_height)}
          _ ->
            {80, 24}
        end
      _ ->
        {80, 24}
    end
  end

  @doc """
  Determine the breakpoint based on terminal size.
  """
  def get_breakpoint({width, _height}) do
    cond do
      width < @grid.breakpoints.xs -> :xs
      width < @grid.breakpoints.sm -> :sm
      width < @grid.breakpoints.md -> :md
      width < @grid.breakpoints.lg -> :lg
      true -> :xl
    end
  end

  @doc """
  Create a layout configuration for the given terminal size.
  """
  def create_layout({width, height} = size) do
    breakpoint = get_breakpoint(size)
    layout_config = @grid.layouts[breakpoint]
    
    columns = layout_config.columns
    column_widths = calculate_column_widths(width, columns)
    
    %{
      breakpoint: breakpoint,
      total_width: width,
      total_height: height,
      columns: columns,
      column_widths: column_widths,
      header_height: layout_config.header_height,
      footer_height: layout_config.footer_height,
      content_height: height - layout_config.header_height - layout_config.footer_height,
      content_padding: layout_config.content_padding,
      show_borders: layout_config.show_borders,
      show_controls_help: layout_config.show_controls_help,
      controls_height: layout_config.footer_height
    }
  end

  @doc """
  Calculate column widths for responsive layout.
  """
  def calculate_column_widths(total_width, columns) when columns > 0 do
    case columns do
      1 ->
        # For single column, use full width (borders handled separately)
        [total_width]
      _ ->
        # For multiple columns, reserve space for borders and separators
        # left border (1) + column separators (columns - 1) + right border (1)
        available_width = total_width - (columns + 1)
        base_width = div(available_width, columns)
        remainder = rem(available_width, columns)
        
        # Distribute remainder across columns (last columns get extra width for tests)
        Enum.map(0..(columns - 1), fn i ->
          if (columns - 1 - i) < remainder do
            base_width + 1
          else
            base_width
          end
        end)
    end
  end

  def calculate_column_widths(_total_width, _columns), do: []

  @doc """
  Get layout information for debugging.
  """
  def get_layout_info do
    @grid
  end

  @doc """
  Determine breakpoint (legacy function for backward compatibility).
  """
  def determine_breakpoint(width) do
    get_breakpoint({width, 24})
  end

  @doc """
  Calculate responsive columns (legacy function for backward compatibility).
  """
  def calculate_responsive_columns(width, _layout_config, _breakpoint) do
    layout = create_layout({width, 24})
    layout.columns
  end

  # Backward compatibility functions for tests
  
  @doc """
  Draw single column content (backward compatibility).
  """
  def draw_single_column_content(state, layout) do
    AriaTui.Display.BackwardCompatibility.draw_single_column_content(state, layout)
  end

  @doc """
  Draw two column content (backward compatibility).
  """
  def draw_two_column_content(state, layout) do
    AriaTui.Display.BackwardCompatibility.draw_two_column_content(state, layout)
  end

  @doc """
  Draw side by side panels (backward compatibility).
  """
  def draw_side_by_side_panels(left_content, right_content, left_width, right_width, height) do
    AriaTui.Display.BackwardCompatibility.draw_side_by_side_panels(left_content, right_content, left_width, right_width, height)
  end
end
