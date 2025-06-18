# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule DebugDurativeActionsSTN do
  alias AriaEngine.Timeline.STN

  def run do
    IO.puts("=== Debugging STN Inconsistency (Minimal Case) ===")

    # 1. Create a new STN
    stn = STN.new()
    IO.puts("\nInitial STN consistent: #{STN.consistent?(stn)}")
    IO.puts("Initial STN time points: #{inspect(STN.time_points(stn))}")
    IO.puts("Initial STN constraints: #{inspect(stn.constraints)}")

    # 2. Add time points
    stn = STN.add_time_point(stn, "t1")
    stn = STN.add_time_point(stn, "t2")
    IO.puts("\nSTN after adding t1, t2: #{STN.consistent?(stn)}")
    IO.puts("STN time points: #{inspect(STN.time_points(stn))}")
    IO.puts("STN constraints: #{inspect(stn.constraints)}")

    # 3. Add first constraint: t1 -> t2 is {10, 20}
    IO.puts("\n--- Adding constraint: t1 -> t2 is {10, 20} ---")
    stn_step1 = STN.add_constraint(stn, "t1", "t2", {10, 20})
    IO.puts("STN consistent after t1->t2: #{STN.consistent?(stn_step1)}")
    IO.puts("STN constraints: #{inspect(stn_step1.constraints)}")
    IO.puts("Constraint t1->t2: #{inspect(STN.get_constraint(stn_step1, "t1", "t2"))}")
    IO.puts("Constraint t2->t1: #{inspect(STN.get_constraint(stn_step1, "t2", "t1"))}")

    # 4. Add second constraint: t2 -> t1 is {5, 15} (this should cause inconsistency)
    IO.puts("\n--- Adding constraint: t2 -> t1 is {5, 15} (EXPECT INCONSISTENCY) ---")
    stn_step2 = STN.add_constraint(stn_step1, "t2", "t1", {5, 15})
    IO.puts("STN consistent after t2->t1: #{STN.consistent?(stn_step2)}")
    IO.puts("STN constraints: #{inspect(stn_step2.constraints)}")
    IO.puts("Constraint t1->t2: #{inspect(STN.get_constraint(stn_step2, "t1", "t2"))}")
    IO.puts("Constraint t2->t1: #{inspect(STN.get_constraint(stn_step2, "t2", "t1"))}")
  end
end

DebugDurativeActionsSTN.run()
