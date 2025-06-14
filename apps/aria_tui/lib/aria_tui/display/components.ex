# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaTui.Display.Components do
  @moduledoc """
  UI components for the Aria TUI system.
  Provides reusable components like headers, panels, controls, etc.
  """

  alias AriaTui.Display.Colors

  @doc """
  Draw a responsive header based on layout configuration.
  """
  def draw_responsive_header(state, layout) do
    case layout.breakpoint do
      :xs ->
        draw_compact_header(state, layout)
      :sm ->
        draw_enhanced_header(state, layout)
      _ -> # md, lg, xl
        draw_full_header(state, layout)
    end
  end

  @doc """
  Draw a compact header for extra small screens.
  """
  def draw_compact_header(state, layout) do
    colors = Colors.colors()
    width = layout.total_width
    
    # Top border
    IO.puts("#{colors.bright_cyan}┌#{String.duplicate("─", width - 2)}┐#{colors.reset}")
    
    # Title line
    title = " 🎯 Timestrike"  # Changed from "Aria Timestrike"
    title_padding = width - Colors.visual_length(title) - 2
    IO.puts("#{colors.bright_cyan}│#{colors.bright_white}#{title}#{String.duplicate(" ", max(0, title_padding))}#{colors.bright_cyan}│#{colors.reset}")
    
    # Status line with tick count and play status
    tick_count = Map.get(state, :tick_count, 0)
    paused = Map.get(state, :paused, false)
    play_symbol = if paused, do: "⏸", else: "▶"
    status = " T:#{tick_count} #{play_symbol}"
    status_padding = width - Colors.visual_length(status) - 2
    IO.puts("#{colors.bright_cyan}│#{status}#{String.duplicate(" ", max(0, status_padding))}#{colors.bright_cyan}│#{colors.reset}")
    
    # Bottom border
    IO.puts("#{colors.bright_cyan}├#{String.duplicate("─", width - 2)}┤#{colors.reset}")
  end

  @doc """
  Draw an enhanced header for small screens.
  """
  def draw_enhanced_header(state, layout) do
    colors = Colors.colors()
    width = layout.total_width
    
    # Top border
    IO.puts("#{colors.bright_cyan}┌#{String.duplicate("─", width - 2)}┐#{colors.reset}")
    
    # Title line with emoji
    title = " 🎯 Aria Timestrike - Interactive Strategy"
    title_padding = width - Colors.visual_length(title) - 2
    IO.puts("#{colors.bright_cyan}│#{colors.bright_white}#{title}#{String.duplicate(" ", max(0, title_padding))}#{colors.bright_cyan}│#{colors.reset}")
    
    # Status and time line
    status = get_status_text(state)
    time_info = get_time_info(state)
    combined = " #{status} │ #{time_info}"
    combined_padding = width - Colors.visual_length(combined) - 2
    IO.puts("#{colors.bright_cyan}│#{combined}#{String.duplicate(" ", max(0, combined_padding))}#{colors.bright_cyan}│#{colors.reset}")
    
    # Stats line
    stats = get_stats_text(state)
    stats_padding = width - Colors.visual_length(stats) - 2
    IO.puts("#{colors.bright_cyan}│#{stats}#{String.duplicate(" ", max(0, stats_padding))}#{colors.bright_cyan}│#{colors.reset}")
    
    # Bottom border
    IO.puts("#{colors.bright_cyan}├#{String.duplicate("─", width - 2)}┤#{colors.reset}")
  end

  @doc """
  Draw a full header for medium and larger screens.
  """
  def draw_full_header(state, layout) do
    colors = Colors.colors()
    width = layout.total_width
    
    # Top border
    IO.puts("#{colors.bright_cyan}┌#{String.duplicate("─", width - 2)}┐#{colors.reset}")
    
    # Main title line
    title = " 🎯 Aria Timestrike - Interactive Strategy Game"
    title_padding = width - Colors.visual_length(title) - 2
    IO.puts("#{colors.bright_cyan}│#{colors.bright_white}#{title}#{String.duplicate(" ", max(0, title_padding))}#{colors.bright_cyan}│#{colors.reset}")
    
    # Status and game info line
    status = get_status_text(state)
    time_info = get_time_info(state)
    turn_info = get_turn_info(state)
    info_line = " #{status} │ #{time_info} │ #{turn_info}"
    info_padding = width - Colors.visual_length(info_line) - 2
    IO.puts("#{colors.bright_cyan}│#{info_line}#{String.duplicate(" ", max(0, info_padding))}#{colors.bright_cyan}│#{colors.reset}")
    
    # Stats line
    stats = get_stats_text(state)
    stats_padding = width - Colors.visual_length(stats) - 2
    IO.puts("#{colors.bright_cyan}│#{stats}#{String.duplicate(" ", max(0, stats_padding))}#{colors.bright_cyan}│#{colors.reset}")
    
    if layout.header_height >= 5 do
      # Additional info line for very large screens
      extra_info = get_extra_info(state)
      extra_padding = width - Colors.visual_length(extra_info) - 2
      IO.puts("#{colors.bright_cyan}│#{colors.gray}#{extra_info}#{String.duplicate(" ", max(0, extra_padding))}#{colors.bright_cyan}│#{colors.reset}")
    end
    
    # Bottom border
    IO.puts("#{colors.bright_cyan}├#{String.duplicate("─", width - 2)}┤#{colors.reset}")
  end

  @doc """
  Draw responsive controls/footer.
  """
  def draw_responsive_controls(layout) do
    case layout.breakpoint do
      :xs ->
        draw_compact_controls(layout)
      :sm ->
        draw_standard_controls(layout)
      _ -> # md, lg, xl
        draw_full_controls(layout)
    end
  end

  @doc """
  Draw compact controls for extra small screens.
  """
  def draw_compact_controls(layout) do
    colors = Colors.colors()
    width = layout.total_width
    
    # Controls header
    IO.puts("#{colors.bright_cyan}│#{colors.bright_white} Controls#{String.duplicate(" ", width - 11)}#{colors.bright_cyan}│#{colors.reset}")
    IO.puts("#{colors.bright_cyan}├#{String.duplicate("─", width - 2)}┤#{colors.reset}")
    
    # Compact controls
    controls = " #{colors.bright_yellow}SPC#{colors.reset}-Int│#{colors.bright_yellow}P#{colors.reset}-Pause│#{colors.bright_yellow}Q#{colors.reset}-Quit│#{colors.bright_yellow}C#{colors.reset}-Conv"
    controls_padding = width - Colors.visual_length(controls) - 2
    IO.puts("#{colors.bright_cyan}│#{controls}#{String.duplicate(" ", max(0, controls_padding))}#{colors.bright_cyan}│#{colors.reset}")
    
    # Bottom border
    IO.puts("#{colors.bright_cyan}├#{String.duplicate("─", width - 2)}┤#{colors.reset}")
  end

  @doc """
  Draw standard controls for small screens.
  """
  def draw_standard_controls(layout) do
    colors = Colors.colors()
    width = layout.total_width
    
    # Controls header
    IO.puts("#{colors.bright_cyan}│#{colors.bright_white} 🎮 Controls#{String.duplicate(" ", width - 14)}#{colors.bright_cyan}│#{colors.reset}")
    IO.puts("#{colors.bright_cyan}├#{String.duplicate("─", width - 2)}┤#{colors.reset}")
    
    # Standard controls
    controls = "  #{colors.bright_yellow}SPACE#{colors.reset}-Int│#{colors.bright_yellow}P#{colors.reset}-Pause│#{colors.bright_yellow}Q#{colors.reset}-Quit│#{colors.bright_yellow}C#{colors.reset}-Conviction"
    controls_padding = width - Colors.visual_length(controls) - 2
    IO.puts("#{colors.bright_cyan}│#{controls}#{String.duplicate(" ", max(0, controls_padding))}#{colors.bright_cyan}│#{colors.reset}")
    
    # Bottom border
    IO.puts("#{colors.bright_cyan}├#{String.duplicate("─", width - 2)}┤#{colors.reset}")
  end

  @doc """
  Draw full controls for medium and larger screens.
  """
  def draw_full_controls(layout) do
    colors = Colors.colors()
    width = layout.total_width
    
    # Controls header
    IO.puts("#{colors.bright_cyan}│#{colors.bright_white} 🎮 Controls#{String.duplicate(" ", width - 14)}#{colors.bright_cyan}│#{colors.reset}")
    IO.puts("#{colors.bright_cyan}├#{String.duplicate("─", width - 2)}┤#{colors.reset}")
    
    # Full controls
    base_controls = "#{colors.bright_yellow}SPACE#{colors.reset}-Interrupt/Replan │ #{colors.bright_yellow}P#{colors.reset}-Pause/Resume │ #{colors.bright_yellow}Q#{colors.reset}-Quit │ #{colors.bright_yellow}C#{colors.reset}-Conviction"
    controls = if width >= 120 do # lg, xl might have Refresh
      "  #{base_controls} │ #{colors.bright_yellow}R#{colors.reset}-Refresh"
    else # md
      "  #{base_controls}"
    end
    
    controls_padding = width - Colors.visual_length(controls) - 2
    IO.puts("#{colors.bright_cyan}│#{controls}#{String.duplicate(" ", max(0, controls_padding))}#{colors.bright_cyan}│#{colors.reset}")
    
    if layout.controls_height >= 4 do # Typically for lg, xl
      help_text = "  Use keyboard shortcuts for real-time game control"
      help_padding = width - String.length(help_text) - 2
      IO.puts("#{colors.bright_cyan}│#{colors.gray}#{help_text}#{String.duplicate(" ", max(0, help_padding))}#{colors.bright_cyan}│#{colors.reset}")
    end
    
    # Bottom border
    IO.puts("#{colors.bright_cyan}├#{String.duplicate("─", width - 2)}┤#{colors.reset}")
  end

  # Private helper functions

  defp get_status_text(state) do
    colors = Colors.colors()
    paused = Map.get(state, :paused, false)
    case Map.get(state, :status, :active) do
      :active -> 
        if paused do
          "#{colors.bright_yellow}⏸#{colors.reset} Paused"
        else
          "#{colors.bright_green}●#{colors.reset} Active"
        end
      :paused -> "#{colors.bright_yellow}⏸#{colors.reset} Paused"
      :ended -> "#{colors.bright_red}■#{colors.reset} Ended"
      _ -> "#{colors.gray}○#{colors.reset} Unknown"
    end
  end

  defp get_time_info(state) do
    colors = Colors.colors()
    turn = Map.get(state, :current_turn, 1)
    time = Map.get(state, :game_time, "00:00")
    tick_count = Map.get(state, :tick_count, 0)
    "#{colors.bright_blue}Turn #{turn}#{colors.reset} │ #{colors.cyan}#{time}#{colors.reset} │ #{colors.bright_white}Tick: #{tick_count}#{colors.reset}"
  end

  defp get_turn_info(state) do
    colors = Colors.colors()
    phase = Map.get(state, :phase, "planning")
    "#{colors.bright_white}Phase: #{String.capitalize(phase)}#{colors.reset}"
  end

  defp get_stats_text(state) do
    colors = Colors.colors()
    health = Map.get(state, :health, 100)
    energy = Map.get(state, :energy, 100)
    score = Map.get(state, :score, 0)
    " #{colors.bright_red}❤ #{health}#{colors.reset} │ #{colors.bright_yellow}⚡ #{energy}#{colors.reset} │ #{colors.bright_white}Score: #{score}#{colors.reset}"
  end

  defp get_extra_info(state) do
    location = Map.get(state, :location, "Unknown")
    difficulty = Map.get(state, :difficulty, "Normal")
    "  Location: #{location} │ Difficulty: #{difficulty}"
  end
end
