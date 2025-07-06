# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule Timeline.InconsistencyTest do
  use ExUnit.Case, async: true
  alias Timeline

  setup do
    :ok
  end

  test "Timeline detects inconsistency with contradictory constraints" do
    timeline = Timeline.new()
    timeline = Timeline.add_time_point(timeline, "t1")
    timeline = Timeline.add_time_point(timeline, "t2")
    timeline_step1 = Timeline.add_constraint(timeline, "t1", "t2", {10, 20})
    assert Timeline.consistent?(timeline_step1)
    assert Timeline.get_constraint(timeline_step1, "t1", "t2") == {10, 20}
    assert Timeline.get_constraint(timeline_step1, "t2", "t1") == {-20, -10}
    timeline_step2 = Timeline.add_constraint(timeline_step1, "t2", "t1", {5, 15})
    refute Timeline.consistent?(timeline_step2)
  end
end
