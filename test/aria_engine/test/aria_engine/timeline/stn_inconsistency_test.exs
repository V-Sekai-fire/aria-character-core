# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Timeline.InconsistencyTest do
  use ExUnit.Case, async: true

  alias Timeline

  setup do
    :ok
  end

  test "Timeline detects inconsistency with contradictory constraints" do
    # 1. Create a new Timeline
    timeline = Timeline.new()
    
    # 2. Add time points
    timeline = Timeline.add_time_point(timeline, "t1")
    timeline = Timeline.add_time_point(timeline, "t2")

    # 3. Add first constraint: t1 -> t2 is {10, 20}
    # This will also add t2 -> t1 as {-20, -10}
    timeline_step1 = Timeline.add_constraint(timeline, "t1", "t2", {10, 20})
    assert Timeline.consistent?(timeline_step1)
    assert Timeline.get_constraint(timeline_step1, "t1", "t2") == {10, 20}
    assert Timeline.get_constraint(timeline_step1, "t2", "t1") == {-20, -10}

    # 4. Add second constraint: t2 -> t1 is {5, 15}
    # This should cause inconsistency when intersected with existing t2->t1 of {-20, -10}
    # Expected intersection for t2->t1: max(-20, 5) = 5, min(-10, 15) = -10. Since 5 > -10, it's inconsistent.
    timeline_step2 = Timeline.add_constraint(timeline_step1, "t2", "t1", {5, 15})
    
    # Assert that the Timeline is now inconsistent
    refute Timeline.consistent?(timeline_step2)
  end
end
