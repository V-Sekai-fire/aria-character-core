# ADR-110: MCP Strategy Testing Interface for Hybrid Planner

**Status:** Proposed  
**Date:** June 20, 2025  
**Priority:** HIGH  

## Context

### Current MCP Tools Interface

The existing MCP tools provide a high-level `schedule_activities` interface that goes through the entire scheduler pipeline:

```
MCP Tool → Scheduler → HybridCoordinatorV2 → [All 6 Strategies] → Schedule
```

### Architectural Issue: Mixed Concerns

The current implementation mixes data transformation (MCP layer) with planning execution (domain layer), making it difficult to:
- Test data conversion separately from planning logic
- Execute individual strategies in isolation
- Reuse formatted data in different execution contexts
- Debug issues at the proper architectural layer

### Need for Individual Strategy Testing

To effectively develop and test existing strategies and prepare for future strategy additions, we need:

1. **Individual Strategy Testing**: Test each strategy in isolation
2. **Strategy Comparison**: Compare outputs between different strategies
3. **Development Workflow**: Rapid iteration on strategy implementations
4. **Debugging Capability**: Isolate issues to specific strategies
5. **Performance Benchmarking**: Measure individual strategy performance

## Decision

Rebuild the hybrid planner MCP interface using a **plan converter architecture** that provides individual strategy testing capabilities while maintaining clean separation of concerns.

### Plan Converter Architecture

Transform `schedule_activities` from a full execution pipeline into a pure data converter:

**Current Architecture (Mixed Concerns)**:
```
MCP Tool → validate → convert → AriaEngine.Scheduler → HybridCoordinatorV2 → [Strategies] → Result
```

**New Architecture (Clean Separation)**:
```
MCP Tool (plan converter) → HybridCoordinatorV2 input format
Domain Layer → HybridCoordinatorV2 → [Individual Strategies] → Result
```

### Benefits of Plan Converter Approach

1. **Pure Data Transformation**: MCP tools become pure functions that only format data
2. **Cleaner Testing**: Can test data conversion separately from planning execution
3. **Better Separation**: MCP layer handles format conversion, domain layer handles planning
4. **Reusability**: Formatted data can be used by different execution contexts
5. **Individual Strategy Testing**: Enables direct testing of strategies in isolation

### Dual Interface Design

- **High-level interface**: `schedule_activities` as plan converter for production use
- **Low-level interface**: Individual strategy testing tools for development and debugging
- **Unified data format**: Both interfaces use the same HybridCoordinatorV2 input format

## Cold Boot Implementation Order

### Boot Level 1: Foundation Types and Contracts

**File**: `lib/aria_engine/hybrid_planner/strategy_types.ex`

```elixir
defmodule AriaEngine.HybridPlanner.StrategyTypes do
  @moduledoc """
  Core type definitions for strategy testing interface.
  """

  @type problem_type :: :planning | :temporal | :optimization | :constraint_satisfaction

  @type strategy_input :: %{
    problem_type: problem_type(),
    domain: AriaEngine.Domain.Core.t(),
    state: AriaEngine.StateV2.t(),
    goals: [term()],
    constraints: map(),
    options: keyword()
  }

  @type performance_metrics :: %{
    execution_time_ms: non_neg_integer(),
    memory_usage_bytes: non_neg_integer(),
    iterations: non_neg_integer(),
    cpu_time_ms: non_neg_integer()
  }

  @type strategy_metadata :: %{
    strategy_name: String.t(),
    strategy_version: String.t(),
    problem_characteristics: map(),
    capabilities: [atom()]
  }

  @type strategy_result :: %{
    status: :success | :failure | :error,
    result: term(),
    performance: performance_metrics(),
    metadata: strategy_metadata(),
    error_details: String.t() | nil
  }

  @type strategy_module :: module()
  @type strategy_name :: atom()
end
```

**File**: `lib/aria_engine/hybrid_planner/strategy_behaviour.ex`

```elixir
defmodule AriaEngine.HybridPlanner.StrategyBehaviour do
  @moduledoc """
  Behaviour that all testable strategies must implement.
  """

  alias AriaEngine.HybridPlanner.StrategyTypes

  @callback execute(StrategyTypes.strategy_input()) :: StrategyTypes.strategy_result()
  @callback strategy_info() :: StrategyTypes.strategy_metadata()
  @callback validate_input(StrategyTypes.strategy_input()) :: {:ok, StrategyTypes.strategy_input()} | {:error, String.t()}
end
```

