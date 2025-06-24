# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaMinizincStnTest do
  use ExUnit.Case

  describe "solve_stn/2" do
    test "solves simple STN with fixpoint fallback" do
      stn = %{
        time_points: MapSet.new(["A", "B", "C"]),
        constraints: %{
          {"A", "B"} => {1, 5},
          {"B", "C"} => {2, 8},
          {"A", "C"} => {3, 10}
        },
        consistent: nil,
        metadata: %{}
      }

      {:ok, result} = AriaMinizincStn.solve_stn(stn, solver: :fixpoint)

      assert result.consistent == true
      assert result.metadata.solver == :fixpoint
      assert is_map(result.metadata.solved_times)
    end

    test "handles basic two-point STN" do
      stn = %{
        time_points: MapSet.new(["A", "B"]),
        constraints: %{
          {"A", "B"} => {5, 10}
        },
        consistent: nil,
        metadata: %{}
      }

      {:ok, result} = AriaMinizincStn.solve_stn(stn, solver: :fixpoint)

      assert result.consistent == true
      assert result.metadata.solver == :fixpoint
    end

    test "handles empty STN" do
      stn = %{
        time_points: MapSet.new([]),
        constraints: %{},
        consistent: nil,
        metadata: %{}
      }

      {:ok, result} = AriaMinizincStn.solve_stn(stn, solver: :fixpoint)

      assert result.consistent == true
      assert result.metadata.solved_times == %{}
    end

    test "validates STN structure" do
      invalid_stn = %{invalid: true}

      {:error, reason} = AriaMinizincStn.solve_stn(invalid_stn)

      assert reason =~ "STN must have :time_points field"
    end

    test "handles invalid solver option" do
      stn = %{
        time_points: MapSet.new(["A"]),
        constraints: %{},
        consistent: nil,
        metadata: %{}
      }

      {:error, reason} = AriaMinizincStn.solve_stn(stn, solver: :invalid)

      assert reason =~ "Invalid solver option"
    end

    test "auto solver selection uses fixpoint when specified" do
      stn = %{
        time_points: MapSet.new(["A", "B"]),
        constraints: %{
          {"A", "B"} => {1, 5}
        },
        consistent: nil,
        metadata: %{}
      }

      {:ok, result} = AriaMinizincStn.solve_stn(stn, solver: :fixpoint)

      assert result.consistent == true
      assert result.metadata.solver == :fixpoint
    end
  end

  describe "duration extraction" do
    test "extracts durations from start/end point constraints" do
      stn = %{
        time_points: MapSet.new(["task1_start", "task1_end", "task2_start", "task2_end"]),
        constraints: %{
          {"task1_start", "task1_end"} => {5, 5},  # Fixed duration of 5
          {"task2_start", "task2_end"} => {3, 3},  # Fixed duration of 3
          {"task1_end", "task2_start"} => {1, 2}   # Precedence constraint
        },
        consistent: nil,
        metadata: %{}
      }

      {:ok, result} = AriaMinizincStn.solve_stn(stn, solver: :fixpoint)

      assert result.consistent == true
      assert is_map(result.metadata.solved_times)
    end
  end

  describe "constraint filtering" do
    test "filters out infinite constraints" do
      stn = %{
        time_points: MapSet.new(["A", "B", "C"]),
        constraints: %{
          {"A", "B"} => {1, 5},
          {"B", "C"} => {:neg_infinity, :infinity},  # Should be filtered out
          {"A", "C"} => {2, 8}
        },
        consistent: nil,
        metadata: %{}
      }

      {:ok, result} = AriaMinizincStn.solve_stn(stn, solver: :fixpoint)

      assert result.consistent == true
    end

    test "filters out self-constraints" do
      stn = %{
        time_points: MapSet.new(["A", "B"]),
        constraints: %{
          {"A", "A"} => {0, 0},  # Self-constraint, should be filtered
          {"A", "B"} => {1, 5}
        },
        consistent: nil,
        metadata: %{}
      }

      {:ok, result} = AriaMinizincStn.solve_stn(stn, solver: :fixpoint)

      assert result.consistent == true
    end
  end
end
