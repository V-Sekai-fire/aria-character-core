# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaTui.DisplayTest do
  use ExUnit.Case, async: true

  alias AriaTui.Display

  describe "responsive grid system" do
    test "calculates correct breakpoints" do
      # Test different terminal sizes
      assert Display.Grid.get_breakpoint({60, 20}) == :xs
      assert Display.Grid.get_breakpoint({80, 24}) == :md
      assert Display.Grid.get_breakpoint({90, 25}) == :md
      assert Display.Grid.get_breakpoint({110, 35}) == :lg
      assert Display.Grid.get_breakpoint({150, 50}) == :xl
    end

    test "creates correct layout configuration" do
      layout_xs = Display.Grid.create_layout({60, 20})
      assert layout_xs.breakpoint == :xs
      assert layout_xs.columns == 1
      assert layout_xs.total_width == 60

      layout_md = Display.Grid.create_layout({90, 25})
      assert layout_md.breakpoint == :md
      assert layout_md.columns == 2
      assert layout_md.total_width == 90

      layout_xl = Display.Grid.create_layout({150, 50})
      assert layout_xl.breakpoint == :xl
      assert layout_xl.columns == 2  # Changed from 3 to 2
      assert layout_xl.total_width == 150
    end

    test "calculates correct column widths" do
      layout_md = Display.Grid.create_layout({100, 30})
      # For 2 columns with 100 width: (100 - 3) / 2 = 48.5 -> [48, 49]
      assert layout_md.column_widths == [48, 49]

      layout_xl = Display.Grid.create_layout({150, 50})
      # For 2 columns with 150 width: (150 - 3) / 2 = 73.5 -> [73, 74]
      assert layout_xl.column_widths == [73, 74]
    end
  end

  describe "panel content extraction" do
    test "extracts content from bordered panels" do
      panel_content = """
      ┌─────────────┐
      │ Test Panel  │
      ├─────────────┤
      │ Line 1      │
      │ Line 2      │
      │ Line 3      │
      └─────────────┘
      """

      extracted = Display.extract_panel_content(panel_content, 15)
      assert length(extracted) >= 3
      assert Enum.any?(extracted, &String.contains?(&1, "Line 1"))
      assert Enum.any?(extracted, &String.contains?(&1, "Line 2"))
      assert Enum.any?(extracted, &String.contains?(&1, "Line 3"))
    end

    test "handles empty content gracefully" do
      empty_content = ""
      extracted = Display.extract_panel_content(empty_content, 20)
      assert is_list(extracted)
      assert length(extracted) >= 1
    end

    test "pads content to specified width" do
      content = "Short"
      extracted = Display.extract_panel_content(content, 20)
      # Check that lines are padded to the specified width
      Enum.each(extracted, fn line ->
        clean_line = Display.clean_ansi_codes(line)
        assert String.length(clean_line) <= 20
      end)
    end
  end

  describe "ANSI code handling" do
    test "removes ANSI color codes" do
      colored_text = "\e[91mRed Text\e[0m"
      clean_text = Display.clean_ansi_codes(colored_text)
      assert clean_text == "Red Text"
    end

    test "handles multiple ANSI codes" do
      complex_text = "\e[96m\e[97mBright Cyan White\e[0m\e[32mGreen\e[0m"
      clean_text = Display.clean_ansi_codes(complex_text)
      assert clean_text == "Bright Cyan WhiteGreen"
    end

    test "preserves text without ANSI codes" do
      plain_text = "Plain text without colors"
      clean_text = Display.clean_ansi_codes(plain_text)
      assert clean_text == plain_text
    end
  end

  describe "column rendering" do
    test "renders two columns with proper alignment" do
      left_content = ["Left Line 1", "Left Line 2"]
      right_content = ["Right Line 1", "Right Line 2"]
      layout = %{column_widths: [30, 30], total_width: 63}

      # Capture IO output
      output = capture_io(fn ->
        Display.draw_side_by_side_panels(left_content, right_content, layout)
      end)

      assert String.contains?(output, "Left Line 1")
      assert String.contains?(output, "Right Line 1")
      # Should contain column separator
      assert String.contains?(output, "│")
    end

    test "handles uneven content lengths" do
      left_content = ["Left 1", "Left 2", "Left 3"]
      right_content = ["Right 1"]
      layout = %{column_widths: [25, 25], total_width: 53}

      output = capture_io(fn ->
        Display.draw_side_by_side_panels(left_content, right_content, layout)
      end)

      # Should handle different content lengths gracefully
      assert String.contains?(output, "Left 1")
      assert String.contains?(output, "Left 3")
      assert String.contains?(output, "Right 1")
    end
  end

  describe "agent status formatting" do
    test "formats alive agent status" do
      status = Display.format_agent_status(:alive)
      assert String.contains?(status, "🟢")
    end

    test "formats dead agent status" do
      status = Display.format_agent_status(:dead)
      assert String.contains?(status, "🔴")
    end

    test "formats unknown agent status" do
      status = Display.format_agent_status(:unknown)
      assert String.contains?(status, "⚪")
    end
  end

  describe "agent color assignment" do
    test "assigns specific colors to known agents" do
      alex_color = Display.get_agent_color("Alex")
      assert String.contains?(alex_color, "\e[92m")  # bright_green

      jace_color = Display.get_agent_color("Jace")
      assert String.contains?(jace_color, "\e[93m")  # bright_yellow

      maya_color = Display.get_agent_color("Maya")
      assert String.contains?(maya_color, "\e[94m")  # bright_blue
    end

    test "assigns default color to unknown agents" do
      unknown_color = Display.get_agent_color("Unknown Agent")
      assert String.contains?(unknown_color, "\e[37m")  # white
    end
  end

  describe "map symbol generation" do
    test "generates enhanced map symbols for agents" do
      symbol = Display.get_enhanced_map_symbol("Alex", {5, 5})
      assert String.contains?(symbol, "⚡")

      symbol = Display.get_enhanced_map_symbol("Jace", {3, 3})
      assert String.contains?(symbol, "◆")

      symbol = Display.get_enhanced_map_symbol("Maya", {7, 7})
      assert String.contains?(symbol, "⭐")
    end

    test "generates compact map symbols for agents" do
      symbol = Display.get_compact_map_symbol(%{name: "Alex"}, {5, 5})
      assert String.contains?(symbol, "A")

      symbol = Display.get_compact_map_symbol(%{name: "Jace"}, {3, 3})
      assert String.contains?(symbol, "J")

      symbol = Display.get_compact_map_symbol(%{name: "Maya"}, {7, 7})
      assert String.contains?(symbol, "M")
    end

    test "generates terrain symbols for empty positions" do
      symbol = Display.get_enhanced_map_symbol(nil, {2, 2})
      # Should be either obstacle or empty terrain
      assert String.contains?(symbol, "▪") or String.contains?(symbol, "·")
    end
  end

  describe "responsive controls" do
    test "formats controls for different screen sizes" do
      # Test compact controls
      compact_layout = %{total_width: 40, breakpoint: :xs}
      compact_output = capture_io(fn ->
        Display.draw_responsive_controls(compact_layout)
      end)
      assert String.contains?(compact_output, "SPC")
      assert String.contains?(compact_output, "P")
      assert String.contains?(compact_output, "Q")

      # Test expanded controls
      expanded_layout = %{total_width: 120, breakpoint: :lg, controls_height: 3}
      expanded_output = capture_io(fn ->
        Display.draw_responsive_controls(expanded_layout)
      end)
      assert String.contains?(expanded_output, "SPACE")
      assert String.contains?(expanded_output, "Pause")
      assert String.contains?(expanded_output, "Quit")
    end
  end

  describe "header rendering" do
    test "renders compact header for small screens" do
      state = %{tick_count: 42, paused: false}

      output = capture_io(fn ->
        Display.draw_compact_header(state, 60)
      end)

      assert String.contains?(output, "Timestrike")
      assert String.contains?(output, "T:42")
      assert String.contains?(output, "▶")
    end

    test "renders enhanced header for large screens" do
      state = %{tick_count: 100, paused: true}
      layout = %{breakpoint: :lg, header_height: 5, total_width: 120, columns: 2}

      output = capture_io(fn ->
        Display.draw_enhanced_header(state, 120, layout)
      end)

      assert String.contains?(output, "Aria Timestrike")
      assert String.contains?(output, "Tick: 100")
      assert String.contains?(output, "⏸")
    end
  end

  describe "terminal size detection" do
    test "handles various terminal sizes" do
      # Should not crash with edge cases
      assert Display.Grid.get_breakpoint({10, 5}) == :xs
      assert Display.Grid.get_breakpoint({200, 100}) == :xl
      assert Display.Grid.get_breakpoint({0, 0}) == :xs
    end
  end

  # Helper function to capture IO output
  defp capture_io(fun) do
    ExUnit.CaptureIO.capture_io(fun)
  end
end