### Boot Level 2: Strategy Isolation Infrastructure

**File**: `lib/aria_engine/hybrid_planner/strategy_isolation.ex`

```elixir
defmodule AriaEngine.HybridPlanner.StrategyIsolation do
  @moduledoc """
  Infrastructure for executing strategies in isolation with resource limits.
  """

  alias AriaEngine.HybridPlanner.StrategyTypes

  @type isolation_options :: [
    timeout_ms: non_neg_integer(),
    memory_limit_mb: non_neg_integer(),
    capture_logs: boolean()
  ]

  @spec execute_isolated(StrategyTypes.strategy_module(), StrategyTypes.strategy_input(), isolation_options()) :: 
    StrategyTypes.strategy_result()
  def execute_isolated(strategy_module, input, opts \\ []) do
    # Implementation details
  end

  @spec setup_isolation_environment(StrategyTypes.strategy_module(), isolation_options()) :: 
    {:ok, pid()} | {:error, String.t()}
  def setup_isolation_environment(strategy_module, opts) do
    # Implementation details
  end

  @spec cleanup_isolation_environment(pid()) :: :ok
  def cleanup_isolation_environment(isolation_pid) do
    # Implementation details
  end

  @spec measure_performance(fun()) :: {term(), StrategyTypes.performance_metrics()}
  def measure_performance(execution_fun) do
    # Implementation details
  end
end
```

### Boot Level 3: Individual Strategy Wrappers

**File**: `lib/aria_engine/hybrid_planner/strategy_wrappers/planning_strategy_wrapper.ex`

```elixir
defmodule AriaEngine.HybridPlanner.StrategyWrappers.PlanningStrategyWrapper do
  @moduledoc """
  Wrapper for testing HTN planning strategy in isolation.
  """

  alias AriaEngine.HybridPlanner.{StrategyTypes, StrategyIsolation}

  @behaviour AriaEngine.HybridPlanner.StrategyBehaviour

  @spec test_strategy(
    AriaEngine.Domain.Core.t(),
    AriaEngine.StateV2.t(),
    [term()],
    keyword()
  ) :: StrategyTypes.strategy_result()
  def test_strategy(domain, state, goals, opts \\ []) do
    input = %{
      problem_type: :planning,
      domain: domain,
      state: state,
      goals: goals,
      constraints: %{},
      options: opts
    }
    
    StrategyIsolation.execute_isolated(__MODULE__, input, opts)
  end

  @impl true
  @spec execute(StrategyTypes.strategy_input()) :: StrategyTypes.strategy_result()
  def execute(input) do
    # Implementation details
  end

  @impl true
  @spec strategy_info() :: StrategyTypes.strategy_metadata()
  def strategy_info() do
    %{
      strategy_name: "HTNPlanningStrategy",
      strategy_version: "1.0.0",
      problem_characteristics: %{
        supports_hierarchical: true,
        supports_temporal: false,
        supports_optimization: false
      },
      capabilities: [:planning, :hierarchical_decomposition]
    }
  end

  @impl true
  @spec validate_input(StrategyTypes.strategy_input()) :: 
    {:ok, StrategyTypes.strategy_input()} | {:error, String.t()}
  def validate_input(input) do
    # Implementation details
  end
end
```

**File**: `lib/aria_engine/hybrid_planner/strategy_wrappers/temporal_strategy_wrapper.ex`

```elixir
defmodule AriaEngine.HybridPlanner.StrategyWrappers.TemporalStrategyWrapper do
  @moduledoc """
  Wrapper for testing STN temporal strategy in isolation.
  """

  alias AriaEngine.HybridPlanner.{StrategyTypes, StrategyIsolation}

  @behaviour AriaEngine.HybridPlanner.StrategyBehaviour

  @spec test_strategy(
    AriaEngine.Timeline.t(),
    AriaEngine.StateV2.t(),
    [term()],
    keyword()
  ) :: StrategyTypes.strategy_result()
  def test_strategy(timeline, state, constraints, opts \\ []) do
    input = %{
      problem_type: :temporal,
      domain: nil,
      state: state,
      goals: constraints,
      constraints: %{timeline: timeline},
      options: opts
    }
    
    StrategyIsolation.execute_isolated(__MODULE__, input, opts)
  end

  @impl true
  @spec execute(StrategyTypes.strategy_input()) :: StrategyTypes.strategy_result()
  def execute(input) do
    # Implementation details
  end

  @impl true
  @spec strategy_info() :: StrategyTypes.strategy_metadata()
  def strategy_info() do
    %{
      strategy_name: "STNTemporalStrategy",
      strategy_version: "1.0.0",
      problem_characteristics: %{
        supports_hierarchical: false,
        supports_temporal: true,
        supports_optimization: false
      },
      capabilities: [:temporal_reasoning, :constraint_propagation]
    }
  end

  @impl true
  @spec validate_input(StrategyTypes.strategy_input()) :: 
    {:ok, StrategyTypes.strategy_input()} | {:error, String.t()}
  def validate_input(input) do
    # Implementation details
  end
end
```

