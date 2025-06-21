#!/usr/bin/env elixir

# Call stack tracer for hybrid solver strategies
Mix.install([
  {:jason, "~> 1.4"},
  {:membrane_core, "~> 1.0"}
])

# Add the project lib path so we can use our modules
Code.append_path("lib")

# Configure Logger for detailed tracing
require Logger
Logger.configure(level: :debug)

# Compile necessary modules
files_to_compile = [
  "lib/aria_engine/mcp_tools_v2.ex",
  "lib/aria_engine/membrane/pipeline_manager.ex",
  "lib/aria_engine/membrane/planner_filter.ex",
  "lib/aria_engine/planner_adapter.ex",
  "lib/aria_engine/scheduler.ex",
  "lib/aria_engine/scheduler/core.ex",
  "lib/aria_engine/scheduler/domain_converter.ex",
  "lib/aria_engine/hybrid_planner/hybrid_coordinator_v2.ex",
  "lib/aria_engine/hybrid_planner/strategies/default/stn_temporal_strategy.ex",
  "lib/aria_engine/temporal_planner/stn_planner.ex",
  "lib/aria_engine/temporal_planner/stn_method.ex"
]

Enum.each(files_to_compile, fn file ->
  if File.exists?(file) do
    try do
      Code.compile_file(file)
      Logger.info("✅ Compiled #{file}")
    rescue
      error ->
        Logger.warning("⚠️  Failed to compile #{file}: #{inspect(error)}")
    end
  else
    Logger.warning("❌ File not found: #{file}")
  end
end)

