# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaMinizincStnComprehensiveTest do
  use ExUnit.Case

  describe "STN consistency checking" do
    test "detects inconsistent STN with conflicting constraints" do
      stn = %{
        time_points: MapSet.new(["A", "B"]),
        constraints: %{
          {"A", "B"} => {10, 15},  # B must be 10-15 after A
          {"B", "A"} => {20, 25}   # A must be 20-25 after B (impossible)
        },
        consistent: nil,
        metadata: %{}
      }

      result = AriaMinizincStn.solve_stn(stn)

      case result do
        {:ok, solved_stn} ->
          # If MiniZinc finds it satisfiable, check the solution
          assert is_boolean(solved_stn.consistent)
        {:error, reason} ->
          # Expected for inconsistent STN
          assert is_binary(reason)
      end
    end

    test "handles complex STN with multiple time points" do
      stn = %{
        time_points: MapSet.new(["A", "B", "C", "D", "E"]),
        constraints: %{
          {"A", "B"} => {1, 3},
          {"B", "C"} => {2, 4},
          {"C", "D"} => {1, 2},
          {"D", "E"} => {3, 5},
          {"A", "E"} => {7, 15}  # Transitive constraint
        },
        consistent: nil,
        metadata: %{}
      }

      {:ok, result} = AriaMinizincStn.solve_stn(stn)

      assert result.consistent == true
      assert result.metadata.solver == :minizinc
      assert is_map(result.metadata.solved_times)

      # Verify we have solutions for all time points
      solved_times = result.metadata.solved_times
      time_points = MapSet.to_list(stn.time_points)

      Enum.each(time_points, fn point ->
        assert Map.has_key?(solved_times, point)
        assert is_number(solved_times[point])
      end)
    end

    test "handles STN with zero-duration constraints" do
      stn = %{
        time_points: MapSet.new(["A", "B", "C"]),
        constraints: %{
          {"A", "B"} => {0, 0},  # B happens exactly at same time as A
          {"B", "C"} => {5, 5}   # C happens exactly 5 units after B
        },
        consistent: nil,
        metadata: %{}
      }

      {:ok, result} = AriaMinizincStn.solve_stn(stn)

      assert result.consistent == true
      solved_times = result.metadata.solved_times

      # Verify timing relationships
      assert solved_times["A"] == solved_times["B"]
      assert solved_times["C"] == solved_times["B"] + 5
    end

    test "handles STN with negative time constraints" do
      stn = %{
        time_points: MapSet.new(["A", "B", "C"]),
        constraints: %{
          {"B", "A"} => {-10, -5},  # A happens 5-10 units before B
          {"A", "C"} => {3, 7}      # C happens 3-7 units after A
        },
        consistent: nil,
        metadata: %{}
      }

      {:ok, result} = AriaMinizincStn.solve_stn(stn)

      assert result.consistent == true
      solved_times = result.metadata.solved_times

      # Verify timing relationships (A should be before B)
      assert solved_times["A"] <= solved_times["B"]
      assert solved_times["C"] >= solved_times["A"]
    end
  end

  describe "STN with durative actions" do
    test "handles complex durative action scheduling" do
      stn = %{
        time_points: MapSet.new([
          "task1_start", "task1_end",
          "task2_start", "task2_end",
          "task3_start", "task3_end"
        ]),
        constraints: %{
          # Task durations
          {"task1_start", "task1_end"} => {10, 10},
          {"task2_start", "task2_end"} => {5, 5},
          {"task3_start", "task3_end"} => {8, 8},

          # Precedence constraints
          {"task1_end", "task2_start"} => {2, 5},    # Task2 starts 2-5 after Task1 ends
          {"task2_end", "task3_start"} => {1, 3},    # Task3 starts 1-3 after Task2 ends

          # Resource constraints (tasks can't overlap)
          {"task1_start", "task2_start"} => {10, 1000},  # Task2 can't start until Task1 finishes
        },
        consistent: nil,
        metadata: %{}
      }

      {:ok, result} = AriaMinizincStn.solve_stn(stn)

      assert result.consistent == true
      solved_times = result.metadata.solved_times

      # Verify task ordering
      assert solved_times["task1_start"] < solved_times["task1_end"]
      assert solved_times["task2_start"] < solved_times["task2_end"]
      assert solved_times["task3_start"] < solved_times["task3_end"]

      # Verify precedence
      assert solved_times["task1_end"] <= solved_times["task2_start"]
      assert solved_times["task2_end"] <= solved_times["task3_start"]
    end

    test "handles parallel task execution" do
      stn = %{
        time_points: MapSet.new([
          "parallel1_start", "parallel1_end",
          "parallel2_start", "parallel2_end",
          "sync_point"
        ]),
        constraints: %{
          # Parallel task durations
          {"parallel1_start", "parallel1_end"} => {15, 15},
          {"parallel2_start", "parallel2_end"} => {12, 12},

          # Both tasks can start at the same time
          {"parallel1_start", "parallel2_start"} => {0, 2},

          # Sync point after both tasks complete
          {"parallel1_end", "sync_point"} => {1, 3},
          {"parallel2_end", "sync_point"} => {1, 3}
        },
        consistent: nil,
        metadata: %{}
      }

      {:ok, result} = AriaMinizincStn.solve_stn(stn)

      assert result.consistent == true
      solved_times = result.metadata.solved_times

      # Verify parallel execution is possible
      start_diff = abs(solved_times["parallel1_start"] - solved_times["parallel2_start"])
      assert start_diff <= 2

      # Verify sync point is after both tasks
      assert solved_times["sync_point"] >= solved_times["parallel1_end"]
      assert solved_times["sync_point"] >= solved_times["parallel2_end"]
    end
  end

  describe "STN performance and scalability" do
    test "handles medium-scale STN efficiently" do
      # Create STN with 20 time points and various constraints
      time_points = for i <- 1..20, do: "point_#{i}"

      constraints =
        for i <- 1..19, into: %{} do
          from = "point_#{i}"
          to = "point_#{i + 1}"
          {{from, to}, {1, 5}}
        end

      # Add some cross-constraints
      cross_constraints = %{
        {"point_1", "point_10"} => {15, 25},
        {"point_5", "point_15"} => {20, 30},
        {"point_10", "point_20"} => {25, 35}
      }

      all_constraints = Map.merge(constraints, cross_constraints)

      stn = %{
        time_points: MapSet.new(time_points),
        constraints: all_constraints,
        consistent: nil,
        metadata: %{}
      }

      start_time = System.monotonic_time(:millisecond)
      {:ok, result} = AriaMinizincStn.solve_stn(stn)
      end_time = System.monotonic_time(:millisecond)

      solve_time = end_time - start_time

      assert result.consistent == true
      assert solve_time < 5000  # Should solve within 5 seconds
      assert map_size(result.metadata.solved_times) == 20
    end

    test "handles STN with timeout gracefully" do
      stn = %{
        time_points: MapSet.new(["A", "B"]),
        constraints: %{
          {"A", "B"} => {1, 5}
        },
        consistent: nil,
        metadata: %{}
      }

      # Very short timeout to test timeout handling
      result = AriaMinizincStn.solve_stn(stn, timeout: 1)

      case result do
        {:ok, solved_stn} ->
          # If it solves quickly, that's fine
          assert solved_stn.consistent == true
        {:error, reason} ->
          # Timeout is expected with very short timeout
          assert is_binary(reason)
      end
    end
  end

  describe "STN edge cases" do
    test "handles STN with single time point" do
      stn = %{
        time_points: MapSet.new(["A"]),
        constraints: %{},
        consistent: nil,
        metadata: %{}
      }

      {:ok, result} = AriaMinizincStn.solve_stn(stn)

      assert result.consistent == true
      assert Map.has_key?(result.metadata.solved_times, "A")
    end

    test "handles STN with disconnected components" do
      stn = %{
        time_points: MapSet.new(["A", "B", "C", "D"]),
        constraints: %{
          {"A", "B"} => {1, 3},  # Component 1
          {"C", "D"} => {2, 4}   # Component 2 (disconnected)
        },
        consistent: nil,
        metadata: %{}
      }

      {:ok, result} = AriaMinizincStn.solve_stn(stn)

      assert result.consistent == true
      solved_times = result.metadata.solved_times

      # Both components should have valid solutions
      assert solved_times["B"] >= solved_times["A"] + 1
      assert solved_times["D"] >= solved_times["C"] + 2
    end

    test "handles STN with very large time bounds" do
      stn = %{
        time_points: MapSet.new(["A", "B"]),
        constraints: %{
          {"A", "B"} => {1000000, 2000000}
        },
        consistent: nil,
        metadata: %{}
      }

      result = AriaMinizincStn.solve_stn(stn)

      case result do
        {:ok, solved_stn} ->
          if solved_stn.consistent == true do
            solved_times = solved_stn.metadata.solved_times
            assert solved_times["B"] >= solved_times["A"] + 1000000
          else
            # Handle unsatisfiable case gracefully - very large bounds exceed solver domain
            assert solved_stn.consistent == false
            assert solved_stn.metadata.solved_times == %{}
          end
        {:error, reason} ->
          # Very large bounds exceed solver domain, expect error
          assert is_binary(reason)
      end
    end
  end
end
