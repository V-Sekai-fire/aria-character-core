# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.GoalTest do
  use ExUnit.Case
  doctest AriaEngine.Multigoal

  alias AriaEngine.Multigoal

  describe "Goal management" do
    test "creates and manages multigoals" do
      multigoal = AriaEngine.create_multigoal()
      |> Multigoal.add_goal("location", "player", "treasure_room")
      |> Multigoal.add_goal("has", "player", "treasure")

      assert Multigoal.size(multigoal) == 2
      refute Multigoal.empty?(multigoal)

      goals_list = Multigoal.to_list(multigoal)
      assert {"location", "player", "treasure_room"} in goals_list
      assert {"has", "player", "treasure"} in goals_list
    end

    test "checks goal satisfaction" do
      # Create a state where player is in treasure_room and has treasure
      state = AriaEngine.create_state()
      |> AriaEngine.set_fact("location", "player", "treasure_room")
      |> AriaEngine.set_fact("has", "player", "treasure")

      multigoal = AriaEngine.create_multigoal()
      |> Multigoal.add_goal("location", "player", "treasure_room")
      |> Multigoal.add_goal("has", "player", "treasure")

      assert Multigoal.satisfied?(multigoal, state)

      # Test partial satisfaction
      partial_multigoal = Multigoal.add_goal(multigoal, "health", "player", 100)
      refute Multigoal.satisfied?(partial_multigoal, state)

      unsatisfied = Multigoal.unsatisfied_goals(partial_multigoal, state)
      assert unsatisfied == [{"health", "player", 100}]
    end
  end
end
