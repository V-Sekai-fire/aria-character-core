# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule GoalTest do
  use ExUnit.Case
  doctest AriaEngine.Multigoal

  alias AriaEngine.Multigoal
  alias AriaEngine.StateV2

  # Helper functions
  defp create_multigoal(), do: Multigoal.new()
  defp create_state(), do: StateV2.new()

  describe "Goal management" do
    test "creates and manages multigoals" do
      multigoal =
        create_multigoal()
        |> Multigoal.add_goal("player", "location", "treasure_room")
        |> Multigoal.add_goal("player", "has", "treasure")

      assert Multigoal.size(multigoal) == 2
      refute Multigoal.empty?(multigoal)

      goals_list = Multigoal.to_list(multigoal)
      assert {"player", "location", "treasure_room"} in goals_list
      assert {"player", "has", "treasure"} in goals_list
    end

    test "checks goal satisfaction" do
      # Create a state where player is in treasure_room and has treasure
      state =
        StateV2.new()
        |> StateV2.set_fact("player", "location", "treasure_room")
        |> StateV2.set_fact("player", "has", "treasure")

      multigoal =
        create_multigoal()
        |> Multigoal.add_goal("player", "location", "treasure_room")
        |> Multigoal.add_goal("player", "has", "treasure")

      assert Multigoal.satisfied?(multigoal, state)

      # Test partial satisfaction
      partial_multigoal = Multigoal.add_goal(multigoal, "player", "health", 100)
      refute Multigoal.satisfied?(partial_multigoal, state)

      unsatisfied = Multigoal.unsatisfied_goals(partial_multigoal, state)
      assert unsatisfied == [{"player", "health", 100}]
    end
  end
end
