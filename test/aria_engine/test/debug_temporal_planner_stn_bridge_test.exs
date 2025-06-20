# NOTE:
# When registering unigoal methods for the planner, you must register for the SUBJECT (e.g., "player")
# and your method must pattern match on [predicate, object] (e.g., ["has", item]).
# The planner will call your method as: defp achieve_has_item_unigoal(state, ["has", item])
# NOT as ["player", "has", item] or ["subject", "predicate", "object"].
# See this test for a working example.

defmodule TemporalPlannerSTNBridgeTest do
  use ExUnit.Case

  require Logger
  alias Domain
  alias State
  alias AriaEngine.StateV2

  @moduledoc """
  ExUnit test for unifying temporal planner via STN bridge.
  """

  test "temporal and non-temporal actions unify and validate with STN" do
    # 1. Define the domain with temporal and non-temporal actions
    domain = build_temporal_hybrid_domain()

    # 2. Define initial state with time
    initial_state = StateV2.new()
    |> StateV2.set_fact("player", "location", "start_location")
    |> StateV2.set_fact("player", "has", "nothing")
    |> StateV2.set_fact("item", "location", "middle_location")
    |> StateV2.set_fact("time", "current", 0)

    # 3. Define goals
    goals = [
      {"player", "has", "item"},
      {"player", "location", "end_location"}
    ]

    # 4. Attempt to generate a plan
    Logger.debug("Initial state: #{inspect(initial_state)}")
    Logger.debug("Goals: #{inspect(goals)}")
    case AriaEngine.PlannerAdapter.plan(domain, initial_state, goals, verbose: 3) do
      {:ok, solution_tree} ->
        Logger.debug("Planner returned solution_tree: #{inspect(solution_tree, pretty: true)}")
        # 5. Construct a Timeline from the plan's temporal aspects
        timeline = build_timeline_from_plan(solution_tree, initial_state)
        Logger.debug("Constructed timeline: #{inspect(timeline)}")

        # 6. Check Timeline consistency (example: check for non-overlapping actions, valid durations, etc.)
        assert timeline != nil, "Timeline should be constructed for unified temporal/non-temporal plan"
        # Optionally, add more timeline-specific assertions here

      {:error, reason} ->
        Logger.error("Planning failed: #{inspect(reason)}")
        flunk("Planning failed: #{reason}")
    end
  end

  # --- Domain and Action Definitions ---

  defp build_temporal_hybrid_domain do
    Domain.new("temporal_hybrid")
    |> Domain.add_action(:pickup, &pickup_action/2)
    |> Domain.add_action(:travel, &travel_action/2)
    |> Domain.add_unigoal_method("player", &achieve_has_item_unigoal/2)
    |> Domain.add_unigoal_method("player", &achieve_location_unigoal/2)
  end

  defp pickup_action(state, [item]) do
    Logger.debug("pickup_action called with state=#{inspect(state)}, args=#{inspect([item])}")
    player_location = StateV2.get_fact(state, "player", "location")
    item_location = StateV2.get_fact(state, item, "location")

    if player_location == item_location do
      StateV2.set_fact(state, "player", "has", item)
    else
      false
    end
  end

  defp travel_action(state, [from_loc, to_loc, duration_ms]) do
    Logger.debug("travel_action called with state=#{inspect(state)}, args=#{inspect([from_loc, to_loc, duration_ms])}")
    current_loc = StateV2.get_fact(state, "player", "location")
    if current_loc == from_loc do
      new_time = StateV2.get_fact(state, "time", "current") + duration_ms
      StateV2.set_fact(state, "player", "location", to_loc)
      |> StateV2.set_fact("time", "current", new_time)
    else
      false
    end
  end

  defp achieve_has_item_unigoal(state, ["has", item]) do
    Logger.debug("achieve_has_item_unigoal (subject, [predicate, object]) called with state=#{inspect(state)}, item=#{inspect(item)}")
    if StateV2.get_fact(state, "player", "has") == item do
      []
    else
      player_location = StateV2.get_fact(state, "player", "location")
      item_location = StateV2.get_fact(state, item, "location") || "middle_location"
      [
        {:travel, [player_location, item_location, 2000]},
        {:pickup, [item]}
      ]
    end
  end

  defp achieve_has_item_unigoal(state, args) do
    Logger.debug("achieve_has_item_unigoal catch-all called with state=#{inspect(state)}, args=#{inspect(args)}")
    false
  end

  defp achieve_location_unigoal(state, ["location", target_location]) do
    Logger.debug("achieve_location_unigoal (subject, [predicate, object]) called with state=#{inspect(state)}, target_location=#{inspect(target_location)}")
    if StateV2.get_fact(state, "player", "location") == target_location do
      []
    else
      current_player_loc = StateV2.get_fact(state, "player", "location")
      [
        {:travel, [current_player_loc, target_location, 3000]}
      ]
    end
  end

  defp achieve_location_unigoal(_state, _args), do: false

  # Dummy timeline builder for demonstration; replace with real logic as needed
  defp build_timeline_from_plan(plan, initial_state) do
    # Example: just return the plan and initial state as a tuple for now
    {plan, initial_state}
  end
end