**Note**: Additional strategy wrappers (such as StateV2, Domain, and Execution strategies) will be added as Boot Level 3 expands. ExhortStrategy wrapper will be implemented after the foundational system is complete.

### Boot Level 4: Plan Converter and MCP Tool Handlers

**File**: `lib/aria_engine/hybrid_planner/plan_converter.ex`

```elixir
defmodule AriaEngine.HybridPlanner.PlanConverter do
  @moduledoc """
  Pure data converter that transforms MCP input format to HybridCoordinatorV2 input format.
  """

  @type mcp_input :: map()
  @type coordinator_input :: map()
  @type conversion_result :: {:ok, coordinator_input()} | {:error, String.t()}

  @spec convert_to_coordinator_input(mcp_input()) :: conversion_result()
  def convert_to_coordinator_input(params) do
    try do
      case validate_mcp_params(params) do
        {:ok, validated_params} ->
          coordinator_input = %{
            schedule_name: validated_params["schedule_name"],
            activities: convert_activities(validated_params["activities"]),
            entities: convert_entities(validated_params["entities"] || []),
            resources: validated_params["resources"] || %{},
            constraints: validated_params["constraints"] || %{},
            options: extract_options(validated_params)
          }
          {:ok, coordinator_input}
        {:error, reason} ->
          {:error, reason}
      end
    rescue
      e -> {:error, "Conversion error: #{Exception.message(e)}"}
    end
  end

  @spec validate_mcp_params(map()) :: {:ok, map()} | {:error, String.t()}
  defp validate_mcp_params(params) do
    # Reuse existing validation logic from MCPTools
    cond do
      not Map.has_key?(params, "schedule_name") ->
        {:error, "schedule_name is required"}
      not is_binary(params["schedule_name"]) ->
        {:error, "schedule_name must be a string"}
      not Map.has_key?(params, "activities") ->
        {:error, "activities is required"}
      not is_list(params["activities"]) ->
        {:error, "activities must be a list"}
      true ->
        {:ok, params}
    end
  end

  # Reuse existing conversion functions from MCPTools
  defp convert_activities(activities), do: activities  # Implementation details
  defp convert_entities(entities), do: entities        # Implementation details
  defp extract_options(params), do: []                 # Implementation details
end
```

**File**: `lib/aria_engine/mcp_tools.ex` (updated)

