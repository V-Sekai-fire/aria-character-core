# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

# Debug script for unifying temporal planner via STN bridge
# Usage: mix run apps/aria_engine/test/debug_temporal_planner_stn_bridge.exs

defmodule TemporalPlannerSTNBridgeDebug do
  alias {Domain, State}
  alias Timeline.STN

  @moduledoc """
  This debug script demonstrates how a plan involving both temporal and non-temporal
  actions can be unified and validated using the Simple Temporal Network (STN) bridge.

  It defines a simple domain with:
  - A non-temporal action: `pickup` (instantaneous).
  - A temporal action: `travel` (takes time).

  The script then attempts to generate a plan and constructs an STN from the
  temporal aspects of the plan to verify its consistency.
  """

  require Logger

  def run do
    Logger.info("=== Debugging Temporal Planner STN Bridge ===")

    # 1. Define the domain with temporal and non-temporal actions
    domain = build_temporal_hybrid_domain()

    # 2. Define initial state with time
    initial_state =
      StateV2.new()
      |> State.set_fact("location", "player", "start_location")
      |> State.set_fact("has", "player", "nothing")
      # Current time in milliseconds
      |> State.set_fact("time", "current", 0)

    # 3. Define goals
    # Goal: Player has the item and is at the end location
    goals = [
      {"has", "player", "item"},
      {"location", "player", "end_location"}
    ]

    Logger.info("\n--- Planning ---")
    Logger.info("Initial State: #{inspect(initial_state.data)}")
    Logger.info("Goals: #{inspect(goals)}")

    # 4. Attempt to generate a plan
    # Note: plan might not directly handle temporal actions with durations
    # in a way that automatically builds an STN. We will simulate this.
    case plan(domain, initial_state, goals, verbose: 0) do
      {:ok, plan} ->
        Logger.info("\nGenerated Plan:")
        Enum.each(plan, fn action -> Logger.info("  #{inspect(action)}") end)

        # 5. Construct an STN from the plan's temporal aspects
        stn = build_stn_from_plan(plan, initial_state)

        Logger.info("\n--- STN Validation ---")
        Logger.info("STN Time Points: #{inspect(STN.time_points(stn))}")
        Logger.info("STN Constraints: #{inspect(stn.constraints)}")

        # 6. Check STN consistency
        if STN.consistent?(stn) do
          Logger.info(
            "\n✅ STN is consistent. Temporal and non-temporal elements unified successfully."
          )

          # Optionally, solve the STN to get minimal network
          solved_stn = STN.solve(stn)
          Logger.info("Solved STN Constraints: #{inspect(solved_stn.constraints)}")
        else
          Logger.info("\n❌ STN is inconsistent. Temporal constraints conflict.")
        end

      {:error, reason} ->
        Logger.info("\nPlanning failed: #{reason}")

        Logger.info(
          "This might indicate that the planner needs to be extended to handle temporal actions directly, or that the domain definition needs refinement."
        )
    end
  end

  # --- Domain and Action Definitions ---

  defp build_temporal_hybrid_domain do
    Domain.new("temporal_hybrid")
    |> Domain.add_action(:pickup, &pickup_action/2)
    |> Domain.add_action(:travel, &travel_action/2)
    |> Domain.add_unigoal_method("has", &achieve_has_item_unigoal/2)
    |> Domain.add_unigoal_method("location", &achieve_location_unigoal/2)
  end

  # Non-temporal action: pickup
  defp pickup_action(state, [item]) do
    player_location = State.get_fact(state, "player", "location")
    item_location = State.get_fact(state, "location", item)

    if player_location == item_location do
      State.set_fact(state, "has", "player", "item")
    else
      # Cannot pickup if not in same location
      false
    end
  end

  # Temporal action: travel
  # This action will return a new state and the duration it took
  defp travel_action(state, [from_loc, to_loc, duration_ms]) do
    current_loc = State.get_fact(state, "player", "location")

    if current_loc == from_loc do
      new_time = State.get_fact(state, "current", "time") + duration_ms

      State.set_fact(state, "location", "player", "to_loc")
      |> State.set_fact("time", "current", new_time)
    else
      # Cannot travel from wrong location
      false
    end
  end

  # Unigoal method for "has" goal
  defp achieve_has_item_unigoal(state, ["has", "player", item]) do
    if State.get_fact(state, "player", "has") == item do
      # Already has the item, no actions needed
      []
    else
      player_location = State.get_fact(state, "player", "location")
      # Assume item is here
      item_location = "middle_location"

      # Plan to travel to item location and pick it up
      [
        # Travel to item (2 seconds)
        {:travel, [player_location, item_location, 2000]},
        {:pickup, [item]}
      ]
    end
  end

  # Unigoal method for "location" goal
  defp achieve_location_unigoal(state, ["location", "player", target_location]) do
    if State.get_fact(state, "player", "location") == target_location do
      # Already at target location, no actions needed
      []
    else
      current_player_loc = State.get_fact(state, "player", "location")
      # Plan to travel to the target location
      [
        # Travel to target (3 seconds)
        {:travel, [current_player_loc, target_location, 3000]}
      ]
    end
  end

  # --- STN Construction from Plan ---

  defp build_stn_from_plan(plan, initial_state) do
    stn = STN.new(time_unit: :millisecond)
    current_time = State.get_fact(initial_state, "current", "time")

    # Add a time point for the start of the plan
    stn = STN.add_time_point(stn, "t_start_plan_#{current_time}")
    last_time_point = "t_start_plan_#{current_time}"

    Enum.reduce(plan, {stn, current_time, last_time_point}, fn action,
                                                               {acc_stn, acc_time, acc_last_tp} ->
      case action do
        {:travel, [_from, _to, duration_ms]} ->
          # Temporal action: create new time point and add constraint
          new_time = acc_time + duration_ms
          new_time_point = "t_travel_end_#{new_time}"

          acc_stn =
            acc_stn
            |> STN.add_time_point(new_time_point)
            |> STN.add_constraint(acc_last_tp, new_time_point, {duration_ms, duration_ms})

          {acc_stn, new_time, new_time_point}

        {:pickup, _item} ->
          # Non-temporal action: assumed instantaneous, so time doesn't advance
          # We can add a constraint that the action happens at the current time point
          # or simply keep the last_time_point the same.
          # For simplicity, we'll assume it happens at the current time point.
          {acc_stn, acc_time, acc_last_tp}

        _ ->
          # Handle other action types if necessary
          {acc_stn, acc_time, acc_last_tp}
      end
    end)
    # Return only the STN
    |> elem(0)
  end
end

# Run the debug script
TemporalPlannerSTNBridgeDebug.run()
