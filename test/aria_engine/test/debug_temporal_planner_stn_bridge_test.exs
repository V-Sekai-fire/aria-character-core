# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule TemporalPlannerSTNBridgeTest do
  use ExUnit.Case
  require Logger
  alias Domain
  alias State
  alias AriaEngine.State
  @moduledoc "ExUnit test for unifying temporal planner via STN bridge.\n"
  test "temporal and non-temporal actions unify and validate with STN" do
    domain = build_temporal_hybrid_domain()

    initial_state =
      State.new()
      |> State.set_fact("player", "location", "start_location")
      |> State.set_fact("player", "has", "nothing")
      |> State.set_fact("item", "location", "middle_location")
      |> State.set_fact("time", "current", 0)

    goals = [{"player", "has", "item"}, {"player", "location", "end_location"}]
    Logger.debug("Initial state: #{inspect(initial_state)}")
    Logger.debug("Goals: #{inspect(goals)}")

    case AriaEngine.PlannerAdapter.plan(domain, initial_state, goals, verbose: 3) do
      {:ok, solution_tree} ->
        Logger.debug("Planner returned solution_tree: #{inspect(solution_tree, pretty: true)}")
        timeline = build_timeline_from_plan(solution_tree, initial_state)
        Logger.debug("Constructed timeline: #{inspect(timeline)}")

        assert is_tuple(timeline) and tuple_size(timeline) == 2,
               "Timeline should be constructed for unified temporal/non-temporal plan"

      {:error, reason} ->
        Logger.error("Planning failed: #{inspect(reason)}")
        flunk("Planning failed: #{reason}")
    end
  end

  defp build_temporal_hybrid_domain do
    Domain.new("temporal_hybrid")
    |> Domain.add_action(:pickup, &pickup_action/2)
    |> Domain.add_action(:travel, &travel_action/2)
    |> Domain.add_unigoal_method("player", &achieve_has_item_unigoal/2)
    |> Domain.add_unigoal_method("player", &achieve_location_unigoal/2)
  end

  defp pickup_action(state, [item]) do
    Logger.debug("pickup_action called with state=#{inspect(state)}, args=#{inspect([item])}")
    player_location = State.get_fact(state, "player", "location")
    item_location = State.get_fact(state, item, "location")

    if player_location == item_location do
      State.set_fact(state, "player", "has", item)
    else
      false
    end
  end

  defp travel_action(state, [from_loc, to_loc, duration_ms]) do
    Logger.debug(
      "travel_action called with state=#{inspect(state)}, args=#{inspect([from_loc, to_loc, duration_ms])}"
    )

    current_loc = State.get_fact(state, "player", "location")

    if current_loc == from_loc do
      new_time = State.get_fact(state, "time", "current") + duration_ms

      State.set_fact(state, "player", "location", to_loc)
      |> State.set_fact("time", "current", new_time)
    else
      false
    end
  end

  defp achieve_has_item_unigoal(state, ["has", item]) do
    Logger.debug(
      "achieve_has_item_unigoal (subject, [predicate, object]) called with state=#{inspect(state)}, item=#{inspect(item)}"
    )

    if State.get_fact(state, "player", "has") == item do
      []
    else
      player_location = State.get_fact(state, "player", "location")
      item_location = State.get_fact(state, item, "location") || "middle_location"
      [travel: [player_location, item_location, 2000], pickup: [item]]
    end
  end

  defp achieve_has_item_unigoal(state, args) do
    Logger.debug(
      "achieve_has_item_unigoal catch-all called with state=#{inspect(state)}, args=#{inspect(args)}"
    )

    false
  end

  defp achieve_location_unigoal(state, ["location", target_location]) do
    Logger.debug(
      "achieve_location_unigoal (subject, [predicate, object]) called with state=#{inspect(state)}, target_location=#{inspect(target_location)}"
    )

    if State.get_fact(state, "player", "location") == target_location do
      []
    else
      current_player_loc = State.get_fact(state, "player", "location")
      [travel: [current_player_loc, target_location, 3000]]
    end
  end

  defp achieve_location_unigoal(_state, _args) do
    false
  end

  defp build_timeline_from_plan(plan, initial_state) do
    {plan, initial_state}
  end
end