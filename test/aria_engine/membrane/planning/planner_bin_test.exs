# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Membrane.Planning.PlannerBinTest do
  use ExUnit.Case, async: true

  alias AriaEngine.Membrane.Planning.PlannerBin
  alias AriaEngine.Membrane.Planning.Format.PlanningRequest

  describe "PlannerBin" do
    test "validates unified goal format correctly" do
      # Valid goals following ADR-134 format
      valid_goals = [
        {"player", "location", "room1"},
        {"chef", "task", "cooking"},
        {"oven", "temperature", 350}
      ]

      assert :ok = PlannerBin.validate_unified_goals(valid_goals)
    end

    test "rejects invalid goal formats" do
      # Invalid goals - not a 3-tuple
      invalid_goals = [
        {"player", "location"}  # Missing value
      ]

      assert {:error, _reason} = PlannerBin.validate_unified_goals(invalid_goals)
    end

    test "creates planning request with unified format" do
      goals = [
        {"player", "location", "room1"},
        {"chef", "task", "cooking"}
      ]

      request = PlannerBin.create_request(
        domain: nil,
        state: nil,
        goals: goals,
        strategy_preferences: [:mock]
      )

      assert %PlanningRequest{} = request
      assert length(request.goals) == 2
      assert request.strategy_preferences == [:mock]
    end

    test "has required interface functions" do
      # Verify the interface exists
      assert function_exported?(PlannerBin, :get_strategy_stats, 1)
      assert function_exported?(PlannerBin, :get_active_requests, 1)
      assert function_exported?(PlannerBin, :validate_unified_goals, 1)
      assert function_exported?(PlannerBin, :create_request, 1)
    end
  end
end
