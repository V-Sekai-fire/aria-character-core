# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaTui.Display.GridTest do
  use ExUnit.Case, async: true

  alias AriaTui.Display.Grid

  describe "breakpoint calculation" do
    test "returns xs for very small terminals" do
      assert Grid.get_breakpoint({50, 15}) == :xs
      assert Grid.get_breakpoint({60, 18}) == :xs
    end

    test "returns sm for small terminals" do
      assert Grid.get_breakpoint({70, 20}) == :sm
      assert Grid.get_breakpoint({79, 23}) == :sm
    end

    test "returns md for medium terminals" do
      assert Grid.get_breakpoint({80, 24}) == :md
      assert Grid.get_breakpoint({99, 29}) == :md
    end

    test "returns lg for large terminals" do
      assert Grid.get_breakpoint({100, 30}) == :lg
      assert Grid.get_breakpoint({119, 39}) == :lg
    end

    test "returns xl for extra large terminals" do
      assert Grid.get_breakpoint({120, 40}) == :xl
      assert Grid.get_breakpoint({200, 60}) == :xl
    end

    test "handles edge cases" do
      # Zero size
      assert Grid.get_breakpoint({0, 0}) == :xs

      # Negative size (shouldn't happen but handle gracefully)
      assert Grid.get_breakpoint({-10, -5}) == :xs

      # Very large size
      assert Grid.get_breakpoint({1000, 500}) == :xl
    end
  end

  describe "layout creation" do
    test "creates single column layout for xs" do
      layout = Grid.create_layout({60, 20})

      assert layout.breakpoint == :xs
      assert layout.columns == 1
      assert layout.total_width == 60
      assert layout.total_height == 20
      assert length(layout.column_widths) == 1
      assert hd(layout.column_widths) == 60
    end

    test "creates two column layout for md" do
      layout = Grid.create_layout({90, 25})

      assert layout.breakpoint == :md
      assert layout.columns == 2
      assert layout.total_width == 90
      assert layout.total_height == 25
      assert length(layout.column_widths) == 2

      # Should distribute width evenly accounting for separator
      [left, right] = layout.column_widths
      assert left + right == 90 - 3  # 3 chars for separators
    end

    test "creates two column layout for xl (not three)" do
      layout = Grid.create_layout({150, 50})

      assert layout.breakpoint == :xl
      assert layout.columns == 2  # Should be 2, not 3
      assert layout.total_width == 150
      assert layout.total_height == 50
      assert length(layout.column_widths) == 2
    end
  end

  describe "column width calculation" do
    test "distributes width evenly for two columns" do
      # 100 total - 3 separators = 97 available
      # 97 / 2 = 48.5, so [48, 49]
      widths = Grid.calculate_column_widths(100, 2)
      assert widths == [48, 49]
      assert Enum.sum(widths) == 97
    end

    test "handles single column" do
      widths = Grid.calculate_column_widths(80, 1)
      assert widths == [80]
    end

    test "handles odd total widths" do
      # 101 total - 3 separators = 98 available
      # 98 / 2 = 49, so [49, 49]
      widths = Grid.calculate_column_widths(101, 2)
      assert widths == [49, 49]
      assert Enum.sum(widths) == 98
    end

    test "handles minimum widths" do
      # Very small terminal
      widths = Grid.calculate_column_widths(30, 2)
      # 30 - 3 = 27, 27 / 2 = 13.5, so [13, 14]
      assert widths == [13, 14]
      assert Enum.sum(widths) == 27
    end
  end

  describe "responsive content rendering" do
    setup do
      # Mock state for testing
      game_state = %{
        agents: [
          %{name: "Alex", position: {5.0, 3.0}, status: :alive, speed: 1.2},
          %{name: "Jace", position: {8.0, 2.0}, status: :alive, speed: 0.8}
        ],
        map: %{width: 12, height: 8}
      }

      state = %{
        game_state: game_state,
        tick_count: 42,
        paused: false,
        last_update: DateTime.utc_now()
      }

      %{state: state}
    end

    test "renders single column content for xs", %{state: state} do
      layout = Grid.create_layout({60, 20})

      output = ExUnit.CaptureIO.capture_io(fn ->
        Grid.draw_single_column_content(state, layout)
      end)

      # Should contain agent and map information
      assert String.contains?(output, "Agents")  # Agents panel header
      assert String.contains?(output, "Map")   # Map panel header
      assert String.contains?(output, "│")  # Should have borders
    end

    test "renders two column content for md/lg/xl", %{state: state} do
      layout = Grid.create_layout({100, 30})

      output = ExUnit.CaptureIO.capture_io(fn ->
        Grid.draw_two_column_content(state, layout)
      end)

      # Should contain agent and map information in columns
      assert String.contains?(output, "┌")  # Top border
      assert String.contains?(output, "┬")  # Column separator at top
      assert String.contains?(output, "│")  # Should have column separators
    end
  end

  describe "layout validation" do
    test "ensures minimum viable layouts" do
      # Very small terminal should still work
      layout = Grid.create_layout({20, 10})
      assert layout.breakpoint == :xs
      assert layout.columns == 1
      assert layout.total_width >= 20

      # Layout should be usable
      assert length(layout.column_widths) == layout.columns
      assert Enum.all?(layout.column_widths, &(&1 > 0))
    end

    test "handles reasonable maximum sizes" do
      layout = Grid.create_layout({300, 100})
      assert layout.breakpoint == :xl
      assert layout.columns == 2
      assert layout.total_width == 300

      # Should not create excessively wide columns
      Enum.each(layout.column_widths, fn width ->
        assert width > 0
        assert width < 300  # Should be reasonable
      end)
    end
  end

  describe "grid system consistency" do
    test "breakpoint boundaries are consistent" do
      # Test boundary conditions
      assert Grid.get_breakpoint({69, 19}) == :xs
      assert Grid.get_breakpoint({70, 20}) == :sm

      assert Grid.get_breakpoint({79, 23}) == :sm
      assert Grid.get_breakpoint({80, 24}) == :md

      assert Grid.get_breakpoint({99, 29}) == :md
      assert Grid.get_breakpoint({100, 30}) == :lg

      assert Grid.get_breakpoint({119, 39}) == :lg
      assert Grid.get_breakpoint({120, 40}) == :xl
    end

    test "column count matches breakpoint expectations" do
      breakpoints_and_columns = [
        {:xs, 1}, {:sm, 1}, {:md, 2}, {:lg, 2}, {:xl, 2}
      ]

      Enum.each(breakpoints_and_columns, fn {breakpoint, expected_columns} ->
        # Create a layout that should result in this breakpoint
        {width, height} = case breakpoint do
          :xs -> {60, 18}
          :sm -> {75, 22}
          :md -> {85, 26}
          :lg -> {110, 35}
          :xl -> {130, 45}
        end

        layout = Grid.create_layout({width, height})
        assert layout.breakpoint == breakpoint
        assert layout.columns == expected_columns
      end)
    end
  end
end
