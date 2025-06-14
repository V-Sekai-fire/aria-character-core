# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaTui.Display do
  @moduledoc """
  Main display module for the Aria TUI system with responsive grid layout.

  This module provides the primary interface for rendering the TUI display,
  coordinating between the grid system, components, and renderer modules.

  ## Content Providers

  The TUI system supports configurable content providers through the
  `AriaTui.ContentProvider` behaviour. To use a custom content provider,
  include a `:content_provider` key in your state map:

      state = %{
        content_provider: MyApp.TuiContentProvider,
        # ... other state data
      }

  Content providers must implement the `AriaTui.ContentProvider` behaviour
  to provide domain-specific formatting for different types of applications.
  """

  alias AriaTui.Display.{Grid, Colors, Components, Renderer}

  @doc """
  Clear the terminal screen.
  """
  def clear_screen do
    IO.puts("\e[2J\e[H")
  end

  @doc """
  Get the current terminal size.
  """
  def get_terminal_size do
    Grid.get_terminal_size()
  end

  @doc """
  Display the complete application state with responsive layout.
  """
  def display_state(state) do
    # Move cursor to home position instead of clearing screen to reduce flickering
    IO.write("\e[H")

    # Get current terminal size and create layout
    terminal_size = get_terminal_size()
    layout = Grid.create_layout(terminal_size)

    # Draw the complete interface
    Components.draw_responsive_header(state, layout)
    Renderer.draw_responsive_content(state, layout)
    Components.draw_responsive_controls(layout)
  end

  # Legacy functions for backward compatibility with existing tests

  @doc """
  Draw responsive header (legacy compatibility).
  """
  def draw_responsive_header(state, layout) do
    Components.draw_responsive_header(state, layout)
  end

  @doc """
  Draw responsive content (legacy compatibility).
  """
  def draw_responsive_content(state, layout) do
    Renderer.draw_responsive_content(state, layout)
  end

  @doc """
  Draw single column content (legacy compatibility).
  """
  def draw_single_column_content(state, layout) do
    Renderer.draw_single_column_content(state, layout)
  end

  @doc """
  Draw two column content (legacy compatibility).
  """
  def draw_two_column_content(state, layout) do
    Renderer.draw_two_column_content(state, layout)
  end

  @doc """
  Draw side by side panels (legacy compatibility).
  """
  def draw_side_by_side_panels(left_content, right_content, left_width, right_width, height) do
    Renderer.draw_side_by_side_panels(left_content, right_content, left_width, right_width, height)
  end

  @doc """
  Draw side by side panels with layout (legacy compatibility).
  """
  def draw_side_by_side_panels(left_content, right_content, layout) do
    left_width = Enum.at(layout.column_widths, 0, 30)
    right_width = Enum.at(layout.column_widths, 1, 30)
    height = Map.get(layout, :content_height, length(left_content))

    draw_side_by_side_panels(left_content, right_content, left_width, right_width, height)
  end

  @doc """
  Draw compact header (legacy compatibility).
  Accepts either a layout map or just a width integer.
  """
  def draw_compact_header(state, layout) when is_map(layout) do
    Components.draw_compact_header(state, layout)
  end

  def draw_compact_header(state, width) when is_integer(width) do
    # Create a minimal layout structure
    layout = %{total_width: width, breakpoint: :xs}
    Components.draw_compact_header(state, layout)
  end

  @doc """
  Draw enhanced header (legacy compatibility).
  """
  def draw_enhanced_header(state, layout) do
    Components.draw_enhanced_header(state, layout)
  end

  @doc """
  Draw enhanced header with width and layout (legacy compatibility).
  """
  def draw_enhanced_header(state, width, layout) do
    # Create a temporary layout with the specified width
    temp_layout = Map.put(layout, :total_width, width)
    Components.draw_enhanced_header(state, temp_layout)
  end

  @doc """
  Draw responsive controls (legacy compatibility).
  """
  def draw_responsive_controls(layout) do
    Components.draw_responsive_controls(layout)
  end

  @doc """
  Extract panel content (legacy compatibility).
  """
  def extract_panel_content(panel_text) do
    Renderer.extract_panel_content(panel_text)
  end

  @doc """
  Extract panel content with padding (legacy compatibility).
  """
  def extract_panel_content(panel_text, width) do
    content = extract_panel_content(panel_text)

    # Ensure at least one line even for empty content
    content = if Enum.empty?(content), do: [""], else: content

    # Pad to specified width
    Enum.map(content, fn line ->
      current_length = Colors.visual_length(line)
      padding = width - current_length
      line <> String.duplicate(" ", max(0, padding))
    end)
  end

  @doc """
  Count ANSI characters in a string (legacy compatibility).
  """
  def count_ansi_chars(string) do
    Colors.count_ansi_chars(string)
  end

  @doc """
  Clean ANSI codes from text (legacy compatibility).
  """
  def clean_ansi_codes(text) do
    Regex.replace(~r/\e\[[0-9;]*m/, text, "")
  end

  @doc """
  Format agent status (legacy compatibility).
  """
  def format_agent_status(status) do
    colors = Colors.colors()
    case status do
      :alive -> "#{colors.bright_green}🟢#{colors.reset} Alive"
      :dead -> "#{colors.bright_red}🔴#{colors.reset} Dead"
      :unknown -> "#{colors.gray}⚪#{colors.reset} Unknown"
      _ -> "#{colors.gray}⚪#{colors.reset} Unknown"
    end
  end

  @doc """
  Get agent color (legacy compatibility - now using generic names).
  """
  def get_agent_color(agent_name) do
    colors = Colors.colors()
    case agent_name do
      "Agent_A" -> colors.bright_green
      "Agent_B" -> colors.bright_yellow
      "Agent_C" -> colors.bright_blue
      "Agent_D" -> colors.bright_red
      _ -> colors.white
    end
  end

  @doc """
  Get enhanced map symbol (legacy compatibility).
  """
  def get_enhanced_map_symbol(agent_or_nil, {x, y}) do
    case agent_or_nil do
      nil ->
        # Terrain symbol based on position
        case rem(x + y, 4) do
          0 -> "▪"  # Changed from "." to "▪"
          1 -> "·"  # Changed from "~" to "·"
          2 -> "▪"  # Changed from "^" to "▪"
          _ -> "·"
        end
      agent_name when is_binary(agent_name) ->
        # Enhanced symbols with generic agents
        case agent_name do
          "Agent_A" -> "⚡"  # Special symbol for Agent A
          "Agent_B" -> "◆"   # Special symbol for Agent B  
          "Agent_C" -> "⭐"  # Special symbol for Agent C
          "Agent_D" -> "❄️"  # Special symbol for Agent D
          _ ->
            first_char = String.first(agent_name) |> String.upcase()
            color = get_agent_color(agent_name)
            "#{color}#{first_char}#{Colors.get(:reset)}"
        end
      %{name: name} ->
        get_enhanced_map_symbol(name, {x, y})
      _ ->
        "?"
    end
  end

  @doc """
  Get compact map symbol (legacy compatibility).
  """
  def get_compact_map_symbol(agent, {_x, _y}) do
    case agent do
      nil -> "."
      %{name: name} ->
        first_char = String.first(name) |> String.upcase()
        color = get_agent_color(name)
        "#{color}#{first_char}#{Colors.get(:reset)}"
      _ -> "?"
    end
  end

  # Note: Grid module is now available as AriaTui.Display.Grid
  # For backward compatibility, tests should use AriaTui.Display.Grid directly
end