```elixir
defmodule AriaEngine.MCPTools do
  # ... existing code ...

  alias AriaEngine.HybridPlanner.{
    PlanConverter,
    StrategyWrappers.PlanningStrategyWrapper,
    StrategyWrappers.TemporalStrategyWrapper
  }

  @tools [
    {:schedule_activities, "1.0.0"},
    {:test_planning_strategy, "1.0.0"},
    {:test_temporal_strategy, "1.0.0"}
  ]

  # Updated schedule_activities as pure plan converter
  def handle_tool_call(:schedule_activities, params) do
    case PlanConverter.convert_to_coordinator_input(params) do
      {:ok, coordinator_input} ->
        %{
          "status" => "success",
          "coordinator_input" => coordinator_input,
          "conversion_metadata" => %{
            "original_activities" => length(params["activities"] || []),
            "converted_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
            "input_format" => "mcp_schedule_activities",
            "output_format" => "hybrid_coordinator_v2"
          }
        }
      {:error, reason} ->
        %{
          "status" => "error",
          "reason" => reason,
          "coordinator_input" => nil
        }
    end
  end

  @spec handle_tool_call(atom(), map()) :: map()
  def handle_tool_call(:test_planning_strategy, params) do
    domain = parse_domain(params["domain"])
    state = parse_state(params["state"])
    goals = params["goals"] || []
    options = params["options"] || []

    case PlanningStrategyWrapper.test_strategy(domain, state, goals, options) do
      %{status: :success} = result -> format_success_response(result)
      %{status: :failure} = result -> format_failure_response(result)
      %{status: :error} = result -> format_error_response(result)
    end
  end

  def handle_tool_call(:test_temporal_strategy, params) do
    timeline = parse_timeline(params["timeline"])
    state = parse_state(params["state"])
    constraints = params["constraints"] || []
    options = params["options"] || []

    case TemporalStrategyWrapper.test_strategy(timeline, state, constraints, options) do
      %{status: :success} = result -> format_success_response(result)
      %{status: :failure} = result -> format_failure_response(result)
      %{status: :error} = result -> format_error_response(result)
    end
  end


  @spec format_success_response(StrategyTypes.strategy_result()) :: map()
  defp format_success_response(result) do
    %{
      "status" => "success",
      "result" => result.result,
      "performance" => %{
        "execution_time_ms" => result.performance.execution_time_ms,
        "memory_usage_bytes" => result.performance.memory_usage_bytes,
        "iterations" => result.performance.iterations
      },
      "metadata" => %{
        "strategy_name" => result.metadata.strategy_name,
        "strategy_version" => result.metadata.strategy_version,
        "capabilities" => result.metadata.capabilities
      }
    }
  end

  @spec format_failure_response(StrategyTypes.strategy_result()) :: map()
  defp format_failure_response(result) do
    %{
      "status" => "failure",
      "error" => result.error_details,
      "performance" => %{
        "execution_time_ms" => result.performance.execution_time_ms
      },
      "metadata" => %{
        "strategy_name" => result.metadata.strategy_name
      }
    }
  end

  @spec format_error_response(StrategyTypes.strategy_result()) :: map()
  defp format_error_response(result) do
    %{
      "status" => "error",
      "error" => result.error_details,
      "metadata" => %{
        "strategy_name" => result.metadata.strategy_name
      }
    }
  end
end
```

### Boot Level 5: Multi-Strategy Execution Framework

**File**: `lib/aria_engine/hybrid_planner/multi_strategy_executor.ex`

```elixir
defmodule AriaEngine.HybridPlanner.MultiStrategyExecutor do
  @moduledoc """
  Framework for executing multiple strategies in parallel and aggregating results.
  """

  alias AriaEngine.HybridPlanner.StrategyTypes

  @type execution_options :: [
    parallel: boolean(),
    timeout_ms: non_neg_integer(),
    max_concurrent: pos_integer()
  ]

  @type aggregated_results :: %{
    strategy_results: [StrategyTypes.strategy_result()],
    execution_summary: map(),
    timing_info: map()
  }

  @spec execute_strategies(
    StrategyTypes.strategy_input(),
    [StrategyTypes.strategy_module()],
    execution_options()
  ) :: aggregated_results()
  def execute_strategies(problem, strategy_list, opts \\ []) do
    parallel = Keyword.get(opts, :parallel, true)
    
    if parallel do
      execute_parallel(problem, strategy_list, opts)
    else
      execute_sequential(problem, strategy_list, opts)
    end
  end

  @spec execute_parallel(
    StrategyTypes.strategy_input(),
    [StrategyTypes.strategy_module()],
    execution_options()
  ) :: aggregated_results()
  defp execute_parallel(problem, strategy_list, opts) do
    max_concurrent = Keyword.get(opts, :max_concurrent, System.schedulers_online())
    timeout_ms = Keyword.get(opts, :timeout_ms, 30_000)

    tasks = strategy_list
    |> Enum.map(fn strategy_module ->
      Task.async(fn ->
        strategy_module.execute(problem)
      end)
    end)

    results = Task.await_many(tasks, timeout_ms)
    
    %{
      strategy_results: results,
      execution_summary: summarize_execution(results),
      timing_info: %{
        total_execution_time_ms: calculate_total_time(results),
        parallel_execution: true
      }
    }
  end

  @spec execute_sequential(
    StrategyTypes.strategy_input(),
    [StrategyTypes.strategy_module()],
    execution_options()
  ) :: aggregated_results()
  defp execute_sequential(problem, strategy_list, _opts) do
    start_time = System.monotonic_time(:millisecond)
    
    results = Enum.map(strategy_list, fn strategy_module ->
      strategy_module.execute(problem)
    end)
    
    end_time = System.monotonic_time(:millisecond)
    
    %{
      strategy_results: results,
      execution_summary: summarize_execution(results),
      timing_info: %{
        total_execution_time_ms: end_time - start_time,
        parallel_execution: false
      }
    }
  end

  @spec summarize_execution([StrategyTypes.strategy_result()]) :: map()
  defp summarize_execution(results) do
    success_count = Enum.count(results, &(&1.status == :success))
    failure_count = Enum.count(results, &(&1.status == :failure))
    error_count = Enum.count(results, &(&1.status == :error))
    
    %{
      total_strategies: length(results),
      success_count: success_count,
      failure_count: failure_count,
      error_count: error_count,
      success_rate: success_count / length(results)
    }
  end

  @spec calculate_total_time([StrategyTypes.strategy_result()]) :: non_neg_integer()
  defp calculate_total_time(results) do
    results
    |> Enum.map(& &1.performance.execution_time_ms)
    |> Enum.max(fn -> 0 end)
  end
end
```

