# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaTui.Display do
  @moduledoc """
  Display module providing TUI functionality for Aria Character Core.
  Handles terminal output, responsive layouts, and visual components.
  """

  alias IO.ANSI

  @colors %{
    red: ANSI.red(),
    green: ANSI.green(),
    yellow: ANSI.yellow(),
    blue: ANSI.blue(),
    magenta: ANSI.magenta(),
    cyan: ANSI.cyan(),
    white: ANSI.white(),
    reset: ANSI.reset()
  }

  @doc """
  Clear the terminal screen.
  """
  def clear_screen do
    IO.write(ANSI.clear())
    IO.write(ANSI.cursor(0, 0))
  end

  @doc """
  Display the main game state in a responsive layout.
  """
  def display_game_state(game_state) do
    {terminal_width, terminal_height} = get_terminal_size()
    
    # Create responsive layout
    layout = AriaTui.Display.Grid.create_layout({terminal_width, terminal_height})
    
    # Display header
    display_header(game_state, terminal_width)
    
    # Display main content panels based on layout
    display_panels(game_state, layout)
    
    # Display status bar
    display_status_bar(game_state, terminal_width)
    
    {:ok, "Displayed game state with #{layout.columns} columns (#{layout.breakpoint} breakpoint)"}
  end

  @doc """
  Get current terminal size.
  """
  def get_terminal_size do
    case :io.columns() do
      {:ok, cols} ->
        case :io.rows() do
          {:ok, rows} -> {cols, rows}
          _ -> {80, 24}  # Default fallback
        end
      _ -> {80, 24}  # Default fallback
    end
  end

  @doc """
  Extract content from a panel, handling borders and padding.
  """
  def extract_panel_content(content, width) when is_binary(content) do
    lines = String.split(content, "\n")
    
    # Filter out border lines and extract content
    content_lines = 
      lines
      |> Enum.reject(&is_border_line?/1)
      |> Enum.map(&extract_line_content/1)
      |> Enum.reject(&(&1 == ""))
    
    # If no content, return at least one empty line
    if Enum.empty?(content_lines) do
      [String.pad_trailing("", width)]
    else
      Enum.map(content_lines, &pad_line(&1, width))
    end
  end

  def extract_panel_content("", width), do: [String.pad_trailing("", width)]

  @doc """
  Clean ANSI color codes from text.
  """
  def clean_ansi_codes(text) when is_binary(text) do
    # Remove ANSI escape sequences
    text
    |> String.replace(~r/\e\[[0-9;]*m/, "")
    |> String.replace(~r/\e\[[0-9;]*[A-Za-z]/, "")
  end

  @doc """
  Format agent status with appropriate styling.
  """
  def format_agent_status(:alive), do: "#{@colors[:green]}ALIVE#{@colors[:reset]}"
  def format_agent_status(:dead), do: "#{@colors[:red]}DEAD#{@colors[:reset]}"
  def format_agent_status(_), do: "#{@colors[:yellow]}UNKNOWN#{@colors[:reset]}"

  @doc """
  Get agent-specific color.
  """
  def get_agent_color(agent_name) when is_binary(agent_name) do
    # Simple hash-based color assignment
    hash = :crypto.hash(:md5, agent_name) |> :binary.first()
    colors = [@colors[:red], @colors[:green], @colors[:yellow], @colors[:blue], @colors[:magenta], @colors[:cyan]]
    Enum.at(colors, rem(hash, length(colors)))
  end

  @doc """
  Generate enhanced map symbol for agent.
  """
  def get_enhanced_map_symbol(agent_name, {_x, _y}) when is_binary(agent_name) do
    color = get_agent_color(agent_name)
    first_char = String.first(agent_name) |> String.upcase()
    "#{color}#{first_char}#{@colors[:reset]}"
  end

  @doc """
  Generate compact map symbol for agent.
  """
  def get_compact_map_symbol(%{name: agent_name}, {_x, _y}) do
    first_char = String.first(agent_name) |> String.upcase()
    "#{first_char}"
  end

  def get_compact_map_symbol(agent_name, {_x, _y}) when is_binary(agent_name) do
    first_char = String.first(agent_name) |> String.upcase()
    "#{first_char}"
  end

  # Helper functions for panel content extraction
  defp is_border_line?(line) do
    String.match?(line, ~r/^[┌┐└┘├┤┬┴┼─│]+$/) or
    String.match?(line, ~r/^\s*[+\-|]+\s*$/)
  end

  defp extract_line_content(line) do
    line
    |> String.trim()
    |> String.replace(~r/^[│|]\s*/, "")
    |> String.replace(~r/\s*[│|]$/, "")
    |> String.trim()
  end

  defp pad_line(line, width) do
    clean_length = String.length(clean_ansi_codes(line))
    if clean_length < width do
      line <> String.duplicate(" ", width - clean_length)
    else
      line
    end
  end

  # Private helper functions for display
  defp display_header(_game_state, width) do
    header = String.pad_leading(String.pad_trailing(" ARIA CHARACTER CORE ", width, "="), width, "=")
    IO.puts("#{@colors[:cyan]}#{header}#{@colors[:reset]}")
  end

  defp display_panels(game_state, layout) do
    case layout.columns do
      1 -> display_single_column_layout(game_state, layout)
      2 -> display_two_column_layout(game_state, layout)
      _ -> display_multi_column_layout(game_state, layout)
    end
  end

  defp display_single_column_layout(game_state, layout) do
    width = List.first(layout.column_widths, layout.total_width - 2)
    
    # Display main panel
    display_game_panel(game_state, width)
    IO.puts("")
    
    # Display secondary panels stacked
    display_agents_panel(game_state, width)
    IO.puts("")
    display_map_panel(game_state, width)
  end

  defp display_two_column_layout(game_state, layout) do
    [left_width, right_width] = layout.column_widths
    
    # Split panels between columns
    left_content = capture_panel_output(fn -> display_game_panel(game_state, left_width) end)
    right_content = capture_panel_output(fn -> 
      display_agents_panel(game_state, right_width)
      IO.puts("")
      display_map_panel(game_state, right_width)
    end)
    
    # Display side by side
    display_side_by_side(left_content, right_content, left_width, right_width)
  end

  defp display_multi_column_layout(game_state, layout) do
    # For now, fall back to two-column layout
    display_two_column_layout(game_state, layout)
  end

  defp display_status_bar(_game_state, width) do
    separator = String.duplicate("=", width)
    status = "Status: #{format_agent_status(:alive)} | Time: #{System.system_time(:second)}"
    status_line = String.pad_trailing(status, width)
    
    IO.puts("#{@colors[:cyan]}#{separator}#{@colors[:reset]}")
    IO.puts("#{@colors[:white]}#{status_line}#{@colors[:reset]}")
  end

  defp display_game_panel(game_state, width) do
    title = " Game State "
    border = String.duplicate("─", width - 2)
    
    IO.puts("┌#{border}┐")
    title_padded = String.pad_trailing(String.pad_leading(title, div(width - 2 + String.length(title), 2)), width - 2)
    IO.puts("│#{title_padded}│")
    IO.puts("├#{border}┤")
    
    # Display game content
    content_lines = get_game_content(game_state, width - 2)
    Enum.each(content_lines, fn line ->
      padded_line = String.pad_trailing(line, width - 2)
      IO.puts("│#{padded_line}│")
    end)
    
    IO.puts("└#{border}┘")
  end

  defp display_agents_panel(game_state, width) do
    title = " Agents "
    border = String.duplicate("─", width - 2)
    
    IO.puts("┌#{border}┐")
    title_padded = String.pad_trailing(String.pad_leading(title, div(width - 2 + String.length(title), 2)), width - 2)
    IO.puts("│#{title_padded}│")  
    IO.puts("├#{border}┤")
    
    # Display agents content
    content_lines = get_agents_content(game_state, width - 2)
    Enum.each(content_lines, fn line ->
      padded_line = String.pad_trailing(line, width - 2)
      IO.puts("│#{padded_line}│")
    end)
    
    IO.puts("└#{border}┘")
  end

  defp display_map_panel(game_state, width) do
    title = " Map "
    border = String.duplicate("─", width - 2)
    
    IO.puts("┌#{border}┐")
    title_padded = String.pad_trailing(String.pad_leading(title, div(width - 2 + String.length(title), 2)), width - 2)
    IO.puts("│#{title_padded}│")
    IO.puts("├#{border}┤")
    
    # Display map content
    content_lines = get_map_content(game_state, width - 2)
    Enum.each(content_lines, fn line ->
      padded_line = String.pad_trailing(line, width - 2)
      IO.puts("│#{padded_line}│")
    end)
    
    IO.puts("└#{border}┘")
  end

  defp capture_panel_output(_fun) do
    # Capture output from a function
    # For now, return placeholder content
    ["Panel content line 1", "Panel content line 2", "Panel content line 3"]
  end

  defp display_side_by_side(left_content, right_content, left_width, right_width) do
    max_lines = max(length(left_content), length(right_content))
    
    0..(max_lines - 1)
    |> Enum.each(fn i ->
      left_line = Enum.at(left_content, i, "")
      right_line = Enum.at(right_content, i, "")
      
      left_padded = String.pad_trailing(left_line, left_width)
      right_padded = String.pad_trailing(right_line, right_width)
      
      IO.puts("#{left_padded} #{right_padded}")
    end)
  end

  defp get_game_content(_game_state, width) do
    [
      "Current Turn: 1",
      "Active Players: 2", 
      "Game Mode: Standard",
      String.duplicate(" ", width)
    ]
  end

  defp get_agents_content(_game_state, width) do
    [
      "Alex: #{format_agent_status(:alive)}",
      "Bob: #{format_agent_status(:dead)}",
      "Charlie: #{format_agent_status(:alive)}",
      String.duplicate(" ", width)
    ]
  end

  defp get_map_content(_game_state, width) do
    [
      "┌─────────┐",
      "│ A   B   │", 
      "│         │",
      "│    C    │",
      "└─────────┘",
      String.duplicate(" ", width)
    ]
  end
end

defmodule AriaTui.Display.Grid do
  @moduledoc """
  Responsive grid system for terminal display layout.
  """

  defstruct [:breakpoint, :columns, :total_width, :column_widths]

  @doc """
  Determines the breakpoint based on terminal size.
  """
  def get_breakpoint({width, _height}) when width < 0, do: :xs
  def get_breakpoint({0, _height}), do: :xs
  def get_breakpoint({width, _height}) when width < 70, do: :xs
  def get_breakpoint({width, _height}) when width < 80, do: :sm
  def get_breakpoint({width, _height}) when width < 100, do: :md
  def get_breakpoint({width, _height}) when width < 120, do: :lg
  def get_breakpoint({_width, _height}), do: :xl

  @doc """
  Creates a layout configuration based on terminal size.
  """
  def create_layout({width, _height} = size) do
    breakpoint = get_breakpoint(size)
    columns = get_column_count(breakpoint)
    column_widths = calculate_column_widths(width, columns)

    %__MODULE__{
      breakpoint: breakpoint,
      columns: columns,
      total_width: width,
      column_widths: column_widths
    }
  end

  @doc """
  Calculate column widths for given total width and column count.
  """
  def calculate_column_widths(total_width, columns) when columns <= 1 do
    [total_width]
  end

  def calculate_column_widths(total_width, columns) do
    # Account for spacing between columns (columns - 1) * 1 space
    available_width = total_width - (columns - 1)
    base_width = div(available_width, columns)
    remainder = rem(available_width, columns)

    # Distribute remainder across columns
    Enum.map(0..(columns - 1), fn i ->
      if i < remainder do
        base_width + 1
      else
        base_width
      end
    end)
  end

  defp get_column_count(:xs), do: 1
  defp get_column_count(:sm), do: 1
  defp get_column_count(:md), do: 2
  defp get_column_count(:lg), do: 2
  defp get_column_count(:xl), do: 2
end
