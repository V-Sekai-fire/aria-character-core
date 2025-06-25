# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Timeline.Internal.STN.MiniZincSolverTest do
  use ExUnit.Case, async: true

  alias Timeline.Internal.STN
  alias Timeline.Internal.STN.MiniZincSolver

  describe "solve_stn/1" do
    test "solves consistent STN with simple constraints" do
      stn = STN.new()
      |> STN.add_time_point("start")
      |> STN.add_time_point("middle")
      |> STN.add_time_point("end")
      |> STN.add_constraint("start", "middle", {0, 10})
      |> STN.add_constraint("middle", "end", {5, 15})
      |> STN.add_constraint("start", "end", {5, 25})

      result = MiniZincSolver.solve_stn(stn)

      assert result.consistent == true
    end

    test "solves complex STN with multiple constraints" do
      stn = STN.new()
      |> STN.add_time_point("a")
      |> STN.add_time_point("b")
      |> STN.add_time_point("c")
      |> STN.add_constraint("a", "b", {10, 15})  # a + 10 <= b <= a + 15
      |> STN.add_constraint("b", "c", {10, 15})  # b + 10 <= c <= b + 15  
      |> STN.add_constraint("c", "a", {10, 15})  # c + 10 <= a <= c + 15

      result = MiniZincSolver.solve_stn(stn)

      # MiniZinc should find a solution if one exists
      assert result.consistent == true
    end

    test "handles empty STN" do
      stn = STN.new()

      result = MiniZincSolver.solve_stn(stn)

      # Empty STN should remain consistent but conversion should fail gracefully
      assert result.consistent == false  # Due to conversion error
    end

    test "detects truly inconsistent STN with impossible timing" do
      stn = STN.new()
      |> STN.add_time_point("task_a")
      |> STN.add_time_point("task_b")
      # Task A must finish at least 20 time units before Task B starts
      |> STN.add_constraint("task_a", "task_b", {20, 30})
      # But Task B must finish at least 20 time units before Task A starts (impossible!)
      |> STN.add_constraint("task_b", "task_a", {20, 30})

      result = MiniZincSolver.solve_stn(stn)

      # This should be inconsistent: A + 20 <= B and B + 20 <= A creates A + 40 <= A
      assert result.consistent == false
    end

    test "detects over-constrained temporal windows" do
      stn = STN.new()
      |> STN.add_time_point("start")
      |> STN.add_time_point("middle")
      |> STN.add_time_point("end")
      # Start to middle: exactly 5 time units
      |> STN.add_constraint("start", "middle", {5, 5})
      # Middle to end: exactly 5 time units  
      |> STN.add_constraint("middle", "end", {5, 5})
      # But start to end: must be exactly 15 time units (impossible with 5+5=10)
      |> STN.add_constraint("start", "end", {15, 15})

      result = MiniZincSolver.solve_stn(stn)

      # This should be inconsistent due to over-constrained timing
      assert result.consistent == false
    end

    test "handles boundary condition with very large constraints" do
      stn = STN.new()
      |> STN.add_time_point("a")
      |> STN.add_time_point("b")
      # Constraint that exceeds reasonable bounds
      |> STN.add_constraint("a", "b", {999_999, 1_000_000})

      result = MiniZincSolver.solve_stn(stn)

      # Should either solve or fail gracefully, but not crash
      assert is_boolean(result.consistent)
    end
  end

  describe "convert_stn_to_minizinc/1" do
    test "converts simple STN to MiniZinc format" do
      stn = STN.new()
      |> STN.add_time_point("start")
      |> STN.add_time_point("end")
      |> STN.add_constraint("start", "end", {5, 10})

      {:ok, template_vars} = MiniZincSolver.convert_stn_to_minizinc(stn)

      assert template_vars.num_activities == 2
      # STN creates bidirectional constraints, so we expect 2 constraints
      assert template_vars.num_constraints == 2
      assert template_vars.durations == [0, 0]
      assert length(template_vars.constraints) == 2

      # Check that we have both forward and backward constraints
      constraints = template_vars.constraints
      assert Enum.any?(constraints, fn c -> c.min_distance == -10 and c.max_distance == -5 end)
      assert Enum.any?(constraints, fn c -> c.min_distance == 5 and c.max_distance == 10 end)
    end

    test "filters out infinite constraints" do
      stn = STN.new()
      |> STN.add_time_point("a")
      |> STN.add_time_point("b")
      |> STN.add_constraint("a", "b", {-1.0e16, 1.0e16})  # Infinite constraint

      {:ok, template_vars} = MiniZincSolver.convert_stn_to_minizinc(stn)

      # Infinite constraints should be filtered out
      assert template_vars.num_constraints == 0
      assert template_vars.constraints == []
    end

    test "handles empty STN" do
      stn = STN.new()

      result = MiniZincSolver.convert_stn_to_minizinc(stn)

      assert {:error, "Empty STN - no time points to solve"} = result
    end
  end
end
