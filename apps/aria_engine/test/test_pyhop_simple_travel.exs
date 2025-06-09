# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.PyhopSimpleTravelTest do
  @moduledoc """
  Test suite for Pyhop Simple Travel Example.

  This implements the pyhop_simple_travel_example from GTPyhop, which
  demonstrates near-backward-compatibility with the original Pyhop planner.
  It's a simpler version of the travel domain with basic movement by foot and taxi.
  """

  use ExUnit.Case

  import AriaEngine
  alias AriaEngine.{State, TestDomains}

  @moduletag timeout: 120_000

  describe "Pyhop Simple Travel domain" do
    test "domain creation and basic functionality" do
      domain = TestDomains.build_pyhop_simple_travel_domain()
      summary = AriaEngine.domain_summary(domain)

      assert summary.name == "pyhop_simple_travel"
      assert :walk in summary.actions
      assert :call_taxi in summary.actions
      assert :ride_taxi in summary.actions
      assert :pay_driver in summary.actions
      assert "travel" in summary.task_methods
    end

    test "basic travel planning with different verbosity" do
      domain = TestDomains.build_pyhop_simple_travel_domain()

      state1 = create_state()
      |> set_fact("loc", "me", "home")
      |> set_fact("cash", "me", 20)
      |> set_fact("owe", "me", 0)
      |> set_fact("dist", {"home", "park"}, 8)
      |> set_fact("dist", {"park", "home"}, 8)

      # Test travel from home to park
      {:ok, plan} = plan(domain, state1, [{"travel", "me", "home", "park"}])

      # Should choose taxi since distance > 2
      expected = [{"call_taxi", "me", "home"}, {"ride_taxi", "me", "home", "park"}, {"pay_driver", "me"}]
      assert plan == expected
    end

    test "travel by foot for short distances" do
      domain = TestDomains.build_pyhop_simple_travel_domain()

      state1 = create_state()
      |> set_fact("loc", "me", "home")
      |> set_fact("cash", "me", 20)
      |> set_fact("owe", "me", 0)
      |> set_fact("dist", {"home", "nearby"}, 2)
      |> set_fact("dist", {"nearby", "home"}, 2)

      # Test short distance travel
      {:ok, plan} = plan(domain, state1, [{"travel", "me", "home", "nearby"}])

      # Should choose walking since distance <= 2
      expected = [{"walk", "me", "home", "nearby"}]
      assert plan == expected
    end

    test "insufficient cash prevents taxi travel" do
      domain = TestDomains.build_pyhop_simple_travel_domain()

      state1 = create_state()
      |> set_fact("loc", "me", "home")
      |> set_fact("cash", "me", 1)  # Not enough cash for taxi
      |> set_fact("owe", "me", 0)
      |> set_fact("dist", {"home", "park"}, 8)
      |> set_fact("dist", {"park", "home"}, 8)

      # Should fail - can't afford taxi and too far to walk
      assert {:error, _} = plan(domain, state1, [{"travel", "me", "home", "park"}])
    end

    test "action execution" do
      domain = TestDomains.build_pyhop_simple_travel_domain()

      # Test walk action
      state1 = create_state()
      |> set_fact("loc", "me", "home")

      {:ok, new_state} = execute_action(domain, state1, {"walk", "me", "home", "park"})
      assert get_fact(new_state, "loc", "me") == "park"

      # Test call_taxi action
      state2 = create_state()
      |> set_fact("loc", "me", "home")

      {:ok, new_state} = execute_action(domain, state2, {"call_taxi", "me", "home"})
      assert get_fact(new_state, "loc", "taxi") == "home"

      # Test ride_taxi action
      state3 = create_state()
      |> set_fact("loc", "me", "taxi")
      |> set_fact("loc", "taxi", "home")
      |> set_fact("cash", "me", 20)
      |> set_fact("owe", "me", 0)
      |> set_fact("dist", {"home", "park"}, 8)
      |> set_fact("dist", {"park", "home"}, 8)

      {:ok, new_state} = execute_action(domain, state3, {"ride_taxi", "me", "home", "park"})
      assert get_fact(new_state, "loc", "taxi") == "park"
      assert get_fact(new_state, "loc", "me") == "taxi"
      assert get_fact(new_state, "owe", "me") == taxi_rate(8)

      # Test pay_driver action
      {:ok, final_state} = execute_action(domain, new_state, {"pay_driver", "me"})
      cash_after = get_fact(final_state, "cash", "me")
      owe_after = get_fact(final_state, "owe", "me")

      assert cash_after == 20 - taxi_rate(8)
      assert owe_after == 0
    end
  end
