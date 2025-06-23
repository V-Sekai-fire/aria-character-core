# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule TemporalPuzzleDebug do
  alias {Domain, State, Planner}
  alias Timeline.Interval
  alias DateTime

  @moduledoc "This debug script demonstrates a temporal puzzle: making coffee and toasting a bagel.\nIt highlights how actions with durations and dependencies can be modeled and\ntheir temporal consistency validated using an STN.\n\nScenario:\n- Brew coffee (takes 5 minutes)\n- Toast bagel (takes 3 minutes)\n- Eat bagel (instantaneous, requires bagel toasted)\n- Drink coffee (instantaneous, requires coffee brewed)\n\nThe goal is to have both coffee and bagel ready and consumed.\n"
  require Logger

  def run do
    Logger.info("=== Debugging Temporal Puzzle: Coffee and Bagel ===")
    domain = build_coffee_bagel_domain()

    initial_state =
      State.new()
      |> State.set_fact("coffee", "status", "raw")
      |> State.set_fact("bagel", "status", "raw")
      |> State.set_fact("time", "current", 0)

    goals = [{"coffee", "status", "consumed"}, {"bagel", "status", "consumed"}]
    Logger.info("\n--- Planning ---")
    Logger.info("Initial State: #{inspect(initial_state.data)}")
    Logger.info("Goals: #{inspect(goals)}")

    case plan(domain, initial_state, goals, verbose: 0) do
      {:ok, solution_tree} ->
        Logger.info("\nGenerated Solution Tree:")
        plan_actions = Planner.extract_actions(solution_tree)
        Enum.each(plan_actions, fn action -> Logger.info("  #{inspect(action)}") end)
        Logger.info("\n✅ Planning successful and temporal constraints validated by Planner.")
        Logger.info("You can now execute this solution tree.")

      {:error, reason} ->
        Logger.info("
Planning failed: #{reason}")

        Logger.info(
          "This might indicate that the domain definition needs refinement or that the goals are unachievable."
        )
    end
  end

  defp build_coffee_bagel_domain do
    Domain.new("coffee_bagel")
    |> Domain.add_action(:brew_coffee_start, &brew_coffee_start_action/2, %{
      duration: Interval.from_duration(DateTime.utc_now(), 0, :millisecond)
    })
    |> Domain.add_action(:wait_for_brew, &wait_for_brew_action/2, %{
      duration: Interval.from_duration(DateTime.utc_now(), 300_000, :millisecond)
    })
    |> Domain.add_action(:toast_bagel_start, &toast_bagel_start_action/2, %{
      duration: Interval.from_duration(DateTime.utc_now(), 0, :millisecond)
    })
    |> Domain.add_action(:wait_for_toast, &wait_for_toast_action/2, %{
      duration: Interval.from_duration(DateTime.utc_now(), 180_000, :millisecond)
    })
    |> Domain.add_action(:eat_bagel, &eat_bagel_action/2, %{
      duration: Interval.from_duration(DateTime.utc_now(), 0, :millisecond)
    })
    |> Domain.add_action(:drink_coffee, &drink_coffee_action/2, %{
      duration: Interval.from_duration(DateTime.utc_now(), 0, :millisecond)
    })
    |> Domain.add_unigoal_method("coffee", &achieve_coffee_unigoal/2)
    |> Domain.add_unigoal_method("bagel", &achieve_bagel_unigoal/2)
  end

  defp brew_coffee_start_action(state, []) do
    if State.get_fact(state, "status", "coffee") == "raw" do
      State.set_fact(state, "coffee", "status", "brewing")
    else
      false
    end
  end

  defp wait_for_brew_action(state, []) do
    if State.get_fact(state, "status", "coffee") == "brewing" do
      new_time = State.get_fact(state, "current", "time") + 300_000

      State.set_fact(state, "coffee", "status", "brewed")
      |> State.set_fact("time", "current", new_time)
    else
      false
    end
  end

  defp toast_bagel_start_action(state, []) do
    if State.get_fact(state, "status", "bagel") == "raw" do
      State.set_fact(state, "bagel", "status", "toasting")
    else
      false
    end
  end

  defp wait_for_toast_action(state, []) do
    if State.get_fact(state, "status", "bagel") == "toasting" do
      new_time = State.get_fact(state, "current", "time") + 180_000

      State.set_fact(state, "bagel", "status", "toasted")
      |> State.set_fact("time", "current", new_time)
    else
      false
    end
  end

  defp eat_bagel_action(state, []) do
    if State.get_fact(state, "status", "bagel") == "toasted" do
      State.set_fact(state, "bagel", "status", "consumed")
    else
      false
    end
  end

  defp drink_coffee_action(state, []) do
    if State.get_fact(state, "status", "coffee") == "brewed" do
      State.set_fact(state, "coffee", "status", "consumed")
    else
      false
    end
  end

  defp achieve_coffee_unigoal(state, ["status", "consumed"]) do
    case State.get_fact(state, "status", "coffee") do
      "consumed" -> []
      "brewed" -> [drink_coffee: []]
      "brewing" -> [wait_for_brew: [], drink_coffee: []]
      "raw" -> [brew_coffee_start: [], wait_for_brew: [], drink_coffee: []]
      _ -> false
    end
  end

  defp achieve_bagel_unigoal(state, ["status", "consumed"]) do
    case State.get_fact(state, "status", "bagel") do
      "consumed" -> []
      "toasted" -> [eat_bagel: []]
      "toasting" -> [wait_for_toast: [], eat_bagel: []]
      "raw" -> [toast_bagel_start: [], wait_for_toast: [], eat_bagel: []]
      _ -> false
    end
  end
end

TemporalPuzzleDebug.run()