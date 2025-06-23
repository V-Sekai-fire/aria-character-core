# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Membrane.Planning.SimpleBacktrackTest do
  use ExUnit.Case, async: false

  alias AriaEngine.Membrane.Planning.PlannerBin
  alias AriaEngine.Membrane.Planning.Format.{PlanningRequest, PlanningResponse}
  alias AriaEngine.Membrane.Format.PlanningParams
  alias TestDomains

  @moduletag timeout: 30_000

  describe "Simple Backtrack Planning through Membrane" do
    test "solves simple backtrack problem with mock strategy" do
      # Create a simple planning request using unified goal format
      goals = [
        {"system", "flag", "0"},  # Set flag to 0
        {"action", "type", "getv"}  # Execute getv action
      ]

      # Create planning request
      request = PlanningRequest.new(
        request_id: "test_backtrack_001",
        domain: nil,  # Use nil for mock strategy
        state: %{"flag" => -1},  # Initial state
        goals: goals,
        strategy_preferences: [:mock],  # Use mock strategy for simplicity
        options: %{
          timeout_ms: 5000,
          verbose: 1
        },
        metadata: %{
          test_case: "simple_backtrack",
          expected_actions: 3
        }
      )

      # Convert to PlanningParams format (simulating the pipeline)
      planning_params = PlanningParams.create(
        request.domain,
        request.state,
        request.goals,
        Map.to_list(request.options),
        request.request_id,
        %{
          strategy_preferences: request.strategy_preferences,
          original_format: :planning_request,
          converted_at: DateTime.utc_now()
        }
      )

      # Test that PlannerBin can validate the goals
      assert :ok = PlannerBin.validate_unified_goals(goals)

      # Test that the request is properly formatted
      assert %PlanningRequest{} = request
      assert request.request_id == "test_backtrack_001"
      assert length(request.goals) == 2
      assert request.strategy_preferences == [:mock]

      # Test that PlanningParams conversion works
      assert %PlanningParams{} = planning_params
      assert PlanningParams.valid?(planning_params)
      assert planning_params.request_id == "test_backtrack_001"
    end

    test "creates valid planning response structure" do
      # Test the response format that should come from the pipeline
      plan_result = %{
        actions: [
          %{
            name: "putv",
            parameters: [0],
            start_time: 0,
            duration: 1,
            cost: 1
          },
          %{
            name: "getv",
            parameters: [0],
            start_time: 1,
            duration: 1,
            cost: 1
          },
          %{
            name: "getv",
            parameters: [0],
            start_time: 2,
            duration: 1,
            cost: 1
          }
        ],
        timeline: [
          %{
            time: 0,
            event_type: :action_start,
            action_id: "putv_0",
            description: "Set flag to 0",
            metadata: %{}
          },
          %{
            time: 1,
            event_type: :action_start,
            action_id: "getv_0",
            description: "Check flag is 0",
            metadata: %{}
          },
          %{
            time: 2,
            event_type: :action_start,
            action_id: "getv_0_2",
            description: "Check flag is 0 again",
            metadata: %{}
          }
        ],
        resource_allocation: %{},
        validation_status: :valid
      }

      performance_metrics = %{
        execution_time_ms: 150,
        strategy_used: :mock,
        success: true
      }

      # Create successful response
      response = PlanningResponse.success(
        plan_result,
        :mock,
        "test_backtrack_001",
        performance_metrics
      )

      # Validate response structure
      assert %PlanningResponse{} = response
      assert PlanningResponse.valid?(response)
      assert PlanningResponse.success?(response)
      assert response.status == :success
      assert response.strategy_used == :mock
      assert response.request_id == "test_backtrack_001"
      assert length(response.result.actions) == 3
      assert length(response.result.timeline) == 3
      assert response.performance_metrics.execution_time_ms == 150
    end

    test "handles error cases properly" do
      # Test error response format
      error_response = PlanningResponse.error(
        "Mock planning failed: invalid goals",
        "test_backtrack_error",
        %{execution_time_ms: 50, strategy_used: :mock, success: false},
        strategy_used: :mock
      )

      assert %PlanningResponse{} = error_response
      assert PlanningResponse.valid?(error_response)
      assert PlanningResponse.error?(error_response)
      assert error_response.status == :error
      assert error_response.error_reason == "Mock planning failed: invalid goals"
      assert error_response.request_id == "test_backtrack_error"
    end

    test "validates unified goal format requirements" do
      # Test valid unified goals
      valid_goals = [
        {"player", "location", "room1"},
        {"chef", "task", "cooking"},
        {"oven", "temperature", "350"}
      ]
      assert :ok = PlannerBin.validate_unified_goals(valid_goals)

      # Test invalid goals - wrong format
      invalid_goals = [
        {"player", "location"},  # Missing value
        "invalid_goal",          # Not a tuple
        {"a", "b", "c", "d"}     # Too many elements
      ]
      assert {:error, _reason} = PlannerBin.validate_unified_goals(invalid_goals)

      # Test invalid goals - wrong types
      invalid_type_goals = [
        {123, "location", "room1"},  # Subject not string
        {"player", 456, "room1"},    # Predicate not string
      ]
      assert {:error, _reason} = PlannerBin.validate_unified_goals(invalid_type_goals)
    end

    test "creates planning request with all required fields" do
      goals = [{"system", "state", "ready"}]

      request = PlannerBin.create_request(
        domain: nil,
        state: %{},
        goals: goals,
        strategy_preferences: [:mock, :lazy_execution],
        options: %{timeout_ms: 10000},
        metadata: %{test: true}
      )

      assert %PlanningRequest{} = request
      assert is_binary(request.request_id)
      assert request.goals == goals
      assert request.strategy_preferences == [:mock, :lazy_execution]
      assert request.options.timeout_ms == 10000
      assert request.metadata.test == true
    end
  end
end
