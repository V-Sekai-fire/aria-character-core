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
    
    # Main content area
    content_lines = get_main_content(state, width - 2, content_height)
    
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
    
    # Get content for both columns
    left_content = get_left_panel_content(state, left_width, content_height - 2) # -2 for borders
    right_content = get_right_panel_content(state, right_width, content_height - 2)
    
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

  defp get_main_content(state, width, height) do
    content = [
      " Agents",  # Removed emoji for test compatibility
      "",
      " Current Phase: #{get_phase_display(state)}",
      " Player Status: #{get_player_status(state)}",
      " Resources: #{get_resources_display(state)}",
      "",
      " Map",  # Removed emoji for test compatibility
      " • Complete the current mission",
      " • Maintain resource balance",
      " • Adapt to changing conditions",
      "",
      " Statistics",  # Removed emoji for test compatibility
      " Turns Completed: #{Map.get(state, :turns_completed, 0)}",
      " Actions Taken: #{Map.get(state, :actions_taken, 0)}",
      " Efficiency Rating: #{get_efficiency_rating(state)}"
    ]
    
    # Pad content to fit available space
    content
    |> Enum.take(height)
    |> pad_content_lines(width, height)
  end

  defp get_left_panel_content(state, width, height) do
    content = [
      " Game Status",  # Removed emoji for test compatibility
      "",
      " Turn: #{Map.get(state, :current_turn, 1)}",
      " Phase: #{get_phase_display(state)}",
      " Time: #{Map.get(state, :game_time, "00:00")}",
      "",
      " Character",  # Removed emoji for test compatibility
      " Health: #{Map.get(state, :health, 100)}%",
      " Energy: #{Map.get(state, :energy, 100)}%",
      " Level: #{Map.get(state, :level, 1)}",
      "",
      " Progress",  # Removed emoji for test compatibility
      " Score: #{Map.get(state, :score, 0)}",
      " Achievements: #{Map.get(state, :achievements, 0)}/10"
    ]
    
    pad_content_lines(content, width, height)
  end

  defp get_right_panel_content(state, width, height) do
    content = [
      " Environment",  # Removed emoji for test compatibility
      "",
      " Location: #{Map.get(state, :location, "Unknown")}",
      " Weather: #{Map.get(state, :weather, "Clear")}",
      " Visibility: #{Map.get(state, :visibility, "Good")}",
      "",
      " Combat",  # Removed emoji for test compatibility
      " Enemies Nearby: #{Map.get(state, :enemies_nearby, 0)}",
      " Threat Level: #{get_threat_level(state)}",
      " Last Action: #{Map.get(state, :last_action, "None")}",
      "",
      " Inventory",  # Removed emoji for test compatibility
      " Items: #{Map.get(state, :item_count, 0)}/20",
      " Weight: #{Map.get(state, :weight, 0)}/100 kg"
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

  defp get_phase_display(state) do
    phase = Map.get(state, :phase, "planning")
    case phase do
      "planning" -> Colors.colorize("Planning", :bright_blue)
      "action" -> Colors.colorize("Action", :bright_green)
      "resolution" -> Colors.colorize("Resolution", :bright_yellow)
      _ -> Colors.colorize(String.capitalize(phase), :white)
    end
  end

  defp get_player_status(state) do
    case Map.get(state, :status, :active) do
      :active -> Colors.colorize("Active", :bright_green)
      :paused -> Colors.colorize("Paused", :bright_yellow)
      :ended -> Colors.colorize("Finished", :bright_red)
      _ -> Colors.colorize("Unknown", :gray)
    end
  end

  defp get_resources_display(state) do
    resources = Map.get(state, :resources, %{})
    gold = Map.get(resources, :gold, 0)
    mana = Map.get(resources, :mana, 0)
    "#{Colors.colorize("#{gold}g", :bright_yellow)} #{Colors.colorize("#{mana}m", :bright_blue)}"
  end

  defp get_efficiency_rating(state) do
    rating = Map.get(state, :efficiency, 85)
    cond do
      rating >= 90 -> Colors.colorize("Excellent", :bright_green)
      rating >= 75 -> Colors.colorize("Good", :green)
      rating >= 60 -> Colors.colorize("Fair", :yellow)
      true -> Colors.colorize("Poor", :red)
    end
  end

  defp get_threat_level(state) do
    level = Map.get(state, :threat_level, :low)
    case level do
      :low -> Colors.colorize("Low", :green)
      :medium -> Colors.colorize("Medium", :yellow)
      :high -> Colors.colorize("High", :red)
      :critical -> Colors.colorize("Critical", :bright_red)
      _ -> Colors.colorize("Unknown", :gray)
    end
  end
end
