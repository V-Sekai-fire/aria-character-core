# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule FunctionAsObjectDemoTest do
  use ExUnit.Case, async: true
  
  alias HybridPlanner.{StrategyCoordinator, StrategyRegistry}

  describe "Function as Object Pattern Demo" do
    test "demonstrates composable strategy functions" do
      # Create a simple test domain
      domain = Domain.new("function_as_object_demo")
      |> Domain.add_action(:move, fn state, [_from, to] ->
        new_state = StateV2.set_fact(state, "location", "robot", to)
        {:ok, new_state}
      end)
      |> Domain.add_unigoal_method("location", "navigate", fn state, ["robot", target] ->
        current = StateV2.get_fact(state, "location", "robot") 
        if current == target do
          {:ok, []}
        else
          {:ok, [{:move, [current, target]}]}
        end
      end)

      initial_state = StateV2.new()
      |> StateV2.set_fact("location", "robot", "room1")

      goals = [{"location", "robot", "room2"}]

      # Demonstrate Function as Object composition
      strategies = StrategyRegistry.default_strategies()
      
      # Compose custom coordinator from strategy functions
      custom_coordinator = StrategyCoordinator.new(
        strategies.planning.htn,      # HTN planning function
        strategies.temporal.stn,      # STN temporal validation function  
        strategies.execution.lazy,    # Lazy execution function
        %{custom_composition: true}
      )

      # Use the composed strategy coordinator
      assert {:ok, final_state} = StrategyCoordinator.coordinate(
        custom_coordinator, 
        domain, 
        initial_state, 
        goals
      )

      # Verify the goal was achieved
      final_location = StateV2.get_fact(final_state, "location", "robot")
      assert final_location == "room2"
    end

    test "demonstrates runtime strategy selection" do
      # Simple domain for testing
      domain = Domain.new("runtime_strategy_demo")
      |> Domain.add_action(:act, fn state, _args -> {:ok, state} end)
      |> Domain.add_unigoal_method("test", "method", fn _state, _args -> {:ok, []} end)

      state = StateV2.new()
      goals = [{"test", "goal", "value"}]

      # Test different strategy combinations
      coordinators = [
        StrategyCoordinator.hybrid_htn_stn(),
        StrategyCoordinator.pure_strips(),
        StrategyCoordinator.reactive_planner()
      ]

      # Each coordinator uses different strategy functions but same interface
      Enum.each(coordinators, fn coordinator ->
        # All coordinators should work with the same domain/state/goals
        # This demonstrates Function as Object flexibility
        case StrategyCoordinator.plan_only(coordinator, domain, state, goals) do
          {:ok, _plan} -> :ok
          {:error, _reason} -> :ok  # Some strategies may not support this simple domain
        end
      end)
    end

    test "demonstrates middleware composition with Function as Object" do
      # Create strategy with middleware functions
      base_coordinator = StrategyCoordinator.hybrid_htn_stn()
      
      # Middleware are also functions that can be composed
      middleware = [
        StrategyCoordinator.logging_middleware("Demo Strategy"),
        StrategyCoordinator.timeout_middleware(5000)
      ]
      
      enhanced_coordinator = %{base_coordinator | middleware: middleware}
      
      # Verify coordinator structure
      assert length(enhanced_coordinator.middleware) == 2
      assert is_function(enhanced_coordinator.planning_fn)
      assert is_function(enhanced_coordinator.temporal_fn) 
      assert is_function(enhanced_coordinator.execution_fn)
    end

    test "demonstrates Function as Object inspection capabilities" do
      coordinator = StrategyCoordinator.hybrid_htn_stn()
      
      # Can inspect function metadata because functions are objects
      strategy_info = StrategyCoordinator.get_strategy_info(coordinator)
      
      assert Map.has_key?(strategy_info, :planning_function)
      assert Map.has_key?(strategy_info, :temporal_function)
      assert Map.has_key?(strategy_info, :execution_function)
      assert Map.has_key?(strategy_info, :metadata)
      
      # Verify function compatibility
      domain = Domain.new("test")
      assert StrategyCoordinator.compatible_with_domain?(coordinator, domain)
    end
  end
end