### Boot Level 6: Strategy Comparison and Analysis

**File**: `lib/aria_engine/hybrid_planner/strategy_comparison.ex`

```elixir
defmodule AriaEngine.HybridPlanner.StrategyComparison do
  @moduledoc """
  Framework for comparing strategy outputs and performance.
  """

  alias AriaEngine.HybridPlanner.{StrategyTypes, MultiStrategyExecutor}

  @type comparison_metrics :: [
    :execution_time | :memory_usage | :solution_quality | :success_rate
  ]

  @type comparison_result :: %{
    problem_summary: map(),
    strategy_results: [StrategyTypes.strategy_result()],
    comparison: %{
      performance_ranking: [map()],
      solution_quality: map(),
      statistical_analysis: map()
    }
  }

  @spec compare_strategies(
    StrategyTypes.strategy_input(),
    [StrategyTypes.strategy_module()],
    comparison_metrics()
  ) :: comparison_result()
  def compare_strategies(problem, strategy_list, metrics) do
    aggregated = MultiStrategyExecutor.execute_strategies(problem, strategy_list)
    
    %{
      problem_summary: summarize_problem(problem),
      strategy_results: aggregated.strategy_results,
      comparison: %{
        performance_ranking: rank_by_performance(aggregated.strategy_results, metrics),
        solution_quality: compare_solution_quality(aggregated.strategy_results),
        statistical_analysis: analyze_statistics(aggregated.strategy_results)
      }
    }
  end

  @spec rank_by_performance([StrategyTypes.strategy_result()], comparison_metrics()) :: [map()]
  def rank_by_performance(results, metrics) do
    results
    |> Enum.map(&extract_performance_data(&1, metrics))
    |> Enum.sort_by(&calculate_composite_score(&1, metrics))
    |> Enum.with_index(1)
    |> Enum.map(fn {strategy_data, rank} ->
      Map.put(strategy_data, :rank, rank)
    end)
  end

  @spec compare_solution_quality([StrategyTypes.strategy_result()]) :: map()
  def compare_solution_quality(results) do
    successful_results = Enum.filter(results, &(&1.status == :success))
    
    %{
      total_solutions: length(successful_results),
      unique_solutions: count_unique_solutions(successful_results),
      solution_diversity: calculate_solution_diversity(successful_results),
      optimal_solutions: identify_optimal_solutions(successful_results)
    }
  end

  @spec analyze_statistics([StrategyTypes.strategy_result()]) :: map()
  def analyze_statistics(results) do
    execution_times = Enum.map(results, & &1.performance.execution_time_ms)
    memory_usage = Enum.map(results, & &1.performance.memory_usage_bytes)
    
    %{
      execution_time_stats: calculate_stats(execution_times),
      memory_usage_stats: calculate_stats(memory_usage),
      success_rate: calculate_success_rate(results),
      performance_variance: calculate_performance_variance(results)
    }
  end

  @spec extract_performance_data(StrategyTypes.strategy_result(), comparison_metrics()) :: map()
  defp extract_performance_data(result, metrics) do
    base_data = %{
      strategy_name: result.metadata.strategy_name,
      status: result.status
    }
    
    Enum.reduce(metrics, base_data, fn metric, acc ->
      case metric do
        :execution_time -> Map.put(acc, :execution_time_ms, result.performance.execution_time_ms)
        :memory_usage -> Map.put(acc, :memory_usage_bytes, result.performance.memory_usage_bytes)
        :solution_quality -> Map.put(acc, :solution_quality, assess_solution_quality(result))
        :success_rate -> Map.put(acc, :success, result.status == :success)
      end
    end)
  end

  @spec calculate_composite_score(map(), comparison_metrics()) :: float()
  defp calculate_composite_score(strategy_data, metrics) do
    # Implementation details for composite scoring
    0.0
  end

  @spec summarize_problem(StrategyTypes.strategy_input()) :: map()
  defp summarize_problem(problem) do
    %{
      problem_type: problem.problem_type,
      goal_count: length(problem.goals),
      constraint_count: map_size(problem.constraints),
      complexity_estimate: estimate_complexity(problem)
    }
  end

  @spec calculate_stats([number()]) :: map()
  defp calculate_stats(values) do
    sorted = Enum.sort(values)
    count = length(values)
    
    %{
      min: Enum.min(values),
      max: Enum.max(values),
      mean: Enum.sum(values) / count,
      median: Enum.at(sorted, div(count, 2)),
      std_dev: calculate_standard_deviation(values)
    }
  end

  # Additional helper functions...
  defp count_unique_solutions(_results), do: 0
  defp calculate_solution_diversity(_results), do: 0.0
  defp identify_optimal_solutions(_results), do: []
  defp calculate_success_rate(_results), do: 0.0
  defp calculate_performance_variance(_results), do: 0.0
  defp assess_solution_quality(_result), do: 0.0
  defp estimate_complexity(_problem), do: :medium
  defp calculate_standard_deviation(_values), do: 0.0
end
```

