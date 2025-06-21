#!/usr/bin/env elixir

# Direct solver call stack tracer - bypasses pipeline issues
Mix.install([{:jason, "~> 1.4"}])

# Add the project lib path
Code.append_path("lib")

# Configure Logger
require Logger
Logger.configure(level: :info)

defmodule DirectSolverTrace do
  @moduledoc """
  Directly traces solver calls without going through the problematic pipeline layer.
  """

  require Logger

  def trace_direct_solve() do
    Logger.info("=== DIRECT SOLVER CALL STACK TRACE ===")
    
    # Try to compile and test each component in the solver chain
    test_compilation_chain()
    test_direct_scheduler_call()
    test_planner_adapter_call()
    test_hybrid_coordinator_call()
    test_strategy_calls()
    
    Logger.info("=== DIRECT SOLVER TRACE COMPLETE ===")
  end

  defp test_compilation_chain() do
    Logger.info("\n🔧 TESTING COMPILATION CHAIN")
    
    modules_to_test = [
      {"StateV2", "lib/aria_engine/state_v2.ex"},
      {"Scheduler", "lib/aria_engine/scheduler.ex"},
      {"Scheduler.Core", "lib/aria_engine/scheduler/core.ex"},
      {"PlannerAdapter", "lib/aria_engine/planner_adapter.ex"},
      {"HybridCoordinatorV2", "lib/aria_engine/hybrid_planner/hybrid_coordinator_v2.ex"},
      {"STNTemporalStrategy", "lib/aria_engine/hybrid_planner/strategies/default/stn_temporal_strategy.ex"},
      {"STNPlanner", "lib/aria_engine/temporal_planner/stn_planner.ex"},
      {"STNMethod", "lib/aria_engine/temporal_planner/stn_method.ex"}
    ]
    
    Enum.each(modules_to_test, fn {name, file} ->
      if File.exists?(file) do
        try do
          Code.compile_file(file)
          Logger.info("✅ #{name} compiled successfully")
        rescue
          error ->
            Logger.error("❌ #{name} compilation failed: #{inspect(error)}")
        end
      else
        Logger.error("❌ #{name} file not found: #{file}")
      end
    end)
  end

  defp test_direct_scheduler_call() do
    Logger.info("\n📞 TESTING DIRECT SCHEDULER CALL")
    
    # Create test data
    activities = [
      %{
        "id" => "test_activity",
        "name" => "Test Activity",
        "duration" => %{
          "start" => "2025-06-21T09:00:00Z",
          "end" => "2025-06-21T10:00:00Z"
        },
        "participants" => ["alice"],
        "resources" => ["room_1"]
      }
    ]
    
    entities = [%{"id" => "alice", "type" => "person"}]
    resources = %{"room_1" => %{"type" => "meeting_room", "capacity" => 4}}
    
    try do
      # Test if AriaEngine.Scheduler module exists and has schedule_activities function
      if Code.ensure_loaded?(AriaEngine.Scheduler) do
        Logger.info("✅ AriaEngine.Scheduler module loaded")
        
        # Check if the function exists
        if function_exported?(AriaEngine.Scheduler, :schedule_activities, 3) do
          Logger.info("✅ schedule_activities/3 function exists")
          
          # Try to call it
          result = AriaEngine.Scheduler.schedule_activities("test_schedule", activities, [
            entities: entities,
            resources: resources,
            constraints: %{}
          ])
          
          Logger.info("✅ Scheduler call successful: #{inspect(result)}")
        else
          Logger.warning("⚠️  schedule_activities/3 function not exported")
          
          # List available functions
          functions = AriaEngine.Scheduler.__info__(:functions)
          Logger.info("Available functions: #{inspect(functions)}")
        end
      else
        Logger.error("❌ AriaEngine.Scheduler module not available")
      end
    rescue
      error ->
        Logger.error("❌ Scheduler call failed: #{inspect(error)}")
        Logger.error("Stacktrace: #{Exception.format_stacktrace(__STACKTRACE__)}")
    end
  end

  defp test_planner_adapter_call() do
    Logger.info("\n🎯 TESTING PLANNER ADAPTER CALL")
    
    try do
      if Code.ensure_loaded?(AriaEngine.PlannerAdapter) do
        Logger.info("✅ AriaEngine.PlannerAdapter module loaded")
        
        # Check available functions
        functions = AriaEngine.PlannerAdapter.__info__(:functions)
        Logger.info("Available functions: #{inspect(functions)}")
        
        if function_exported?(AriaEngine.PlannerAdapter, :plan_tasks, 4) do
          Logger.info("✅ plan_tasks/4 function exists")
          
          # We can't easily test this without proper domain/state setup
          Logger.info("⚠️  Would need proper domain and state setup to test")
        else
          Logger.warning("⚠️  plan_tasks/4 function not exported")
        end
      else
        Logger.error("❌ AriaEngine.PlannerAdapter module not available")
      end
    rescue
      error ->
        Logger.error("❌ PlannerAdapter test failed: #{inspect(error)}")
    end
  end

  defp test_hybrid_coordinator_call() do
    Logger.info("\n🧠 TESTING HYBRID COORDINATOR CALL")
    
    try do
      # Try different possible module names
      coordinator_modules = [
        AriaEngine.HybridPlanner.HybridCoordinatorV2,
        HybridPlanner.HybridCoordinatorV2,
        AriaEngine.HybridCoordinatorV2
      ]
      
      coordinator_found = Enum.find(coordinator_modules, fn module ->
        Code.ensure_loaded?(module)
      end)
      
      if coordinator_found do
        Logger.info("✅ Hybrid coordinator found: #{inspect(coordinator_found)}")
        
        # Check available functions
        functions = coordinator_found.__info__(:functions)
        Logger.info("Available functions: #{inspect(functions)}")
        
        # Look for solve/plan functions
        solve_functions = Enum.filter(functions, fn {name, _arity} ->
          name in [:solve, :plan, :coordinate]
        end)
        
        if Enum.empty?(solve_functions) do
          Logger.warning("⚠️  No solve/plan functions found")
        else
          Logger.info("✅ Solve functions found: #{inspect(solve_functions)}")
        end
      else
        Logger.error("❌ No hybrid coordinator module found")
      end
    rescue
      error ->
        Logger.error("❌ Hybrid coordinator test failed: #{inspect(error)}")
    end
  end

  defp test_strategy_calls() do
    Logger.info("\n⚡ TESTING STRATEGY CALLS")
    
    # Test STN Temporal Strategy
    test_stn_temporal_strategy()
    
    # Test STN Planner
    test_stn_planner()
    
    # Test STN Method
    test_stn_method()
  end

  defp test_stn_temporal_strategy() do
    Logger.info("\n🎯 Testing STN Temporal Strategy")
    
    try do
      strategy_modules = [
        AriaEngine.HybridPlanner.Strategies.Default.STNTemporalStrategy,
        HybridPlanner.Strategies.Default.STNTemporalStrategy
      ]
      
      strategy_found = Enum.find(strategy_modules, fn module ->
        Code.ensure_loaded?(module)
      end)
      
      if strategy_found do
        Logger.info("✅ STN Temporal Strategy found: #{inspect(strategy_found)}")
        
        functions = strategy_found.__info__(:functions)
        Logger.info("Available functions: #{inspect(functions)}")
        
        # Look for key strategy functions
        key_functions = Enum.filter(functions, fn {name, _arity} ->
          name in [:add_temporal_constraints, :validate_temporal_consistency, :update_constraints, :get_temporal_schedule]
        end)
        
        Logger.info("✅ Key strategy functions: #{inspect(key_functions)}")
      else
        Logger.error("❌ STN Temporal Strategy module not found")
      end
    rescue
      error ->
        Logger.error("❌ STN Temporal Strategy test failed: #{inspect(error)}")
    end
  end

  defp test_stn_planner() do
    Logger.info("\n📋 Testing STN Planner")
    
    try do
      planner_modules = [
        AriaEngine.TemporalPlanner.STNPlanner,
        TemporalPlanner.STNPlanner
      ]
      
      planner_found = Enum.find(planner_modules, fn module ->
        Code.ensure_loaded?(module)
      end)
      
      if planner_found do
        Logger.info("✅ STN Planner found: #{inspect(planner_found)}")
        
        functions = planner_found.__info__(:functions)
        Logger.info("Available functions: #{inspect(functions)}")
        
        # Look for planning functions
        plan_functions = Enum.filter(functions, fn {name, _arity} ->
          name in [:new, :plan, :solve, :consistent?]
        end)
        
        Logger.info("✅ Planning functions: #{inspect(plan_functions)}")
      else
        Logger.error("❌ STN Planner module not found")
      end
    rescue
      error ->
        Logger.error("❌ STN Planner test failed: #{inspect(error)}")
    end
  end

  defp test_stn_method() do
    Logger.info("\n🔧 Testing STN Method")
    
    try do
      method_modules = [
        AriaEngine.TemporalPlanner.STNMethod,
        TemporalPlanner.STNMethod
      ]
      
      method_found = Enum.find(method_modules, fn module ->
        Code.ensure_loaded?(module)
      end)
      
      if method_found do
        Logger.info("✅ STN Method found: #{inspect(method_found)}")
        
        functions = method_found.__info__(:functions)
        Logger.info("Available functions: #{inspect(functions)}")
        
        # Look for method functions
        method_functions = Enum.filter(functions, fn {name, _arity} ->
          name in [:solve_constraints, :chain, :parallel, :alternative, :can_execute?]
        end)
        
        Logger.info("✅ Method functions: #{inspect(method_functions)}")
      else
        Logger.error("❌ STN Method module not found")
      end
    rescue
      error ->
        Logger.error("❌ STN Method test failed: #{inspect(error)}")
    end
  end
end

# Run the direct solver trace
DirectSolverTrace.trace_direct_solve()