end
    domain = create_domain("pyhop_simple_travel")

    # Add actions (using operators for backward compatibility)
    domain
    |> add_action(:walk, &walk_action/2)
    |> add_action(:call_taxi, &call_taxi_action/2)
    |> add_action(:ride_taxi, &ride_taxi_action/2)
    |> add_action(:pay_driver, &pay_driver_action/2)

    # Add task methods
    |> add_task_method("travel", &travel_by_foot_method/2)
    |> add_task_method("travel", &travel_by_taxi_method/2)
  end

  # Taxi rate calculation (matches GTPyhop)
  defp taxi_rate(dist), do: 1.5 + 0.5 * dist

  # Action implementations
  defp walk_action(state, [person, from, to]) do
    current_loc = get_fact(state, "loc", person)

    if current_loc == from do
      set_fact(state, "loc", person, to)
    else
      nil
    end
  end

  defp call_taxi_action(state, [person, location]) do
    state
    |> set_fact("loc", "taxi", location)
  end

  defp ride_taxi_action(state, [person, from, to]) do
    person_loc = get_fact(state, "loc", person)
    taxi_loc = get_fact(state, "loc", "taxi")
    dist = get_distance(state, from, to)

    if taxi_loc == from and person_loc == from do
      state
      |> set_fact("loc", "taxi", to)
      |> set_fact("loc", person, to)
      |> set_fact("owe", person, taxi_rate(dist))
    else
      nil
    end
  end

  defp pay_driver_action(state, [person]) do
    cash = get_fact(state, "cash", person)
    owe = get_fact(state, "owe", person)

    if cash >= owe do
      state
      |> set_fact("cash", person, cash - owe)
      |> set_fact("owe", person, 0)
    else
      nil
    end
  end

  # Method implementations
  defp travel_by_foot_method(state, [person, from, to]) do
    dist = get_distance(state, from, to)

    if dist && dist <= 2 do
      [{"walk", person, from, to}]
    else
      nil
    end
  end

  defp travel_by_taxi_method(state, [person, from, to]) do
    cash = get_fact(state, "cash", person)
    dist = get_distance(state, from, to)

    if dist && cash >= taxi_rate(dist) do
      [{"call_taxi", person, from}, {"ride_taxi", person, from, to}, {"pay_driver", person}]
    else
      nil
    end
  end

  # Helper functions
  defp get_distance(state, from, to) do
    # Try both directions since distance should be symmetric
    get_fact(state, "dist", {from, to}) || get_fact(state, "dist", {to, from})
  end

  # Helper function to execute a single action for testing
  defp execute_action(domain, state, action) do
    case action do
      {action_name, arg1} ->
        action_func = domain.actions[String.to_atom(action_name)]
        if action_func do
          result = action_func.(state, [arg1])
          if result, do: {:ok, result}, else: {:error, "Action failed"}
        else
          {:error, "Action not found"}
        end

      {action_name, arg1, arg2} ->
        action_func = domain.actions[String.to_atom(action_name)]
        if action_func do
          result = action_func.(state, [arg1, arg2])
          if result, do: {:ok, result}, else: {:error, "Action failed"}
        else
          {:error, "Action not found"}
        end

      {action_name, arg1, arg2, arg3} ->
        action_func = domain.actions[String.to_atom(action_name)]
        if action_func do
          result = action_func.(state, [arg1, arg2, arg3])
          if result, do: {:ok, result}, else: {:error, "Action failed"}
        else
          {:error, "Action not found"}
        end

      _ ->
        {:error, "Invalid action format"}
    end
  end
end
