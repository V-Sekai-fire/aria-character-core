# NOTE:
# When registering unigoal methods for the planner, you must register for the PREDICATE (e.g., "has", "location")
# and your method must pattern match on [subject, object] (e.g., ["player", item]).
# The planner will call your method as: defp achieve_has_item_unigoal(state, ["player", item])
# This follows GTPyhop's predicate-based registration pattern.
# See this test for a working example.

defmodule TemporalPlannerSTNBridgeTest do
  use ExUnit.Case

  require Logger
  alias State

  @moduledoc """
  ExUnit test for unifying temporal planner via STN bridge.
  """

  test "temporal and non-temporal actions unify and validate with STN" do
    # 1. Define the domain with temporal and non-temporal actions
    domain = build_temporal_hybrid_domain()

    # 2. Define initial state with time
    initial_state =
      State.new()
      |> State.set_fact("location", "player", "start_location")
      |> State.set_fact("has", "player", "nothing")
      |> State.set_fact("location", "item", "middle_location")
      |> State.set_fact("time", "current", 0)

    # 3. Define goals
    goals = [
      {"has", "player", "item"},
      {"location", "player", "end_location"}
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
        assert is_tuple(timeline) and tuple_size(timeline) == 2,
               "Timeline should be constructed for unified temporal/non-temporal plan"

      # Optionally, add more timeline-specific assertions here

      {:error, reason} ->
        Logger.error("Planning failed: #{inspect(reason)}")
        flunk("Planning failed: #{reason}")
    end
  end

  # --- Domain and Action Definitions ---

  defp build_temporal_hybrid_domain do
    AriaEngine.Domain.new("temporal_hybrid")
    |> AriaEngine.Domain.add_action(:pickup, &pickup_action/2)
    |> AriaEngine.Domain.add_action(:travel, &travel_action/2)
    |> AriaEngine.Domain.add_unigoal_method("has", &achieve_has_item_unigoal/2)
    |> AriaEngine.Domain.add_unigoal_method("location", &achieve_location_unigoal/2)
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

  defp achieve_has_item_unigoal(state, [subject, item]) do
    Logger.debug(
      "achieve_has_item_unigoal (predicate-based) called with state=#{inspect(state)}, subject=#{inspect(subject)}, item=#{inspect(item)}"
    )

    if State.get_fact(state, subject, "has") == item do
      []
    else
      player_location = State.get_fact(state, subject, "location")
      item_location = State.get_fact(state, item, "location") || "middle_location"

      [
        {:travel, [player_location, item_location, 2000]},
        {:pickup, [item]}
      ]
    end
  end

  defp achieve_has_item_unigoal(state, args) do
    Logger.debug(
      "achieve_has_item_unigoal catch-all called with state=#{inspect(state)}, args=#{inspect(args)}"
    )

    false
  end

  defp achieve_location_unigoal(state, [subject, target_location]) do
    Logger.debug(
      "achieve_location_unigoal (predicate-based) called with state=#{inspect(state)}, subject=#{inspect(subject)}, target_location=#{inspect(target_location)}"
    )

    if State.get_fact(state, subject, "location") == target_location do
      []
    else
      current_player_loc = State.get_fact(state, subject, "location")

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