defmodule CallStackTracer do
  @moduledoc """
  Traces the call stack during a solve operation to identify which hybrid solver strategies are used.
  """

  require Logger

  def trace_solve_operation() do
    Logger.info("=== CALL STACK TRACER FOR HYBRID SOLVER ===")
    
    # Enable process tracing
    :erlang.trace(:all, true, [:call, :return_to, :procs])
    
    # Set up tracing for key modules
    setup_tracing()
    
    # Execute a solve operation
    execute_traced_solve()
    
    # Disable tracing
    :erlang.trace(:all, false, [:call, :return_to, :procs])
    
    Logger.info("=== CALL STACK TRACE COMPLETE ===")
  end

  defp setup_tracing() do
    # Trace key modules in the solve chain
    modules_to_trace = [
      AriaEngine.MCPToolsV2,
      AriaEngine.Membrane.PlannerFilter,
      AriaEngine.PlannerAdapter,
      AriaEngine.Scheduler,
      AriaEngine.Scheduler.Core,
      AriaEngine.Scheduler.DomainConverter,
      AriaEngine.HybridPlanner.HybridCoordinatorV2,
      AriaEngine.HybridPlanner.Strategies.Default.STNTemporalStrategy,
      AriaEngine.TemporalPlanner.STNPlanner,
      AriaEngine.TemporalPlanner.STNMethod
    ]
    
    Enum.each(modules_to_trace, fn module ->
      try do
        # Trace all function calls in these modules
        :erlang.trace_pattern({module, :_, :_}, true, [:local])
        Logger.info("🔍 Tracing enabled for #{inspect(module)}")
      rescue
        error ->
        Logger.warning("⚠️  Could not trace #{inspect(module)}: #{inspect(error)}")
      end
    end)
  end

  defp execute_traced_solve() do
    Logger.info("\n🚀 EXECUTING TRACED SOLVE OPERATION")
    
    # Create a simple test case that should trigger the full solve chain
    test_request = %{
      "schedule_name" => "trace_test",
      "activities" => [
        %{
          "id" => "activity_1",
          "name" => "Test Activity",
          "duration" => %{
            "start" => "2025-06-21T09:00:00Z",
            "end" => "2025-06-21T10:00:00Z"
          },
          "participants" => ["alice"],
          "resources" => ["room_1"]
        }
      ],
      "entities" => [
        %{"id" => "alice", "type" => "person"}
      ],
      "resources" => %{
        "room_1" => %{"type" => "meeting_room", "capacity" => 4}
      },
      "constraints" => %{},
      "pipeline_topology" => "plan_transform_pipeline"
    }
    
    # Start collecting trace messages
    trace_collector_pid = spawn(fn -> collect_trace_messages([]) end)
    
    try do
      # Execute the solve operation
      Logger.info("📞 Calling MCPToolsV2.handle_tool_call...")
      result = AriaEngine.MCPToolsV2.handle_tool_call(:schedule_activities, test_request)
      Logger.info("✅ Solve operation completed: #{inspect(result)}")
      
      # Give trace collector time to process messages
      Process.sleep(1000)
      
      # Get collected traces
      send(trace_collector_pid, {:get_traces, self()})
      receive do
        {:traces, traces} ->
          analyze_call_stack(traces)
      after
        5000 ->
          Logger.warning("⚠️  Timeout waiting for trace collection")
      end
      
    rescue
      error ->
        Logger.error("❌ Error during traced solve: #{inspect(error)}")
        Logger.error("Stacktrace: #{Exception.format_stacktrace(__STACKTRACE__)}")
    end
  end

  defp collect_trace_messages(traces) do
    receive do
      {:trace, pid, :call, {module, function, args}} ->
        trace_entry = %{
          type: :call,
          pid: pid,
          module: module,
          function: function,
          arity: length(args),
          timestamp: :os.timestamp()
        }
        collect_trace_messages([trace_entry | traces])
        
      {:trace, pid, :return_to, {module, function, arity}} ->
        trace_entry = %{
          type: :return_to,
          pid: pid,
          module: module,
          function: function,
          arity: arity,
          timestamp: :os.timestamp()
        }
        collect_trace_messages([trace_entry | traces])
        
      {:get_traces, requester_pid} ->
        send(requester_pid, {:traces, Enum.reverse(traces)})
        
      other ->
        # Ignore other trace messages
        collect_trace_messages(traces)
    after
      10000 ->
        # Timeout after 10 seconds
        Logger.info("🔚 Trace collection timeout")
    end
  end

  defp analyze_call_stack(traces) do
    Logger.info("\n📊 CALL STACK ANALYSIS")
    Logger.info("Total trace entries: #{length(traces)}")
    
    # Group by module
    module_calls = traces
    |> Enum.filter(&(&1.type == :call))
    |> Enum.group_by(& &1.module)
    |> Enum.map(fn {module, calls} -> {module, length(calls)} end)
    |> Enum.sort_by(fn {_module, count} -> count end, :desc)
    
    Logger.info("\n🏗️  MODULE CALL FREQUENCY:")
    Enum.each(module_calls, fn {module, count} ->
      Logger.info("  #{inspect(module)}: #{count} calls")
    end)
    
    # Analyze strategy usage
    analyze_strategy_usage(traces)
    
    # Show call sequence for key modules
    show_key_call_sequence(traces)
    
    # Identify missing strategy calls
    identify_missing_strategies(traces)
  end

  defp analyze_strategy_usage(traces) do
    Logger.info("\n🧠 STRATEGY USAGE ANALYSIS:")
    
    strategy_modules = [
      AriaEngine.HybridPlanner.Strategies.Default.STNTemporalStrategy,
      AriaEngine.TemporalPlanner.STNPlanner,
      AriaEngine.TemporalPlanner.STNMethod
    ]
    
    strategy_calls = traces
    |> Enum.filter(&(&1.type == :call))
    |> Enum.filter(&(&1.module in strategy_modules))
    
    if Enum.empty?(strategy_calls) do
      Logger.warning("❌ NO STRATEGY CALLS DETECTED!")
      Logger.warning("   This indicates the hybrid solver strategies are not being invoked.")
    else
      Logger.info("✅ Strategy calls detected:")
      Enum.each(strategy_calls, fn call ->
        Logger.info("  #{inspect(call.module)}.#{call.function}/#{call.arity}")
      end)
    end
  end

  defp show_key_call_sequence(traces) do
    Logger.info("\n🔄 KEY CALL SEQUENCE:")
    
    key_modules = [
      AriaEngine.MCPToolsV2,
      AriaEngine.Membrane.PlannerFilter,
      AriaEngine.PlannerAdapter,
      AriaEngine.Scheduler,
      AriaEngine.Scheduler.Core,
      AriaEngine.HybridPlanner.HybridCoordinatorV2
    ]
    
    key_calls = traces
    |> Enum.filter(&(&1.type == :call))
    |> Enum.filter(&(&1.module in key_modules))
    |> Enum.take(20)  # Show first 20 key calls
    
    Enum.with_index(key_calls, 1)
    |> Enum.each(fn {call, index} ->
      Logger.info("  #{index}. #{inspect(call.module)}.#{call.function}/#{call.arity}")
    end)
  end

  defp identify_missing_strategies(traces) do
    Logger.info("\n🔍 MISSING STRATEGY ANALYSIS:")
    
    expected_strategies = [
      {AriaEngine.HybridPlanner.HybridCoordinatorV2, :solve},
      {AriaEngine.HybridPlanner.Strategies.Default.STNTemporalStrategy, :solve},
      {AriaEngine.TemporalPlanner.STNPlanner, :plan},
      {AriaEngine.TemporalPlanner.STNMethod, :solve_constraints}
    ]
    
    called_functions = traces
    |> Enum.filter(&(&1.type == :call))
    |> Enum.map(&({&1.module, &1.function}))
    |> MapSet.new()
    
    missing_strategies = expected_strategies
    |> Enum.reject(&MapSet.member?(called_functions, &1))
    
    if Enum.empty?(missing_strategies) do
      Logger.info("✅ All expected strategies were called")
    else
      Logger.warning("❌ MISSING STRATEGY CALLS:")
      Enum.each(missing_strategies, fn {module, function} ->
        Logger.warning("  #{inspect(module)}.#{function} - NOT CALLED")
      end)
    end
    
    # Check for broken call chain
    check_call_chain_integrity(traces)
  end

  defp check_call_chain_integrity(traces) do
    Logger.info("\n🔗 CALL CHAIN INTEGRITY CHECK:")
    
    # Expected call chain: MCP -> Membrane -> PlannerAdapter -> Scheduler -> HybridCoordinator -> Strategies
    expected_chain = [
      AriaEngine.MCPToolsV2,
      AriaEngine.Membrane.PlannerFilter,
      AriaEngine.PlannerAdapter,
      AriaEngine.Scheduler,
      AriaEngine.HybridPlanner.HybridCoordinatorV2,
      AriaEngine.HybridPlanner.Strategies.Default.STNTemporalStrategy
    ]
    
    called_modules = traces
    |> Enum.filter(&(&1.type == :call))
    |> Enum.map(& &1.module)
    |> Enum.uniq()
    
    chain_status = Enum.map(expected_chain, fn module ->
      called = module in called_modules
      {module, called}
    end)
    
    Enum.each(chain_status, fn {module, called} ->
      status = if called, do: "✅", else: "❌"
      Logger.info("  #{status} #{inspect(module)}")
    end)
    
    # Find where the chain breaks
    broken_at = chain_status
    |> Enum.with_index()
    |> Enum.find(fn {{_module, called}, _index} -> not called end)
    
    case broken_at do
      nil ->
        Logger.info("✅ Call chain is complete")
      {{module, false}, index} ->
        Logger.warning("❌ Call chain breaks at step #{index + 1}: #{inspect(module)}")
        Logger.warning("   This indicates the solve request is not reaching the hybrid strategies")
    end
  end
end

# Execute the trace
CallStackTracer.trace_solve_operation()
