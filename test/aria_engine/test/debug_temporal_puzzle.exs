# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

# Debug script for a temporal puzzle (Coffee and Bagel)
# Usage: mix run apps/aria_engine/test/debug_temporal_puzzle.exs

defmodule TemporalPuzzleDebug do
  # Keep Planner for extract_actions
  alias {Domain, State, Planner}
  # STN is no longer directly used
  alias Timeline.Interval
  alias DateTime

  @moduledoc """
  This debug script demonstrates a temporal puzzle: making coffee and toasting a bagel.
  It highlights how actions with durations and dependencies can be modeled and
  their temporal consistency validated using an STN.

  Scenario:
  - Brew coffee (takes 5 minutes)
  - Toast bagel (takes 3 minutes)
  - Eat bagel (instantaneous, requires bagel toasted)
  - Drink coffee (instantaneous, requires coffee brewed)

  The goal is to have both coffee and bagel ready and consumed.
  """

  require Logger

  def run do
    Logger.info("=== Debugging Temporal Puzzle: Coffee and Bagel ===")

    # 1. Define the domain with temporal actions
    domain = build_coffee_bagel_domain()

    # 2. Define initial state
    initial_state =
      StateV2.new()
      |> StateV2.set_fact("coffee", "status", "raw")
      |> StateV2.set_fact("bagel", "status", "raw")
      # Current time in milliseconds
      |> StateV2.set_fact("time", "current", 0)

    # 3. Define goals
    goals = [
      {"coffee", "status", "consumed"},
      {"bagel", "status", "consumed"}
    ]

    Logger.info("\n--- Planning ---")
    Logger.info("Initial State: #{inspect(initial_state.data)}")
    Logger.info("Goals: #{inspect(goals)}")

    # 4. Attempt to generate a plan
    # The plan function now handles STN construction and validation internally
    case plan(domain, initial_state, goals, verbose: 0) do
      # plan now returns the full solution_tree
      {:ok, solution_tree} ->
        Logger.info("\nGenerated Solution Tree:")
        # Extract primitive actions for display
        plan_actions = Planner.extract_actions(solution_tree)
        Enum.each(plan_actions, fn action -> Logger.info("  #{inspect(action)}") end)

        Logger.info("\n✅ Planning successful and temporal constraints validated by Planner.")
        Logger.info("You can now execute this solution tree.")

      # Optionally, you can run the execution here
      # case Planner.run_lazy_refineahead(Planner.domain_to_interface(domain), initial_state, solution_tree) do
      #   {:ok, final_state} ->
      #     Logger.info("\nExecution successful. Final state: #{inspect(final_state.data)}")
      #   {:error, reason} ->
      #     Logger.info("\nExecution failed: #{reason}")
      # end

      {:error, reason} ->
        Logger.info("\nPlanning failed: #{reason}")

        Logger.info(
          "This might indicate that the domain definition needs refinement or that the goals are unachievable."
        )
    end
  end

  # --- Domain and Action Definitions ---

  defp build_coffee_bagel_domain do
    Domain.new("coffee_bagel")
    # Instantaneous
    |> Domain.add_action(:brew_coffee_start, &brew_coffee_start_action/2, %{
      duration: Interval.from_duration(DateTime.utc_now(), 0, :millisecond)
    })
    # 5 minutes
    |> Domain.add_action(:wait_for_brew, &wait_for_brew_action/2, %{
      duration: Interval.from_duration(DateTime.utc_now(), 300_000, :millisecond)
    })
    # Instantaneous
    |> Domain.add_action(:toast_bagel_start, &toast_bagel_start_action/2, %{
      duration: Interval.from_duration(DateTime.utc_now(), 0, :millisecond)
    })
    # 3 minutes
    |> Domain.add_action(:wait_for_toast, &wait_for_toast_action/2, %{
      duration: Interval.from_duration(DateTime.utc_now(), 180_000, :millisecond)
    })
    # Instantaneous
    |> Domain.add_action(:eat_bagel, &eat_bagel_action/2, %{
      duration: Interval.from_duration(DateTime.utc_now(), 0, :millisecond)
    })
    # Instantaneous
    |> Domain.add_action(:drink_coffee, &drink_coffee_action/2, %{
      duration: Interval.from_duration(DateTime.utc_now(), 0, :millisecond)
    })
    |> Domain.add_unigoal_method("coffee", &achieve_coffee_unigoal/2)
    |> Domain.add_unigoal_method("bagel", &achieve_bagel_unigoal/2)
  end

  # Instantaneous action: brew_coffee_start
  defp brew_coffee_start_action(state, []) do
    if StateV2.get_fact(state, "status", "coffee") == "raw" do
      StateV2.set_fact(state, "coffee", "status", "brewing")
    else
      false
    end
  end

  # Temporal action: wait_for_brew (takes 5 minutes = 300,000 ms)
  defp wait_for_brew_action(state, []) do
    if StateV2.get_fact(state, "status", "coffee") == "brewing" do
      new_time = StateV2.get_fact(state, "current", "time") + 300_000

      StateV2.set_fact(state, "coffee", "status", "brewed")
      |> StateV2.set_fact("time", "current", new_time)
    else
      false
    end
  end

  # Instantaneous action: toast_bagel_start
  defp toast_bagel_start_action(state, []) do
    if StateV2.get_fact(state, "status", "bagel") == "raw" do
      StateV2.set_fact(state, "bagel", "status", "toasting")
    else
      false
    end
  end

  # Temporal action: wait_for_toast (takes 3 minutes = 180,000 ms)
  defp wait_for_toast_action(state, []) do
    if StateV2.get_fact(state, "status", "bagel") == "toasting" do
      new_time = StateV2.get_fact(state, "current", "time") + 180_000

      StateV2.set_fact(state, "bagel", "status", "toasted")
      |> StateV2.set_fact("time", "current", new_time)
    else
      false
    end
  end

  # Non-temporal action: eat_bagel (instantaneous, requires bagel toasted)
  defp eat_bagel_action(state, []) do
    if StateV2.get_fact(state, "status", "bagel") == "toasted" do
      StateV2.set_fact(state, "bagel", "status", "consumed")
    else
      false
    end
  end

  # Non-temporal action: drink_coffee (instantaneous, requires coffee brewed)
  defp drink_coffee_action(state, []) do
    if StateV2.get_fact(state, "status", "coffee") == "brewed" do
      StateV2.set_fact(state, "coffee", "status", "consumed")
    else
      false
    end
  end

  # Unigoal method for "coffee" goal (temporal method)
  defp achieve_coffee_unigoal(state, ["status", "consumed"]) do
    case StateV2.get_fact(state, "status", "coffee") do
      "consumed" -> []
      "brewed" -> [{:drink_coffee, []}]
      "brewing" -> [{:wait_for_brew, []}, {:drink_coffee, []}]
      "raw" -> [{:brew_coffee_start, []}, {:wait_for_brew, []}, {:drink_coffee, []}]
      _ -> false
    end
  end

  # Unigoal method for "bagel" goal (temporal method)
  defp achieve_bagel_unigoal(state, ["status", "consumed"]) do
    case StateV2.get_fact(state, "status", "bagel") do
      "consumed" -> []
      "toasted" -> [{:eat_bagel, []}]
      "toasting" -> [{:wait_for_toast, []}, {:eat_bagel, []}]
      "raw" -> [{:toast_bagel_start, []}, {:wait_for_toast, []}, {:eat_bagel, []}]
      _ -> false
    end
  end

  # The build_stn_from_plan function is no longer needed as STN construction
  # and validation are handled internally by Planner.plan
end

# Run the debug script
TemporalPuzzleDebug.run()
