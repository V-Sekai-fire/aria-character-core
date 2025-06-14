# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaTui.DefaultContentProvider do
  @moduledoc """
  Default content provider for TUI component testing and validation.

  This content provider demonstrates the TUI system's capabilities and provides
  interactive testing for grid layouts, responsive design, color schemes,
  and component behavior. It serves as both a demonstration and validation tool
  for the TUI system.
  """

  @behaviour AriaTui.ContentProvider

  alias AriaTui.Display.{Colors, Grid}

  @impl AriaTui.ContentProvider
  def get_main_content(state, width, height) do
    test_mode = Map.get(state, :test_mode, "overview")

    case test_mode do
      "colors" -> get_color_test_content(width, height)
      "layout" -> get_layout_test_content(width, height)
      "responsive" -> get_responsive_test_content(width, height)
      "components" -> get_component_test_content(width, height)
      _ -> get_overview_test_content(state, width, height)
    end
  end

  @impl AriaTui.ContentProvider
  def get_left_panel_content(state, width, height) do
    current_test = Map.get(state, :test_mode, "overview")
    breakpoint = Grid.get_breakpoint(width)

    content = [
      " #{Colors.colorize("🧪 TUI Test Suite", :bright_cyan)}",
      "",
      " #{Colors.colorize("Current Test:", :bright_white)}",
      " #{current_test}",
      "",
      " #{Colors.colorize("Layout Info:", :bright_white)}",
      " Breakpoint: #{breakpoint}",
      " Panel Width: #{width}",
      " Panel Height: #{height}",
      "",
      " #{Colors.colorize("Grid System:", :bright_white)}",
      " • XS: < 60 cols",
      " • SM: 60-79 cols",
      " • MD: 80-119 cols",
      " • LG: 120-159 cols",
      " • XL: ≥ 160 cols",
      "",
      " #{Colors.colorize("Status:", :bright_green)}",
      " All systems operational"
    ]

    pad_content_lines(content, width, height)
  end

  @impl AriaTui.ContentProvider
  def get_right_panel_content(state, width, height) do
    tick_count = Map.get(state, :tick_count, 0)

    content = [
      " #{Colors.colorize("🎮 Test Controls", :bright_yellow)}",
      "",
      " #{Colors.colorize("Navigation:", :bright_white)}",
      " 1: Color Tests",
      " 2: Layout Tests",
      " 3: Responsive Tests",
      " 4: Component Tests",
      " 0: Overview",
      "",
      " #{Colors.colorize("Actions:", :bright_white)}",
      " R: Refresh display",
      " SPACE: Pause/Resume",
      " Q: Quit",
      "",
      " #{Colors.colorize("Runtime Info:", :bright_white)}",
      " Ticks: #{tick_count}",
      " Last Update: #{format_timestamp()}",
      "",
      " #{Colors.colorize("Test Results:", :bright_white)}",
      " #{get_test_status(state)}"
    ]

    pad_content_lines(content, width, height)
  end

  @impl AriaTui.ContentProvider
  def get_header_content(state, layout) do
    test_mode = Map.get(state, :test_mode, "overview")
    breakpoint = Map.get(layout, :breakpoint, :unknown)

    [
      "#{Colors.colorize("🎯 Aria TUI Component Test Suite", :bright_white)} | #{Colors.colorize("Mode: #{test_mode}", :bright_cyan)} | #{Colors.colorize("Layout: #{breakpoint}", :bright_green)}"
    ]
  end

  @impl AriaTui.ContentProvider
  def get_footer_content(_state, _layout) do
    [
      Colors.colorize("[1-4: Tests] [0: Overview] [R: Refresh] [SPACE: Pause] [Q: Quit]", :gray)
    ]
  end

  # Test content generators

  defp get_overview_test_content(_state, width, height) do
    content = [
      " #{Colors.colorize("🎯 TUI Component Test Suite", :bright_white)}",
      "",
      " #{Colors.colorize("Purpose:", :bright_cyan)}",
      " This interface validates TUI components and provides",
      " interactive testing for layout systems, color schemes,",
      " responsiveness, and component behavior.",
      "",
      " #{Colors.colorize("Available Tests:", :bright_yellow)}",
      " 1. Color System - Test all color combinations",
      " 2. Layout Engine - Validate grid and alignment",
      " 3. Responsive Design - Test breakpoint behavior",
      " 4. Component Library - Test individual components",
      "",
      " #{Colors.colorize("Current Terminal:", :bright_green)}",
      " Dimensions: #{width}x#{height}",
      " Breakpoint: #{Grid.get_breakpoint(width)}",
      " Columns: #{get_column_count(width)}",
      "",
      " #{Colors.colorize("System Status:", :bright_white)}",
      " Grid System: #{Colors.colorize("✓ Active", :green)}",
      " Color Engine: #{Colors.colorize("✓ Active", :green)}",
      " Event Handler: #{Colors.colorize("✓ Active", :green)}",
      "",
      " Press 1-4 to run specific tests, or use controls →"
    ]

    pad_content_lines(content, width, height)
  end

  defp get_color_test_content(width, height) do
    content = [
      " #{Colors.colorize("🎨 Color System Test", :bright_white)}",
      "",
      " #{Colors.colorize("Standard Colors:", :bright_cyan)}",
      " #{Colors.colorize("■ Red", :red)} #{Colors.colorize("■ Green", :green)} #{Colors.colorize("■ Blue", :blue)} #{Colors.colorize("■ Yellow", :yellow)}",
      " #{Colors.colorize("■ Magenta", :magenta)} #{Colors.colorize("■ Cyan", :cyan)} #{Colors.colorize("■ White", :white)} #{Colors.colorize("■ Gray", :gray)}",
      "",
      " #{Colors.colorize("Bright Colors:", :bright_cyan)}",
      " #{Colors.colorize("■ Bright Red", :bright_red)} #{Colors.colorize("■ Bright Green", :bright_green)} #{Colors.colorize("■ Bright Blue", :bright_blue)}",
      " #{Colors.colorize("■ Bright Yellow", :bright_yellow)} #{Colors.colorize("■ Bright Magenta", :bright_magenta)} #{Colors.colorize("■ Bright Cyan", :bright_cyan)}",
      " #{Colors.colorize("■ Bright White", :bright_white)}",
      "",
      " #{Colors.colorize("Text Effects:", :bright_cyan)}",
      " Normal text",
      " #{Colors.colorize("Bold text", :bright_white)}",
      " #{Colors.colorize("Important text", :bright_yellow)}",
      " #{Colors.colorize("Warning text", :bright_red)}",
      " #{Colors.colorize("Success text", :bright_green)}",
      "",
      " #{Colors.colorize("Visual Length Test:", :bright_cyan)}",
      " Raw: 'Hello #{Colors.colorize("colored", :bright_red)} world!'",
      " Length: #{Colors.visual_length("Hello #{Colors.colorize("colored", :bright_red)} world!")} chars"
    ]

    pad_content_lines(content, width, height)
  end

  defp get_layout_test_content(width, height) do
    layout = Grid.create_layout({width, height})

    content = [
      " #{Colors.colorize("📐 Layout Engine Test", :bright_white)}",
      "",
      " #{Colors.colorize("Grid Configuration:", :bright_cyan)}",
      " Breakpoint: #{layout.breakpoint}",
      " Total Width: #{layout.total_width}",
      " Content Height: #{layout.content_height}",
      " Column Count: #{layout.columns}",
      "",
      " #{Colors.colorize("Column Widths:", :bright_cyan)}",
      get_column_width_display(layout),
      "",
      " #{Colors.colorize("Alignment Test:", :bright_cyan)}",
      " ◄─────── Left aligned text",
      "          Center aligned text          ",
      "                    Right aligned text ───────►",
      "",
      " #{Colors.colorize("Border Test:", :bright_cyan)}",
      " ┌─────────────────────────────────────┐",
      " │ Bordered content area               │",
      " │ With multiple lines                 │",
      " └─────────────────────────────────────┘",
      "",
      " #{Colors.colorize("Padding Test:", :bright_cyan)}",
      "   Indented content with padding",
      "     More deeply indented content"
    ]

    pad_content_lines(content, width, height)
  end

  defp get_responsive_test_content(width, height) do
    breakpoint = Grid.get_breakpoint(width)

    [
      " #{Colors.colorize("📱 Responsive Design Test", :bright_white)}",
      "",
      " #{Colors.colorize("Current Breakpoint: #{breakpoint}", :bright_green)}",
      "",
      case breakpoint do
        :xs -> get_xs_responsive_content()
        :sm -> get_sm_responsive_content()
        :md -> get_md_responsive_content()
        :lg -> get_lg_responsive_content()
        :xl -> get_xl_responsive_content()
      end
    ]
    |> List.flatten()
    |> pad_content_lines(width, height)
  end

  defp get_component_test_content(width, height) do
    content = [
      " #{Colors.colorize("🧩 Component Library Test", :bright_white)}",
      "",
      " #{Colors.colorize("Progress Bars:", :bright_cyan)}",
      " #{get_progress_bar(75, 20)} 75%",
      " #{get_progress_bar(45, 20)} 45%",
      " #{get_progress_bar(90, 20)} 90%",
      "",
      " #{Colors.colorize("Status Indicators:", :bright_cyan)}",
      " #{Colors.colorize("● Online", :bright_green)}   #{Colors.colorize("● Warning", :bright_yellow)}   #{Colors.colorize("● Error", :bright_red)}   #{Colors.colorize("● Unknown", :gray)}",
      "",
      " #{Colors.colorize("Data Tables:", :bright_cyan)}",
      " ┌─────────────┬─────────┬────────┐",
      " │ Component   │ Status  │ Count  │",
      " ├─────────────┼─────────┼────────┤",
      " │ Grid        │ #{Colors.colorize("Active", :green)}  │    1   │",
      " │ Colors      │ #{Colors.colorize("Active", :green)}  │   16   │",
      " │ Events      │ #{Colors.colorize("Active", :green)}  │    3   │",
      " └─────────────┴─────────┴────────┘",
      "",
      " #{Colors.colorize("Lists and Menus:", :bright_cyan)}",
      " ▶ Active item",
      "   Inactive item",
      "   Another item",
      " ▶ Selected item"
    ]

    pad_content_lines(content, width, height)
  end

  # Helper functions

  defp get_column_width_display(layout) do
    if layout.columns == 1 do
      " Single column: #{layout.total_width} chars"
    else
      widths = Grid.calculate_column_widths(layout.total_width, layout.columns)
      " Left: #{Enum.at(widths, 0)} | Right: #{Enum.at(widths, 1)} chars"
    end
  end

  defp get_xs_responsive_content do
    [
      " #{Colors.colorize("Extra Small Layout", :bright_yellow)}",
      " • Single column only",
      " • Minimal content",
      " • Touch-friendly",
      " • Essential info only"
    ]
  end

  defp get_sm_responsive_content do
    [
      " #{Colors.colorize("Small Layout", :bright_yellow)}",
      " • Single column preferred",
      " • Compact presentation",
      " • Key information visible",
      " • Simple navigation"
    ]
  end

  defp get_md_responsive_content do
    [
      " #{Colors.colorize("Medium Layout", :bright_yellow)}",
      " • Two column layout",
      " • Balanced content distribution",
      " • Enhanced readability",
      " • Full feature set available"
    ]
  end

  defp get_lg_responsive_content do
    [
      " #{Colors.colorize("Large Layout", :bright_yellow)}",
      " • Two column layout",
      " • Expanded content areas",
      " • Rich information display",
      " • Advanced controls visible"
    ]
  end

  defp get_xl_responsive_content do
    [
      " #{Colors.colorize("Extra Large Layout", :bright_yellow)}",
      " • Two column layout",
      " • Maximum content density",
      " • Full feature visibility",
      " • Desktop-optimized experience"
    ]
  end

  defp get_progress_bar(percentage, width) do
    filled = trunc(percentage * width / 100)
    empty = width - filled

    "#{Colors.colorize(String.duplicate("█", filled), :bright_green)}#{Colors.colorize(String.duplicate("░", empty), :gray)}"
  end

  defp get_column_count(width) do
    layout = Grid.create_layout({width, 20})
    layout.columns
  end

  defp format_timestamp do
    DateTime.utc_now()
    |> DateTime.to_time()
    |> Time.to_string()
    |> String.slice(0, 8)
  end

  defp get_test_status(state) do
    case Map.get(state, :test_mode, "overview") do
      "colors" -> "#{Colors.colorize("✓", :green)} Color system"
      "layout" -> "#{Colors.colorize("✓", :green)} Layout engine"
      "responsive" -> "#{Colors.colorize("✓", :green)} Responsive design"
      "components" -> "#{Colors.colorize("✓", :green)} Components"
      _ -> "#{Colors.colorize("●", :yellow)} Ready for testing"
    end
  end

  # Private helper functions

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
end