### Boot Level 7: Advanced MCP Tools

**File**: `lib/aria_engine/mcp_tools.ex` (additional tools)

```elixir
defmodule AriaEngine.MCPTools do
  # ... existing code ...

  alias AriaEngine.HybridPlanner.{StrategyComparison, MultiStrategyExecutor}

  @tools [
    # ... existing tools ...
    {:compare_strategies, "1.0.0"},
    {:benchmark_strategies, "1.0.0"},
    {:analyze_strategy_performance, "1.0.0"}
  ]

  def handle_tool_call(:compare_strategies, params) do
    problem = parse_strategy_input(params["problem"])
    strategy_names = params["strategies"] || []
    metrics = parse_comparison_metrics(params["comparison_metrics"])
    
    strategy_modules = resolve_strategy_modules(strategy_names)
    
    case StrategyComparison.compare_strategies(problem, strategy_modules, metrics) do
      comparison_result -> format_comparison_response(comparison_result)
    end
  end

  def handle_tool_call(:benchmark_strategies, params) do
    problem_set = parse_problem_set(params["problem_set"])
    strategy_names = params["strategies"] || []
    benchmark_options = params["benchmark_options"] || []
    
    strategy_modules = resolve_strategy_modules(strategy_names)
    
    benchmark_results = run_benchmark_suite(problem_set, strategy_modules, benchmark_options)
    format_benchmark_response(benchmark_results)
  end

  def handle_tool_call(:analyze_strategy_performance, params) do
    strategy_name = params["strategy_name"]
    performance_data = params["performance_data"]
    analysis_options = params["analysis_options"] || []
    
    analysis_result = analyze_performance_data(strategy_name, performance_data, analysis_options)
    format_analysis_response(analysis_result)
  end

  @spec resolve_strategy_modules([String.t()]) :: [StrategyTypes.strategy_module()]
  defp resolve_strategy_modules(strategy_names) do
    strategy_map = %{
      "planning" => PlanningStrategyWrapper,
      "temporal" => TemporalStrategyWrapper
    }
    
    Enum.map(strategy_names, &Map.get(strategy_map, &1))
    |> Enum.reject(&is_nil/1)
  end

  @spec parse_strategy_input(map()) :: StrategyTypes.strategy_input()
  defp parse_strategy_input(params) do
    %{
      problem_type: String.to_atom(params["problem_type"]),
      domain: parse_domain(params["domain"]),
      state: parse_state(params["state"]),
      goals: params["goals"] || [],
      constraints: params["constraints"] || %{},
      options: params["options"] || []
    }
  end

  @spec parse_comparison_metrics([String.t()]) :: [atom()]
  defp parse_comparison_metrics(metric_strings) do
    Enum.map(metric_strings, &String.to_atom/1)
  end

  @spec format_comparison_response(StrategyComparison.comparison_result()) :: map()
  defp format_comparison_response(comparison_result) do
    %{
      "status" => "success",
      "problem_summary" => comparison_result.problem_summary,
      "strategy_count" => length(comparison_result.strategy_results),
      "performance_ranking" => comparison_result.comparison.performance_ranking,
      "solution_quality" => comparison_result.comparison.solution_quality,
      "statistical_analysis" => comparison_result.comparison.statistical_analysis
    }
  end

  # Additional helper functions...
  defp parse_problem_set(_params), do: []
  defp run_benchmark_suite(_problem_set, _strategies, _options), do: %{}
  defp format_benchmark_response(_results), do: %{}
  defp analyze_performance_data(_strategy, _data, _options), do: %{}
  defp format_analysis_response(_result), do: %{}
end
```

