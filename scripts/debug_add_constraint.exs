# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AddConstraintDebug do
  alias AriaEngine.Timeline.STN

  @moduledoc """
  Debug script to trace the add_constraint issue.
  Usage: mix run scripts/debug_add_constraint.exs
  """

  def run do
    IO.puts("=== Debugging STN.add_constraint Issue ===")

    # Test case from AriaEngine.Timeline.STNInconsistencyTest
    IO.puts("\n--- Test Case: STN detects inconsistency with contradictory constraints ---")
    
    # Step 1: Create STN and add first constraint
    stn = STN.new()
    stn = STN.add_time_point(stn, "t1")
    stn = STN.add_time_point(stn, "t2")
    
    IO.puts("Initial STN: consistent=#{stn.consistent}, constraints=#{inspect(stn.constraints)}")
    
    # Step 2: Add first constraint: t1 -> t2 is {10, 20}
    stn_step1 = STN.add_constraint(stn, "t1", "t2", {10, 20})
    IO.puts("After t1->t2 {10,20}: consistent=#{stn_step1.consistent}")
    IO.puts("  Constraints: #{inspect(stn_step1.constraints)}")
    
    # Expected: t2 -> t1 should be {-20, -10}
    t2_t1_constraint = STN.get_constraint(stn_step1, "t2", "t1")
    IO.puts("  t2->t1 constraint: #{inspect(t2_t1_constraint)}")
    
    # Step 3: Add second constraint: t2 -> t1 is {5, 15}
    # This should cause inconsistency because intersection of {-20, -10} and {5, 15} is invalid
    IO.puts("\nAdding conflicting constraint t2->t1 {5,15}...")
    stn_step2 = STN.add_constraint(stn_step1, "t2", "t1", {5, 15})
    IO.puts("After t2->t1 {5,15}: consistent=#{stn_step2.consistent}")
    IO.puts("  Constraints: #{inspect(stn_step2.constraints)}")
    
    # The test expects this to be inconsistent
    IO.puts("Expected: consistent=false")
    IO.puts("Actual: consistent=#{stn_step2.consistent}")
    IO.puts("TEST #{if stn_step2.consistent, do: "FAILS", else: "PASSES"}")
  end
end

AddConstraintDebug.run()
