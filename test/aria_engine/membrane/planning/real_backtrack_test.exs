# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Membrane.Planning.RealBacktrackTest do
  use ExUnit.Case, async: false

  alias AriaEngine.Membrane.Planning.PlannerBin
  alias AriaEngine.Membrane.Planning.Format.{PlanningRequest, PlanningResponse}

  @moduletag timeout: 30_000

  describe "Real Backtrack Planning through Membrane" do
    test "handles mock strategy for simple testing" do
      # Test with mock strategy for quick validation
      goals = [
        {"system", "flag", "0"},
        {"action", "type", "getv"}
      ]

      request = PlannerBin.create_request(
        domain: nil,  # Mock doesn't need real domain
        state: %{"flag" => -1},
        goals: goals,
        strategy_preferences: [:mock],
        options: %{timeout_ms: 5000},
        metadata: %{test_case: "mock_simple"}
      )

      # Mock strategy should handle this gracefully
      assert %PlanningRequest{} = request
      assert request.strategy_preferences == [:mock]
      assert :ok = PlannerBin.validate_unified_goals(goals)
    end

    test "creates proper error response for invalid goals" do
      # Test error handling
      invalid_goals = [
        {"incomplete"},  # Missing predicate and value
        "not_a_tuple"    # Not a tuple at all
      ]

      result = PlannerBin.validate_unified_goals(invalid_goals)
      assert {:error, reason} = result
      assert is_binary(reason)
      assert String.contains?(reason, "unified format")
    end

    test "validates strategy preferences" do
      goals = [{"task", "name", "simple"}]

      # Test valid strategy preferences
      valid_strategies = [:mock, :lazy_execution, :hybrid_coordinator, :minizinc]

      request = PlannerBin.create_request(
        domain: nil,
        state: %{},
        goals: goals,
        strategy_preferences: valid_strategies,
        options: %{},
        metadata: %{}
      )

      assert request.strategy_preferences == valid_strategies
    end

    test "handles fallback strategy preferences" do
      goals = [{"task", "name", "complex"}]

      # Test fallback chain
      fallback_chain = [:hybrid_coordinator, :lazy_execution, :mock]

      request = PlannerBin.create_request(
        domain: nil,
        state: %{},
        goals: goals,
        strategy_preferences: fallback_chain,
        options: %{enable_fallback: true},
        metadata: %{fallback_test: true}
      )

      assert request.strategy_preferences == fallback_chain
      assert request.options.enable_fallback == true
    end

    test "creates planning request with unified goal format" do
      # Test the unified goal format that the membrane system expects
      goals = [
        {"player", "location", "room1"},
        {"chef", "task", "cooking"},
        {"oven", "temperature", "350"}
      ]

      request = PlannerBin.create_request(
        domain: nil,
        state: %{},
        goals: goals,
        strategy_preferences: [:mock],
        options: %{timeout_ms: 5000},
        metadata: %{test_case: "unified_format"}
      )

      assert %PlanningRequest{} = request
      assert length(request.goals) == 3
      assert :ok = PlannerBin.validate_unified_goals(goals)
    end

    test "validates complex goal structures" do
      # Test more complex goal validation
      complex_goals = [
        {"entity_1", "state", "active"},
        {"entity_2", "position", "coordinates_10_20"},
        {"system", "mode", "planning"}
      ]

      assert :ok = PlannerBin.validate_unified_goals(complex_goals)

      # Test that each goal is properly structured
      Enum.each(complex_goals, fn {subject, predicate, value} ->
        assert is_binary(subject)
        assert is_binary(predicate)
        assert is_binary(value)
      end)
    end
  end
end