### Boot Level 8: Integration Testing

**File**: `test/aria_engine/hybrid_planner/strategy_testing_integration_test.exs`

```elixir
defmodule AriaEngine.HybridPlanner.StrategyTestingIntegrationTest do
  use ExUnit.Case, async: true

  alias AriaEngine.HybridPlanner.{
    StrategyTypes,
    StrategyWrappers.PlanningStrategyWrapper,
    MultiStrategyExecutor,
    StrategyComparison
  }
  alias AriaEngine.MCPTools

  describe "Boot Level 1: Foundation Types" do
    test "strategy input type validation" do
      input = %{
        problem_type: :planning,
        domain: %AriaEngine.Domain.Core{},
        state: %AriaEngine.StateV2{},
        goals: [:goal1, :goal2],
        constraints: %{},
        options: []
      }
      
      assert %StrategyTypes{} = struct(StrategyTypes, %{})
      assert is_map(input)
      assert input.problem_type in [:planning, :temporal, :optimization, :constraint_satisfaction]
    end
  end

  describe "Boot Level 2: Strategy Isolation" do
    test "strategy can execute in isolation" do
      input = build_test_input(:planning)
      
      result = PlanningStrategyWrapper.test_strategy(
        input.domain,
        input.state,
        input.goals,
        input.options
      )
      
      assert %{status: status} = result
      assert status in [:success, :failure, :error]
      assert is_map(result.performance)
      assert is_map(result.metadata)
    end
  end

  describe "Boot Level 3: Strategy Wrappers" do
    test "all strategy wrappers implement behaviour" do
      wrappers = [
        PlanningStrategyWrapper,
        # Add other wrappers as they're implemented
      ]
      
      Enum.each(wrappers, fn wrapper ->
        assert function_exported?(wrapper, :execute, 1)
        assert function_exported?(wrapper, :strategy_info, 0)
        assert function_exported?(wrapper, :validate_input, 1)
      end)
    end
  end

  describe "Boot Level 4: MCP Tool Integration" do
    test "MCP tools can call strategy wrappers" do
      params = %{
        "domain" => build_test_domain(),
        "state" => build_test_state(),
        "goals" => ["goal1", "goal2"],
        "options" => []
      }
      
      result = MCPTools.handle_tool_call(:test_planning_strategy, params)
      
      assert is_map(result)
      assert Map.has_key?(result, "status")
      assert result["status"] in ["success", "failure", "error"]
    end
  end

  describe "Boot Level 5: Multi-Strategy Execution" do
    test "multiple strategies can execute together" do
      problem = build_test_input(:planning)
      strategies = [PlanningStrategyWrapper]
      
      result = MultiStrategyExecutor.execute_strategies(problem, strategies)
      
      assert %{strategy_results: results} = result
      assert is_list(results)
      assert length(results) == length(strategies)
    end
  end

  describe "Boot Level 6: Strategy Comparison" do
    test "strategies can be compared" do
      problem = build_test_input(:planning)
      strategies = [PlanningStrategyWrapper]
      metrics = [:execution_time, :memory_usage]
      
      result = StrategyComparison.compare_strategies(problem, strategies, metrics)
      
      assert %{comparison: comparison} = result
      assert Map.has_key?(comparison, :performance_ranking)
      assert Map.has_key?(comparison, :solution_quality)
    end
  end

  describe "Boot Level 7: Advanced MCP Tools" do
    test "strategy comparison via MCP tools" do
      params = %{
        "problem" => build_test_problem_params(),
        "strategies" => ["planning"],
        "comparison_metrics" => ["execution_time", "memory_usage"]
      }
      
      result = MCPTools.handle_tool_call(:compare_strategies, params)
      
      assert is_map(result)
      assert result["status"] == "success"
      assert Map.has_key?(result, "performance_ranking")
    end
  end

  describe "Boot Level 8: Complete Integration" do
    test "end-to-end strategy testing workflow" do
      # Test complete workflow from MCP tool to strategy execution
      params = %{
        "domain" => build_test_domain(),
        "state" => build_test_state(),
        "goals" => ["goal1"],
        "options" => []
      }
      
      # Individual strategy test
      individual_result = MCPTools.handle_tool_call(:test_planning_strategy, params)
      assert individual_result["status"] in ["success", "failure", "error"]
      
      # Strategy comparison
      comparison_params = %{
        "problem" => build_test_problem_params(),
        "strategies" => ["planning"],
        "comparison_metrics" => ["execution_time"]
      }
      
      comparison_result = MCPTools.handle_tool_call(:compare_strategies, comparison_params)
      assert comparison_result["status"] == "success"
    end
  end

  # Helper functions for tests
  @spec build_test_input(StrategyTypes.problem_type()) :: StrategyTypes.strategy_input()
  defp build_test_input(problem_type) do
    %{
      problem_type: problem_type,
      domain: build_test_domain(),
      state: build_test_state(),
      goals: [:test_goal],
      constraints: %{},
      options: []
    }
  end

  @spec build_test_domain() :: map()
  defp build_test_domain() do
    %{
      "name" => "test_domain",
      "actions" => [],
      "predicates" => []
    }
  end

  @spec build_test_state() :: map()
  defp build_test_state() do
    %{
      "facts" => [],
      "timestamp" => DateTime.utc_now()
    }
  end

  @spec build_test_problem_params() :: map()
  defp build_test_problem_params() do
    %{
      "problem_type" => "planning",
      "domain" => build_test_domain(),
      "state" => build_test_state(),
      "goals" => ["test_goal"],
      "constraints" => %{},
      "options" => []
    }
  end
end
```

