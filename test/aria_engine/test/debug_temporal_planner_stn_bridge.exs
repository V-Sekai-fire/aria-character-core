# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule TemporalPlannerSTNBridgeDebug do
  alias {Domain, State}
  alias Timeline.STN

  @moduledoc "This debug script demonstrates how a plan involving both temporal and non-temporal\nactions can be unified and validated using the Simple Temporal Network (STN) bridge.\n\nIt defines a simple domain with:\n- A non-temporal action: `pickup` (instantaneous).\n- A temporal action: `travel` (takes time).\n\nThe script then attempts to generate a plan and constructs an STN from the\ntemporal aspects of the plan to verify its consistency.\n"
  require Logger

  def run do
    Logger.info("=== Debugging Temporal Planner STN Bridge ===")
    domain = build_temporal_hybrid_domain()

    initial_state =
      State.new()
      |> State.set_fact("location", "player", "start_location")
      |> State.set_fact("has", "player", "nothing")
      |> State.set_fact("time", "current", 0)

    goals = [{"has", "player", "item"}, {"location", "player", "end_location"}]
    Logger.info("\n--- Planning ---")
    Logger.info("Initial State: #{inspect(initial_state.data)}")
    Logger.info("Goals: #{inspect(goals)}")

    case plan(domain, initial_state, goals, verbose: 0) do
      {:ok, plan} ->
        Logger.info("\nGenerated Plan:")
        Enum.each(plan, fn action -> Logger.info("  #{inspect(action)}") end)
        stn = build_stn_from_plan(plan, initial_state)
        Logger.info("\n--- STN Validation ---")
        Logger.info("STN Time Points: #{inspect(STN.time_points(stn))}")
        Logger.info("STN Constraints: #{inspect(stn.constraints)}")

        if STN.consistent?(stn) do
          Logger.info(
            "\n✅ STN is consistent. Temporal and non-temporal elements unified successfully."
          )

          solved_stn = STN.solve(stn)
          Logger.info("Solved STN Constraints: #{inspect(solved_stn.constraints)}")
        else
          Logger.info("\n❌ STN is inconsistent. Temporal constraints conflict.")
        end

      {:error, reason} ->
        Logger.info("
Planning failed: #{reason}")

        Logger.info(
          "This might indicate that the planner needs to be extended to handle temporal actions directly, or that the domain definition needs refinement."
        )
    end
  end

  defp build_temporal_hybrid_domain do
    Domain.new("temporal_hybrid")
    |> Domain.add_action(:pickup, &pickup_action/2)
    |> Domain.add_action(:travel, &travel_action/2)
    |> Domain.add_unigoal_method("has", &achieve_has_item_unigoal/2)
    |> Domain.add_unigoal_method("location", &achieve_location_unigoal/2)
  end

  defp pickup_action(state, [item]) do
    player_location = State.get_fact(state, "player", "location")
    item_location = State.get_fact(state, "location", item)

    if player_location == item_location do
      State.set_fact(state, "has", "player", "item")
    else
      false
    end
  end

  defp travel_action(state, [from_loc, to_loc, duration_ms]) do
    current_loc = State.get_fact(state, "player", "location")

    if current_loc == from_loc do
      new_time = State.get_fact(state, "current", "time") + duration_ms

      State.set_fact(state, "location", "player", "to_loc")
      |> State.set_fact("time", "current", new_time)
    else
      false
    end
  end

  defp achieve_has_item_unigoal(state, ["has", "player", item]) do
    if State.get_fact(state, "player", "has") == item do
      []
    else
      player_location = State.get_fact(state, "player", "location")
      item_location = "middle_location"
      [travel: [player_location, item_location, 2000], pickup: [item]]
    end
  end

  defp achieve_location_unigoal(state, ["location", "player", target_location]) do
    if State.get_fact(state, "player", "location") == target_location do
      []
    else
      current_player_loc = State.get_fact(state, "player", "location")
      [travel: [current_player_loc, target_location, 3000]]
    end
  end

  defp build_stn_from_plan(plan, initial_state) do
    stn = STN.new(time_unit: :millisecond)
    current_time = State.get_fact(initial_state, "current", "time")
    stn = STN.add_time_point(stn, "t_start_plan_#{current_time}")
    last_time_point = "t_start_plan_#{current_time}"

    Enum.reduce(plan, {stn, current_time, last_time_point}, fn action,
                                                               {acc_stn, acc_time, acc_last_tp} ->
      case action do
        {:travel, [_from, _to, duration_ms]} ->
          new_time = acc_time + duration_ms
          new_time_point = "t_travel_end_#{new_time}"

          acc_stn =
            acc_stn
            |> STN.add_time_point(new_time_point)
            |> STN.add_constraint(acc_last_tp, new_time_point, {duration_ms, duration_ms})

          {acc_stn, new_time, new_time_point}

        {:pickup, _item} ->
          {acc_stn, acc_time, acc_last_tp}

        _ ->
          {acc_stn, acc_time, acc_last_tp}
      end
    end)
    |> elem(0)
  end
end

TemporalPlannerSTNBridgeDebug.run()