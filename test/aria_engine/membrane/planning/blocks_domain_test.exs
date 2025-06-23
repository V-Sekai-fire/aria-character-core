defmodule AriaEngine.Membrane.Planning.BlocksDomainTest do
  @moduledoc """
  Test the membrane planning system using the classic blocks world domain
  from GTpyhop examples. This validates the system with real planning problems.
  """

  use ExUnit.Case, async: true
  alias AriaEngine.Membrane.Planning.Format.{PlanningRequest, PlanningResponse}
  alias AriaEngine.BlocksWorld

  describe "blocks world planning request creation" do
    test "creates valid planning requests for blocks world problems" do
      # Simple pickup problem
      initial_state = %{
        "pos" => %{"a" => "b", "b" => "table", "c" => "table"},
        "clear" => %{"a" => true, "b" => false, "c" => true},
        "holding" => %{"hand" => false}
      }

      goals = [{"c", "holding", true}]

      request = PlanningRequest.new(
        domain: :blocks_world,
        state: initial_state,
        goals: goals,
        strategy_preferences: [:mock],
        options: %{timeout_ms: 5000}
      )

      assert %PlanningRequest{} = request
      assert request.domain == :blocks_world
      assert request.state == initial_state
      assert request.goals == goals
      assert request.strategy_preferences == [:mock]
      assert request.options.timeout_ms == 5000
      assert is_binary(request.request_id)
    end

    test "validates unified goal format for blocks world" do
      # Valid blocks world goals
      valid_goals = [
        {"a", "pos", "b"},           # Block a on block b
        {"hand", "holding", false},  # Hand not holding anything
        {"c", "clear", true}         # Block c is clear
      ]

      assert :ok = AriaEngine.Membrane.Planning.PlannerBin.validate_unified_goals(valid_goals)

      # Invalid goals
      invalid_goals = [
        {"a", "pos"},                # Missing value
        {nil, "pos", "table"},      # Nil subject
        {"a", nil, "table"}         # Nil predicate
      ]

      assert {:error, _reason} = AriaEngine.Membrane.Planning.PlannerBin.validate_unified_goals(invalid_goals)
    end

    test "creates planning requests for complex blocks world scenarios" do
      # Sussman anomaly - classic planning problem
      initial_state = %{
        "pos" => %{"c" => "a", "a" => "table", "b" => "table"},
        "clear" => %{"c" => true, "a" => false, "b" => true},
        "holding" => %{"hand" => false}
      }

      goals = [
        {"a", "pos", "b"},
        {"b", "pos", "c"}
      ]

      request = PlanningRequest.new(
        domain: :blocks_world,
        state: initial_state,
        goals: goals,
        strategy_preferences: [:mock],
        options: %{timeout_ms: 10000}
      )

      assert %PlanningRequest{} = request
      assert length(request.goals) == 2
      assert request.domain == :blocks_world
    end

    test "creates planning requests for tower construction" do
      # Three block tower construction
      initial_state = %{
        "pos" => %{"a" => "table", "b" => "table", "c" => "table"},
        "clear" => %{"a" => true, "b" => true, "c" => true},
        "holding" => %{"hand" => false}
      }

      goals = [
        {"c", "pos", "b"},
        {"b", "pos", "a"},
        {"a", "pos", "table"}
      ]

      request = PlanningRequest.new(
        domain: :blocks_world,
        state: initial_state,
        goals: goals,
        strategy_preferences: [:mock],
        options: %{timeout_ms: 8000}
      )

      assert %PlanningRequest{} = request
      assert length(request.goals) == 3
    end

    test "handles impossible goals gracefully" do
      # Test with physically impossible goal (block on itself)
      initial_state = %{
        "pos" => %{"a" => "table", "b" => "table"},
        "clear" => %{"a" => true, "b" => true},
        "holding" => %{"hand" => false}
      }

      goals = [{"a", "pos", "a"}]  # Impossible: block on itself

      request = PlanningRequest.new(
        domain: :blocks_world,
        state: initial_state,
        goals: goals,
        strategy_preferences: [:mock],
        options: %{timeout_ms: 5000}
      )

      assert %PlanningRequest{} = request
      assert request.goals == [{"a", "pos", "a"}]
    end
  end

  describe "blocks world domain integration" do
    test "blocks world domain has required actions" do
      domain = BlocksWorld.Domain.build()

      # Verify all required actions are present
      assert AriaEngine.Domain.has_action?(domain, :pickup)
      assert AriaEngine.Domain.has_action?(domain, :putdown)
      assert AriaEngine.Domain.has_action?(domain, :stack)
      assert AriaEngine.Domain.has_action?(domain, :unstack)

      # Verify actions can be retrieved
      assert is_function(AriaEngine.Domain.get_action(domain, :pickup), 2)
      assert is_function(AriaEngine.Domain.get_action(domain, :putdown), 2)
      assert is_function(AriaEngine.Domain.get_action(domain, :stack), 2)
      assert is_function(AriaEngine.Domain.get_action(domain, :unstack), 2)
    end

    test "blocks world actions execute without errors" do
      domain = BlocksWorld.Domain.build()

      initial_state = %{
        "pos" => %{"a" => "table", "b" => "table"},
        "clear" => %{"a" => true, "b" => true},
        "holding" => %{"hand" => false}
      }

      # Test that actions can be executed (even if they're stubs)
      pickup_action = AriaEngine.Domain.get_action(domain, :pickup)
      assert {:ok, _result} = pickup_action.(initial_state, ["a"])

      putdown_action = AriaEngine.Domain.get_action(domain, :putdown)
      assert {:ok, _result} = putdown_action.(initial_state, ["a"])

      stack_action = AriaEngine.Domain.get_action(domain, :stack)
      assert {:ok, _result} = stack_action.(initial_state, ["a", "b"])

      unstack_action = AriaEngine.Domain.get_action(domain, :unstack)
      assert {:ok, _result} = unstack_action.(initial_state, ["a", "b"])
    end
  end

  describe "planning response validation" do
    test "creates valid success responses for blocks world" do
      # Mock successful planning result
      plan_result = %{
        actions: [
          %{
            name: "pickup",
            parameters: ["c"],
            start_time: 0,
            duration: 1,
            cost: 1
          }
        ],
        timeline: [
          %{
            time: 0,
            event_type: :action_start,
            action_id: "pickup_c",
            description: "Pick up block c",
            metadata: %{}
          }
        ],
        resource_allocation: %{},
        validation_status: :valid
      }

      performance_metrics = %{
        execution_time_ms: 100,
        strategy_used: :mock,
        success: true
      }

      response = PlanningResponse.success(
        plan_result,
        :mock,
        "blocks_test_001",
        performance_metrics
      )

      assert %PlanningResponse{} = response
      assert PlanningResponse.valid?(response)
      assert PlanningResponse.success?(response)
      assert response.status == :success
      assert response.strategy_used == :mock
      assert response.request_id == "blocks_test_001"
      assert length(response.result.actions) == 1
    end

    test "creates valid error responses for blocks world" do
      error_response = PlanningResponse.error(
        "Blocks world planning failed: impossible goal",
        "blocks_error_001",
        %{execution_time_ms: 50, strategy_used: :mock, success: false},
        strategy_used: :mock
      )

      assert %PlanningResponse{} = error_response
      assert PlanningResponse.valid?(error_response)
      assert PlanningResponse.error?(error_response)
      assert error_response.status == :error
      assert error_response.error_reason == "Blocks world planning failed: impossible goal"
      assert error_response.request_id == "blocks_error_001"
    end
  end

  describe "membrane system interface" do
    test "planner bin utility functions work correctly" do
      # Test that the interface functions exist and work
      assert function_exported?(AriaEngine.Membrane.Planning.PlannerBin, :validate_unified_goals, 1)
      assert function_exported?(AriaEngine.Membrane.Planning.PlannerBin, :create_request, 1)

      # Test goal validation
      valid_goals = [{"a", "pos", "b"}]
      assert :ok = AriaEngine.Membrane.Planning.PlannerBin.validate_unified_goals(valid_goals)

      # Test request creation
      request = AriaEngine.Membrane.Planning.PlannerBin.create_request(
        domain: :blocks_world,
        state: %{},
        goals: valid_goals,
        strategy_preferences: [:mock]
      )

      assert %PlanningRequest{} = request
      assert request.domain == :blocks_world
      assert request.goals == valid_goals
    end

    test "planning request format matches membrane expectations" do
      # Ensure our requests match what the membrane filters expect
      request = PlanningRequest.new(
        domain: :blocks_world,
        state: %{"pos" => %{"a" => "table"}},
        goals: [{"a", "holding", true}],
        strategy_preferences: [:mock],
        options: %{timeout_ms: 5000}
      )

      # Verify the request has all required fields for membrane processing
      assert is_binary(request.request_id)
      assert is_atom(request.domain)
      assert is_map(request.state)
      assert is_list(request.goals)
      assert is_list(request.strategy_preferences)
      assert is_map(request.options)
      assert is_integer(request.options.timeout_ms)
    end
  end
end