## Implementation Summary

This ADR defines a complete cold boot implementation order for the MCP Strategy Testing Interface with concrete Elixir methods and typespecs:

### Boot Level Dependencies

1. **Boot Level 1**: Foundation types and behaviour contracts
2. **Boot Level 2**: Strategy isolation infrastructure with resource limits
3. **Boot Level 3**: Individual strategy wrappers implementing the behaviour
4. **Boot Level 4**: MCP tool registration and handlers
5. **Boot Level 5**: Multi-strategy execution framework
6. **Boot Level 6**: Strategy comparison and analysis
7. **Boot Level 7**: Advanced MCP tools for benchmarking
8. **Boot Level 8**: Complete integration testing

### Key Function Signatures

**Strategy Testing Interface**:
```elixir
@spec test_strategy(domain, state, goals, opts) :: StrategyTypes.strategy_result()
@spec execute(StrategyTypes.strategy_input()) :: StrategyTypes.strategy_result()
@spec strategy_info() :: StrategyTypes.strategy_metadata()
```

**MCP Tool Handlers**:
```elixir
@spec handle_tool_call(atom(), map()) :: map()
```

**Multi-Strategy Execution**:
```elixir
@spec execute_strategies(problem, strategy_list, opts) :: aggregated_results()
@spec compare_strategies(problem, strategy_list, metrics) :: comparison_result()
```

### Type Definitions

All core types are defined in `StrategyTypes` module with proper typespecs for:
- `strategy_input()` - Standardized input format
- `strategy_result()` - Standardized output format  
- `performance_metrics()` - Performance measurement data
- `strategy_metadata()` - Strategy capability information

This provides a clear, implementable roadmap with concrete function signatures and type contracts for building the MCP Strategy Testing Interface.

## Success Criteria

Each boot level has specific success criteria that must be met before proceeding to the next level, ensuring a solid foundation for the complete strategy testing system.

## Related ADRs

- **ADR-111**: Schedule Activities Data Transformer Conversion (aligned architecture)
- **ADR-105**: Reconnect Scheduler to MCP (superseded by plan converter approach)
- **ADR-097**: MCP Scheduler Interface Design (superseded by plan converter approach)
- **ADR-109**: Integrate CP-SAT Solver Strategy via Exhort OR-Tools
- **ADR-091**: Hybrid Planner Dependency Encapsulation  
- **ADR-101**: Reconnect Scheduler with Hybrid Planner
