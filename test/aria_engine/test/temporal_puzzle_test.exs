defmodule TemporalPuzzleTest do
  use ExUnit.Case
  require Logger

  alias Domain
  alias StateV2
  alias Planner
  alias Timeline.Interval
  alias DateTime

  @moduledoc """
  ExUnit test for the temporal puzzle: making coffee and toasting a bagel.
  """

  defp build_coffee_bagel_domain do
    Domain.new("coffee_bagel")
    |> Domain.add_action(:brew_coffee_start, &brew_coffee_start_action/2, %{duration: Interval.from_duration(DateTime.utc_now(), 0, :millisecond)})
    |> Domain.add_action(:wait_for_brew, &wait_for_brew_action/2, %{duration: Interval.from_duration(DateTime.utc_now(), 300_000, :millisecond)})
    |> Domain.add_action(:toast_bagel_start, &toast_bagel_start_action/2, %{duration: Interval.from_duration(DateTime.utc_now(), 0, :millisecond)})
    |> Domain.add_action(:wait_for_toast, &wait_for_toast_action/2, %{duration: Interval.from_duration(DateTime.utc_now(), 180_000, :millisecond)})
    |> Domain.add_action(:eat_bagel, &eat_bagel_action/2, %{duration: Interval.from_duration(DateTime.utc_now(), 0, :millisecond)})
    |> Domain.add_action(:drink_coffee, &drink_coffee_action/2, %{duration: Interval.from_duration(DateTime.utc_now(), 0, :millisecond)})
    |> Domain.add_unigoal_method("coffee", &achieve_coffee_unigoal/2)
    |> Domain.add_unigoal_method("bagel", &achieve_bagel_unigoal/2)
  end

  defp brew_coffee_start_action(state, []) do
    if StateV2.get_fact(state, "status", "coffee") == "raw" do
      StateV2.set_fact(state, "coffee", "status", "brewing")
    else
      false
    end
  end

  defp wait_for_brew_action(state, []) do
    if StateV2.get_fact(state, "status", "coffee") == "brewing" do
      new_time = StateV2.get_fact(state, "current", "time") + 300_000
      StateV2.set_fact(state, "coffee", "status", "brewed")
      |> StateV2.set_fact("time", "current", new_time)
    else
      false
    end
  end

  defp toast_bagel_start_action(state, []) do
    if StateV2.get_fact(state, "status", "bagel") == "raw" do
      StateV2.set_fact(state, "bagel", "status", "toasting")
    else
      false
    end
  end

  defp wait_for_toast_action(state, []) do
    if StateV2.get_fact(state, "status", "bagel") == "toasting" do
      new_time = StateV2.get_fact(state, "current", "time") + 180_000
      StateV2.set_fact(state, "bagel", "status", "toasted")
      |> StateV2.set_fact("time", "current", new_time)
    else
      false
    end
  end

  defp eat_bagel_action(state, []) do
    if StateV2.get_fact(state, "status", "bagel") == "toasted" do
      StateV2.set_fact(state, "bagel", "status", "consumed")
    else
      false
    end
  end

  defp drink_coffee_action(state, []) do
    if StateV2.get_fact(state, "status", "coffee") == "brewed" do
      StateV2.set_fact(state, "coffee", "status", "consumed")
    else
      false
    end
  end

  defp achieve_coffee_unigoal(state, ["status", "consumed"]) do
    case StateV2.get_fact(state, "status", "coffee") do
      "consumed" -> []
      "brewed" -> [{:drink_coffee, []}]
      "brewing" -> [{:wait_for_brew, []}, {:drink_coffee, []}]
      "raw" -> [{:brew_coffee_start, []}, {:wait_for_brew, []}, {:drink_coffee, []}]
      _ -> false
    end
  end

  defp achieve_bagel_unigoal(state, ["status", "consumed"]) do
    case StateV2.get_fact(state, "status", "bagel") do
      "consumed" -> []
      "toasted" -> [{:eat_bagel, []}]
      "toasting" -> [{:wait_for_toast, []}, {:eat_bagel, []}]
      "raw" -> [{:toast_bagel_start, []}, {:wait_for_toast, []}, {:eat_bagel, []}]
      _ -> false
    end
  end

  test "temporal puzzle: coffee and bagel planning produces valid plan" do
    domain = build_coffee_bagel_domain()

    initial_state =
      StateV2.new()
      |> StateV2.set_fact("coffee", "status", "raw")
      |> StateV2.set_fact("bagel", "status", "raw")
      |> StateV2.set_fact("time", "current", 0)

    goals = [
      {"coffee", "status", "consumed"},
      {"bagel", "status", "consumed"}
    ]

    result = HybridCoordinatorV2.plan(HybridCoordinatorV2.new_default(), domain, initial_state, goals, verbose: 0)

    assert {:ok, solution_tree} = result

    plan_actions = Planner.extract_actions(solution_tree)
    assert Enum.any?(plan_actions, fn {action, _} -> action == :brew_coffee_start end)
    assert Enum.any?(plan_actions, fn {action, _} -> action == :wait_for_brew end)
    assert Enum.any?(plan_actions, fn {action, _} -> action == :toast_bagel_start end)
    assert Enum.any?(plan_actions, fn {action, _} -> action == :wait_for_toast end)
    assert Enum.any?(plan_actions, fn {action, _} -> action == :eat_bagel end)
    assert Enum.any?(plan_actions, fn {action, _} -> action == :drink_coffee end)
  end
end
