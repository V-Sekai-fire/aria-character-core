defmodule TemporalPuzzleTest do
  use ExUnit.Case

  alias Domain
  alias State
  alias Planner
  alias DateTime
  alias AriaEngine.StateV2

  @moduledoc """
  ExUnit test for the temporal puzzle: making coffee and toasting a bagel.
  """

  test "coffee and bagel temporal puzzle plan succeeds and validates temporal constraints" do
    # 1. Define the domain with temporal actions
    domain = build_coffee_bagel_domain()

    # 2. Define initial state
    initial_state =
      StateV2.new()
      |> StateV2.set_fact("coffee", "status", "raw")
      |> StateV2.set_fact("bagel", "status", "raw")
      |> StateV2.set_fact("time", "current", 0)

    # 3. Define goals
    todo = [
      {"coffee", "status", "consumed"},
      {"bagel", "status", "consumed"}
    ]

    # 4. Attempt to generate a plan
    case AriaEngine.PlannerAdapter.plan(domain, initial_state, todo, verbose: 0) do
      {:ok, solution_tree} ->
        require Logger
        Logger.debug("Planner returned solution_tree: #{inspect(solution_tree, pretty: true)}")
        # Extract primitive actions for display
        plan_actions = AriaEngine.Plan.Utils.get_primitive_actions_dfs(solution_tree)
        assert is_list(plan_actions)
        assert Enum.any?(plan_actions, fn {action, _} -> action == :brew_coffee end)
        assert Enum.any?(plan_actions, fn {action, _} -> action == :toast_bagel end)
        assert Enum.any?(plan_actions, fn {action, _} -> action == :eat_bagel end)
        assert Enum.any?(plan_actions, fn {action, _} -> action == :drink_coffee end)

      {:error, reason} ->
        require Logger
        Logger.error("Planning failed: #{inspect(reason)}")
        Logger.error("No solution tree returned.")
        flunk("Planning failed: #{reason}")
    end
  end

  # --- Domain and Action Definitions ---

  defp build_coffee_bagel_domain do
    Domain.new("coffee_bagel")
    |> Domain.add_action(:brew_coffee, &brew_coffee_action/2, %{duration: 300_000})
    |> Domain.add_action(:toast_bagel, &toast_bagel_action/2, %{duration: 180_000})
    |> Domain.add_action(:eat_bagel, &eat_bagel_action/2, %{duration: 0})
    |> Domain.add_action(:drink_coffee, &drink_coffee_action/2, %{duration: 0})
    |> Domain.add_unigoal_method("coffee", &achieve_coffee_unigoal/2)
    |> Domain.add_unigoal_method("bagel", &achieve_bagel_unigoal/2)
    |> Domain.add_unigoal_method("time", &achieve_time_unigoal/2)
    |> Domain.add_unigoal_method("status", &achieve_status_unigoal/2)
    |> Domain.add_unigoal_method("consumed", &achieve_consumed_unigoal/2)
    |> Domain.add_unigoal_method("current", &achieve_current_unigoal/2)
  end

  # Brew coffee action (durative logic inside)
  defp brew_coffee_action(state, []) do
    require Logger
    Logger.debug("brew_coffee_action called with state: #{inspect(state)}")

    if StateV2.get_fact(state, "coffee", "status") == "raw" do
      Logger.debug("brew_coffee_action: coffee is raw, proceeding to brew")
      # Start brewing
      state = StateV2.set_fact(state, "coffee", "status", "brewing")
      # Simulate time passing and finish brewing
      new_time = StateV2.get_fact(state, "time", "current") + 300_000

      state
      |> StateV2.set_fact("coffee", "status", "brewed")
      |> StateV2.set_fact("time", "current", new_time)
    else
      Logger.warning(
        "brew_coffee_action: precondition failed, coffee status: #{inspect(StateV2.get_fact(state, "coffee", "status"))}",
        []
      )

      false
    end
  end

  # Toast bagel action (durative logic inside)
  defp toast_bagel_action(state, []) do
    require Logger
    Logger.debug("toast_bagel_action called with state: #{inspect(state)}")

    if StateV2.get_fact(state, "bagel", "status") == "raw" do
      Logger.debug("toast_bagel_action: bagel is raw, proceeding to toast")
      # Start toasting
      state = StateV2.set_fact(state, "bagel", "status", "toasting")
      # Simulate time passing and finish toasting
      new_time = StateV2.get_fact(state, "time", "current") + 180_000

      state
      |> StateV2.set_fact("bagel", "status", "toasted")
      |> StateV2.set_fact("time", "current", new_time)
    else
      Logger.warning(
        "toast_bagel_action: precondition failed, bagel status: #{inspect(StateV2.get_fact(state, "bagel", "status"))}",
        []
      )

      false
    end
  end

  defp eat_bagel_action(state, []) do
    require Logger
    Logger.debug("eat_bagel_action called with state: #{inspect(state)}")

    if StateV2.get_fact(state, "bagel", "status") == "toasted" do
      Logger.debug("eat_bagel_action: bagel is toasted, proceeding to consume")
      StateV2.set_fact(state, "bagel", "status", "consumed")
    else
      Logger.warning(
        "eat_bagel_action: precondition failed, bagel status: #{inspect(StateV2.get_fact(state, "bagel", "status"))}",
        []
      )

      false
    end
  end

  defp drink_coffee_action(state, []) do
    require Logger
    Logger.debug("drink_coffee_action called with state: #{inspect(state)}")

    if StateV2.get_fact(state, "coffee", "status") == "brewed" do
      Logger.debug("drink_coffee_action: coffee is brewed, proceeding to consume")
      StateV2.set_fact(state, "coffee", "status", "consumed")
    else
      Logger.warning(
        "drink_coffee_action: precondition failed, coffee status: #{inspect(StateV2.get_fact(state, "coffee", "status"))}",
        []
      )

      false
    end
  end

  defp achieve_coffee_unigoal(state, ["status", "consumed"]) do
    require Logger
    Logger.debug("achieve_coffee_unigoal called with state: #{inspect(state)}")

    case StateV2.get_fact(state, "coffee", "status") do
      "consumed" ->
        []

      "brewed" ->
        [{:drink_coffee, []}]

      "raw" ->
        [{:brew_coffee, []}, {:drink_coffee, []}]

      other ->
        Logger.warning("achieve_coffee_unigoal: unexpected coffee status: #{inspect(other)}", [])
        false
    end
  end

  defp achieve_coffee_unigoal(_state, _args), do: false

  defp achieve_bagel_unigoal(state, ["status", "consumed"]) do
    require Logger
    Logger.debug("achieve_bagel_unigoal called with state: #{inspect(state)}")

    case StateV2.get_fact(state, "bagel", "status") do
      "consumed" ->
        []

      "toasted" ->
        [{:eat_bagel, []}]

      "raw" ->
        [{:toast_bagel, []}, {:eat_bagel, []}]

      other ->
        Logger.warning("achieve_bagel_unigoal: unexpected bagel status: #{inspect(other)}", [])
        false
    end
  end

  defp achieve_bagel_unigoal(_state, _args), do: false

  defp achieve_time_unigoal(_state, _args), do: []

  defp achieve_status_unigoal(_state, _args), do: []
  defp achieve_consumed_unigoal(_state, _args), do: []
  defp achieve_current_unigoal(_state, _args), do: []
end
