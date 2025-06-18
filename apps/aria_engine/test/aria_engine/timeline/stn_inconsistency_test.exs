# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Timeline.STNInconsistencyTest do
  use ExUnit.Case, async: true

  alias AriaEngine.Timeline.STN

  setup do
    :ok
  end

  test "STN detects inconsistency with contradictory constraints" do
    # 1. Create a new STN
    stn = STN.new()
    
    # 2. Add time points
    stn = STN.add_time_point(stn, "t1")
    stn = STN.add_time_point(stn, "t2")

    # 3. Add first constraint: t1 -> t2 is {10, 20}
    # This will also add t2 -> t1 as {-20, -10}
    stn_step1 = STN.add_constraint(stn, "t1", "t2", {10, 20})
    assert STN.consistent?(stn_step1)
    assert STN.get_constraint(stn_step1, "t1", "t2") == {10, 20}
    assert STN.get_constraint(stn_step1, "t2", "t1") == {-20, -10}

    # 4. Add second constraint: t2 -> t1 is {5, 15}
    # This should cause inconsistency when intersected with existing t2->t1 of {-20, -10}
    # Expected intersection for t2->t1: max(-20, 5) = 5, min(-10, 15) = -10. Since 5 > -10, it's inconsistent.
    stn_step2 = STN.add_constraint(stn_step1, "t2", "t1", {5, 15})
    
    # Assert that the STN is now inconsistent
    refute STN.consistent?(stn_step2)
  end
end
