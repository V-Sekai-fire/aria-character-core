# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaTui.Display.Renderer do
  @moduledoc """
  Content rendering utilities for the Aria TUI system.
  Handles drawing panels, content areas, and complex layouts.
  """

  alias AriaTui.Display.Colors

  @doc """
  Draw responsive content based on layout configuration.
  Uses content provider module if specified in state, otherwise falls back to default.
  """
  def draw_responsive_content(state, layout) do
    case layout.columns do
      1 -> draw_single_column_content(state, layout)
      2 -> draw_two_column_content(state, layout)
      _ -> draw_multi_column_content(state, layout)
    end
  end

  @doc """
  Draw single column content layout.
  """
  def draw_single_column_content(state, layout) do
    colors = Colors.colors()
    width = layout.total_width
    content_height = layout.content_height

    # Main content area - use configurable content provider
    content_lines = get_content_from_provider(state, :main_content, width - 2, content_height)

    Enum.each(content_lines, fn line ->
      line_padding = width - Colors.visual_length(line) - 2
      IO.puts("#{colors.bright_cyan}│#{line}#{String.duplicate(" ", max(0, line_padding))}#{colors.bright_cyan}│#{colors.reset}")
    end)

    # Fill remaining lines
    remaining_lines = content_height - length(content_lines)
    if remaining_lines > 0 do
      empty_line = String.duplicate(" ", width - 2)
      Enum.each(1..remaining_lines, fn _ ->
        IO.puts("#{colors.bright_cyan}│#{empty_line}#{colors.bright_cyan}│#{colors.reset}")
      end)
    end
  end

  @doc """
  Draw two column content layout.
  """
  def draw_two_column_content(state, layout) do
    colors = Colors.colors()
    content_height = layout.content_height
    [left_width, right_width] = layout.column_widths

    # Draw top border with column separator
    IO.puts("#{colors.bright_cyan}┌#{String.duplicate("─", left_width)}┬#{String.duplicate("─", right_width)}┐#{colors.reset}")

    # Get content for both columns using configurable providers
    left_content = get_content_from_provider(state, :left_panel, left_width, content_height - 2) # -2 for borders
    right_content = get_content_from_provider(state, :right_panel, right_width, content_height - 2)

    # Draw side by side
    draw_side_by_side_panels(left_content, right_content, left_width, right_width, content_height - 2)

    # Draw bottom border
    IO.puts("#{colors.bright_cyan}└#{String.duplicate("─", left_width)}┴#{String.duplicate("─", right_width)}┘#{colors.reset}")
  end

  @doc """
  Draw multiple column content (for future expansion).
  """
  def draw_multi_column_content(state, layout) do
    # For now, fallback to two column
    draw_two_column_content(state, layout)
  end

  @doc """
  Draw two panels side by side.
  """
  def draw_side_by_side_panels(left_content, right_content, left_width, right_width, height) do
    colors = Colors.colors()

    # Ensure both content arrays have the same length
    max_lines = max(length(left_content), length(right_content))
    left_padded = pad_content_lines(left_content, left_width, max_lines)
    right_padded = pad_content_lines(right_content, right_width, max_lines)

    # Draw each line
    left_padded
    |> Enum.zip(right_padded)
    |> Enum.each(fn {left_line, right_line} ->
      IO.puts("#{colors.bright_cyan}│#{left_line}│#{right_line}│#{colors.reset}")
    end)

    # Fill remaining height if needed
    lines_drawn = max_lines
    remaining_lines = height - lines_drawn
    if remaining_lines > 0 do
      empty_left = String.duplicate(" ", left_width)
      empty_right = String.duplicate(" ", right_width)
      Enum.each(1..remaining_lines, fn _ ->
        IO.puts("#{colors.bright_cyan}│#{empty_left}│#{empty_right}│#{colors.reset}")
      end)
    end
  end

  @doc """
  Extract content from bordered panels (for testing compatibility).
  """
  def extract_panel_content(panel_text) do
    panel_text
    |> String.split("\n", trim: true)
    |> Enum.drop(1)  # Remove top border
    |> Enum.drop(-1) # Remove bottom border
    |> Enum.map(fn line ->
      # Remove side borders
      line
      |> String.trim_leading("│")
      |> String.trim_trailing("│")
      |> String.trim()
    end)
    |> Enum.reject(&(&1 == "" or String.match?(&1, ~r/^[─┼├┤]+$/)))
  end

  # Private helper functions

  # Get content from a configurable content provider.
  defp get_content_from_provider(state, content_type, width, height) do
    # Check if state has a content provider module specified
    content_provider = Map.get(state, :content_provider)

    case content_provider do
      nil ->
        # Use default content provider
        get_default_content(state, content_type, width, height)

      module when is_atom(module) ->
        # Use specified module implementing ContentProvider behaviour
        if Code.ensure_loaded?(module) do
          case content_type do
            :main_content ->
              apply(module, :get_main_content, [state, width, height])
            :left_panel ->
              apply(module, :get_left_panel_content, [state, width, height])
            :right_panel ->
              apply(module, :get_right_panel_content, [state, width, height])
            _ ->
              get_default_content(state, content_type, width, height)
          end
        else
          get_default_content(state, content_type, width, height)
        end

      _ ->
        get_default_content(state, content_type, width, height)
    end
  rescue
    # If provider module doesn't implement the required function, fall back to default
    UndefinedFunctionError ->
      get_default_content(state, content_type, width, height)
    _ ->
      get_default_content(state, content_type, width, height)
  end

  defp get_default_content(state, content_type, width, height) do
    case content_type do
      :main_content -> get_generic_main_content(state, width, height)
      :left_panel -> get_generic_left_panel_content(state, width, height)
      :right_panel -> get_generic_right_panel_content(state, width, height)
      _ -> ["Unknown content type: #{content_type}"]
    end
  end

  defp get_generic_main_content(state, width, height) do
    content = [
      " TUI System Status",
      "",
      " Current State: #{get_system_status(state)}",
      " System Load: #{get_system_load(state)}%",
      " Uptime: #{get_uptime(state)}",
      "",
      " Components",
      " • TUI renderer operational",
      " • Content provider active",
      " • Terminal interface ready",
      "",
      " Information",
      " This is a generic TUI system.",
      " Use a content provider for custom display.",
      " Press Q to quit."
    ]

    # Pad content to fit available space
    content
    |> Enum.take(height)
    |> pad_content_lines(width, height)
  end

  defp get_generic_left_panel_content(state, width, height) do
    content = [
      " System Info",
      "",
      " Status: #{get_system_status(state)}",
      " Mode: #{Map.get(state, :mode, "default")}",
      " Tick: #{Map.get(state, :tick_count, 0)}",
      "",
      " Resources",
      " Memory: Good",
      " CPU: Normal",
      " I/O: Ready",
      "",
      " Metrics",
      " Redraws: #{Map.get(state, :redraws, 0)}",
      " Updates: #{Map.get(state, :updates, 0)}"
    ]

    pad_content_lines(content, width, height)
  end

  defp get_generic_right_panel_content(_state, width, height) do
    content = [
      " Controls",
      "",
      " Navigation:",
      " • Use arrow keys",
      " • Press SPACE to interact",
      " • Press Q to quit",
      "",
      " System",
      " Terminal: #{get_terminal_info()}",
      " Display: Active",
      " Input: Ready",
      "",
      " Help",
      " This is a fallback display.",
      " Configure a content provider."
    ]

    pad_content_lines(content, width, height)
  end

  defp pad_content_lines(content, width, target_height) do
    padded_lines = Enum.map(content, fn line ->
      visual_len = Colors.visual_length(line)
      padding = width - visual_len
      line <> String.duplicate(" ", max(0, padding))
    end)

    # Ensure we have exactly target_height lines
    current_length = length(padded_lines)
    empty_line = String.duplicate(" ", width)

    cond do
      current_length < target_height ->
        padded_lines ++ List.duplicate(empty_line, target_height - current_length)
      current_length > target_height ->
        Enum.take(padded_lines, target_height)
      true ->
        padded_lines
    end
  end

  defp get_system_status(state) do
    case Map.get(state, :status, "active") do
      "active" -> Colors.colorize("Active", :bright_green)
      "paused" -> Colors.colorize("Paused", :bright_yellow)
      "stopped" -> Colors.colorize("Stopped", :bright_red)
      _ -> Colors.colorize("Unknown", :gray)
    end
  end

  defp get_system_load(state) do
    Map.get(state, :system_load, 15)
  end

  defp get_uptime(state) do
    uptime_seconds = Map.get(state, :uptime_seconds, 0)
    minutes = div(uptime_seconds, 60)
    seconds = rem(uptime_seconds, 60)
    "#{minutes}:#{String.pad_leading("#{seconds}", 2, "0")}"
  end

  defp get_terminal_info do
    case :os.type() do
      {:unix, _} -> "Unix Terminal"
      {:win32, _} -> "Windows Terminal"
      _ -> "Terminal"
    end
  end
end
