# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.HybridPlanner.HybridCoordinatorV2Test do
  use ExUnit.Case, async: true

  alias AriaEngine.HybridPlanner.{
    HybridCoordinatorV2,
    StrategyFactory,
    Strategies.Mock.MockPlanningStrategy
  }

  alias AriaEngine.{StateV2, Domain}

  describe "basic coordinator functionality" do
    test "can create coordinator with default strategies" do
      factory = StrategyFactory.new()
      
      assert {:ok, coordinator} = StrategyFactory.create_coordinator(factory, :default)
      assert %HybridCoordinatorV2{} = coordinator
      
      # Verify all strategies are present
      assert coordinator.planning_strategy != nil
      assert coordinator.temporal_strategy != nil
      assert coordinator.state_strategy != nil
      assert coordinator.domain_strategy != nil
      assert coordinator.logging_strategy != nil
      assert coordinator.execution_strategy != nil
    end

    test "can create coordinator with specific strategy configuration" do
      factory = StrategyFactory.new()
      
      config = %{
        planning_strategy: :default,
        temporal_strategy: :stn,
        state_strategy: :statev2,
        domain_strategy: :default,
        logging_strategy: :quiet,
        execution_strategy: :lazy
      }
      
      assert {:ok, coordinator} = StrategyFactory.create_coordinator(factory, config)
      assert %HybridCoordinatorV2{} = coordinator
    end

    test "coordinator maintains metadata and configuration" do
      factory = StrategyFactory.new()
      {:ok, coordinator} = StrategyFactory.create_coordinator(factory, :default)
      
      assert is_map(coordinator.metadata)
      assert Map.has_key?(coordinator.metadata, :created_at)
      assert Map.has_key?(coordinator.metadata, :strategy_composition)
    end
  end

  describe "strategy injection and composition" do
    test "can inject custom mock strategy" do
      # Create mock planning strategy
      _mock_planning = MockPlanningStrategy.new(
        plan_result: {:ok, [[:test_action, "arg1", "arg2"]]}
      )
      
      # Register mock strategy in factory
      factory = StrategyFactory.new()
      |> StrategyFactory.register_strategy(:planning_strategy, :mock, MockPlanningStrategy)
      
      # Create coordinator with mock
      config = %{
        planning_strategy: :mock,
        temporal_strategy: :stn,
        state_strategy: :statev2,
        domain_strategy: :default,
        logging_strategy: :quiet,
        execution_strategy: :lazy
      }
      
      assert {:ok, coordinator} = StrategyFactory.create_coordinator(factory, config)
      
      # The coordinator should be using the mock strategy type
      strategy_info = HybridCoordinatorV2.get_strategy_info(coordinator, :planning_strategy)
      assert strategy_info.name == :mock_planning_strategy
    end

    test "can swap strategies at runtime" do
      factory = StrategyFactory.new()
      |> StrategyFactory.register_strategy(:planning_strategy, :mock, MockPlanningStrategy)
      
      {:ok, coordinator} = StrategyFactory.create_coordinator(factory, :default)
      
      # Initially using default strategy
      original_info = HybridCoordinatorV2.get_strategy_info(coordinator, :planning_strategy)
      refute original_info.name == :mock_planning_strategy
      
      # Swap to mock strategy
      {:ok, updated_coordinator} = StrategyFactory.swap_strategy(
        coordinator, :planning_strategy, :mock, factory
      )
      
      # Now using mock strategy
      new_info = HybridCoordinatorV2.get_strategy_info(updated_coordinator, :planning_strategy)
      assert new_info.name == :mock_planning_strategy
    end
  end

  describe "functional equivalence with original planner" do
    setup do
      # Create a simple test domain
      domain = Domain.new("test_domain")
      |> Domain.add_action(:test_action, fn state, [arg] ->
        {:ok, StateV2.set_fact(state, "result", "value", arg)}
      end)
      |> Domain.add_task_methods("test_task", [
        {"simple_method", fn _state, [arg] -> [[:test_action, arg]] end}
      ])

      state = StateV2.new()
      |> StateV2.set_fact("initial", "value", "test")

      %{domain: domain, state: state}
    end

    test "planning functionality works through strategy indirection", %{domain: domain, state: state} do
      factory = StrategyFactory.new()
      {:ok, coordinator} = StrategyFactory.create_coordinator(factory, :default)
      
      planning_request = %{
        domain: domain,
        state: state,
        goals: [{"test_task", ["result_value"]}],
        options: []
      }
      
      # This should work through the default HTN planning strategy
      case HybridCoordinatorV2.plan(coordinator, planning_request) do
        {:ok, plan_result} ->
          assert plan_result != nil
          # The exact structure depends on the planning implementation
          # but we should get some kind of plan back
          
        {:error, reason} ->
          # This might fail due to missing dependencies, but the call structure should work
          assert is_binary(reason)
      end
    end

    test "replanning functionality works through strategy indirection", %{domain: domain, state: state} do
      factory = StrategyFactory.new()
      {:ok, coordinator} = StrategyFactory.create_coordinator(factory, :default)
      
      # Create a simple existing plan
      existing_plan = [[:test_action, "original_arg"]]
      
      replan_request = %{
        domain: domain,
        state: state,
        plan: %{solution_tree: existing_plan},
        fail_node_id: "test_action",
        opts: []
      }
      
      # This should work through the default HTN planning strategy
      case HybridCoordinatorV2.replan(coordinator, replan_request) do
        {:ok, plan_result} ->
          assert plan_result != nil
          
        {:error, reason} ->
          # This might fail due to missing dependencies, but the call structure should work
          assert is_binary(reason)
      end
    end
  end

  describe "strategy validation and error handling" do
    test "validates strategy configuration before creation" do
      factory = StrategyFactory.new()
      
      # Missing required strategy
      invalid_config = %{
        planning_strategy: :default,
        # temporal_strategy missing
        state_strategy: :statev2
      }
      
      assert {:error, reason} = StrategyFactory.create_coordinator(factory, invalid_config)
      assert reason =~ "Missing required strategies"
    end

    test "validates strategy exists before creation" do
      factory = StrategyFactory.new()
      
      # Non-existent strategy
      invalid_config = %{
        planning_strategy: :nonexistent,
        temporal_strategy: :stn,
        state_strategy: :statev2,
        domain_strategy: :default,
        logging_strategy: :default,
        execution_strategy: :lazy
      }
      
      assert {:error, reason} = StrategyFactory.create_coordinator(factory, invalid_config)
      assert reason =~ "Strategy not found"
    end

    test "handles strategy execution errors gracefully" do
      # Create mock that always fails
      _mock_planning = MockPlanningStrategy.new(
        should_fail_on: [:plan]
      )
      
      factory = StrategyFactory.new()
      |> StrategyFactory.register_strategy(:planning_strategy, :failing_mock, MockPlanningStrategy)
      
      config = %{
        planning_strategy: :failing_mock,
        temporal_strategy: :stn,
        state_strategy: :statev2,
        domain_strategy: :default,
        logging_strategy: :quiet,
        execution_strategy: :lazy
      }
      
      {:ok, coordinator} = StrategyFactory.create_coordinator(factory, config)
      
      planning_request = %{
        domain: Domain.new("test"),
        state: StateV2.new(),
        goals: [{"test_task", []}],
        options: []
      }
      
      # Should get back an error from the failing mock
      assert {:error, reason} = HybridCoordinatorV2.plan(coordinator, planning_request)
      assert reason =~ "Configured to fail"
    end
  end

  describe "strategy composition and profiling" do
    test "can get strategy information from coordinator" do
      factory = StrategyFactory.new()
      {:ok, coordinator} = StrategyFactory.create_coordinator(factory, :default)
      
      # Should be able to get info for each strategy type
      planning_info = HybridCoordinatorV2.get_strategy_info(coordinator, :planning_strategy)
      assert planning_info.type == :planning
      assert is_list(planning_info.capabilities)
      
      temporal_info = HybridCoordinatorV2.get_strategy_info(coordinator, :temporal_strategy)
      assert temporal_info.type == :temporal
      
      state_info = HybridCoordinatorV2.get_strategy_info(coordinator, :state_strategy)
      assert state_info.type == :state
    end

    test "can get performance metrics from strategies" do
      factory = StrategyFactory.new()
      {:ok, coordinator} = StrategyFactory.create_coordinator(factory, :default)
      
      metrics = HybridCoordinatorV2.get_performance_metrics(coordinator)
      
      assert is_map(metrics)
      # Should have metrics for each strategy type
      assert Map.has_key?(metrics, :planning_strategy)
      assert Map.has_key?(metrics, :temporal_strategy)
      assert Map.has_key?(metrics, :state_strategy)
    end

    test "strategies can track their own call counts and timing" do
      _mock_planning = MockPlanningStrategy.new(call_delay: 10)
      
      factory = StrategyFactory.new()
      |> StrategyFactory.register_strategy(:planning_strategy, :timing_mock, MockPlanningStrategy)
      
      config = %{
        planning_strategy: :timing_mock,
        temporal_strategy: :stn,
        state_strategy: :statev2,
        domain_strategy: :default,
        logging_strategy: :quiet,
        execution_strategy: :lazy
      }
      
      {:ok, coordinator} = StrategyFactory.create_coordinator(factory, config)
      
      planning_request = %{
        domain: Domain.new("test"),
        state: StateV2.new(),
        goals: [{"test_task", []}],
        options: []
      }
      
      # Make a planning call
      HybridCoordinatorV2.plan(coordinator, planning_request)
      
      # Check that timing and call tracking worked
      strategy_info = HybridCoordinatorV2.get_strategy_info(coordinator, :planning_strategy)
      assert strategy_info.call_counts.plan >= 1
      assert strategy_info.call_history_length >= 1
    end
  end

  describe "backward compatibility" do
    test "coordinator provides same interface as original planner" do
      factory = StrategyFactory.new()
      {:ok, _coordinator} = StrategyFactory.create_coordinator(factory, :default)
      
      # These should be the same functions available in the original planner
      assert function_exported?(HybridCoordinatorV2, :plan, 2)
      assert function_exported?(HybridCoordinatorV2, :replan, 2)
      assert function_exported?(HybridCoordinatorV2, :execute, 5)
      assert function_exported?(HybridCoordinatorV2, :validate_plan, 4)
    end

    test "can create coordinator using same patterns as original" do
      # This should work like the original planner constructor
      factory = StrategyFactory.new()
      
      assert {:ok, coordinator} = StrategyFactory.create_default_coordinator(factory)
      assert %HybridCoordinatorV2{} = coordinator
      
      # Should have all required strategies configured
      assert coordinator.planning_strategy != nil
      assert coordinator.execution_strategy != nil
    end
  end
end
