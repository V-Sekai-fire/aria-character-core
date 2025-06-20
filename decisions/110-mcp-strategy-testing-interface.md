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

### Need for Individual Strategy Testing

To effectively develop and test the new ExhortStrategy (ADR-109) and other strategies, we need:

1. **Individual Strategy Testing**: Test each strategy in isolation
2. **Strategy Comparison**: Compare outputs between different strategies
3. **Development Workflow**: Rapid iteration on strategy implementations
4. **Debugging Capability**: Isolate issues to specific strategies
5. **Performance Benchmarking**: Measure individual strategy performance

### Current Limitations

- **No Direct Strategy Access**: Cannot test strategies individually through MCP
- **Complex Pipeline**: Full scheduler pipeline obscures strategy-specific issues
- **Limited Debugging**: Hard to isolate problems to specific strategies
- **No Strategy Comparison**: Cannot easily compare strategy outputs

## Decision

Rebuild the hybrid planner MCP interface to provide individual strategy testing capabilities while maintaining the existing high-level interface for production use.

## Implementation Plan

### Phase 1: Strategy-Level MCP Tools (HIGH PRIORITY)

**File**: `lib/aria_engine/mcp_tools.ex`

**New MCP Tools to Add**:
- [ ] `test_planning_strategy` - Test HTN planning strategy directly
- [ ] `test_temporal_strategy` - Test STN temporal strategy directly  
- [ ] `test_state_strategy` - Test StateV2 strategy directly
- [ ] `test_domain_strategy` - Test domain strategy directly
- [ ] `test_execution_strategy` - Test execution strategy directly
- [ ] `test_exhort_strategy` - Test new ExhortStrategy directly
- [ ] `compare_strategies` - Compare outputs from multiple strategies
- [ ] `benchmark_strategies` - Performance benchmark multiple strategies

### Phase 2: Strategy Input/Output Standardization (HIGH PRIORITY)

**File**: `lib/aria_engine/hybrid_planner/strategy_interface.ex`

**Missing/Required**:
- [ ] Standardized input format for all strategies
- [ ] Standardized output format for all strategies  
- [ ] Input validation and conversion utilities
- [ ] Output formatting and comparison utilities
- [ ] Strategy metadata and capability reporting

**Implementation Patterns Needed**:
- [ ] Common input schema validation
- [ ] Strategy result normalization
- [ ] Error handling standardization
- [ ] Performance metrics collection

### Phase 3: Individual Strategy Wrappers (MEDIUM PRIORITY)

**File**: `lib/aria_engine/hybrid_planner/strategy_wrappers/`

**Missing/Required**:
- [ ] `planning_strategy_wrapper.ex` - Wrap HTN planning for direct testing
- [ ] `temporal_strategy_wrapper.ex` - Wrap STN temporal for direct testing
- [ ] `state_strategy_wrapper.ex` - Wrap StateV2 for direct testing
- [ ] `domain_strategy_wrapper.ex` - Wrap domain strategy for direct testing
- [ ] `execution_strategy_wrapper.ex` - Wrap execution strategy for direct testing
- [ ] `exhort_strategy_wrapper.ex` - Wrap ExhortStrategy for direct testing

**Implementation Patterns Needed**:
- [ ] Strategy isolation and setup
- [ ] Mock dependency injection
- [ ] Result capture and formatting
- [ ] Error isolation and reporting

### Phase 4: Strategy Comparison and Benchmarking (MEDIUM PRIORITY)

**File**: `lib/aria_engine/hybrid_planner/strategy_comparison.ex`

**Missing/Required**:
- [ ] Multi-strategy execution framework
- [ ] Result comparison algorithms
- [ ] Performance benchmarking utilities
- [ ] Visualization and reporting tools
- [ ] Statistical analysis of strategy performance

## Technical Architecture

### MCP Tool Interface Design

```elixir
# Individual Strategy Testing
%{
  name: "test_planning_strategy",
  description: "Test HTN planning strategy with specific domain and goals",
  inputSchema: %{
    type: "object",
    properties: %{
      domain: %{type: "object", description: "Domain definition"},
      state: %{type: "object", description: "Initial state"},
      goals: %{type: "array", description: "Planning goals"},
      strategy_options: %{type: "object", description: "Strategy-specific options"}
    }
  }
}

# Strategy Comparison
%{
  name: "compare_strategies",
  description: "Compare outputs from multiple strategies on same problem",
  inputSchema: %{
    type: "object", 
    properties: %{
      problem: %{type: "object", description: "Problem definition"},
      strategies: %{type: "array", description: "List of strategies to compare"},
      comparison_metrics: %{type: "array", description: "Metrics to compare"}
    }
  }
}
```

### Strategy Wrapper Pattern

```elixir
defmodule AriaEngine.HybridPlanner.StrategyWrappers.PlanningStrategyWrapper do
  @moduledoc """
  Wrapper for testing HTN planning strategy in isolation.
  """
  
  def test_strategy(domain, state, goals, opts \\ []) do
    # Setup isolated environment
    strategy = HybridPlanner.Strategies.Default.HTNPlanningStrategy
    
    # Execute strategy with timing
    start_time = System.monotonic_time(:millisecond)
    result = strategy.plan(domain, state, goals, opts)
    end_time = System.monotonic_time(:millisecond)
    
    # Format result with metadata
    %{
      strategy: "HTNPlanningStrategy",
      result: result,
      performance: %{
        execution_time_ms: end_time - start_time,
        memory_usage: :erlang.memory(:total)
      },
      metadata: strategy.strategy_info()
    }
  end
end
```

### Standardized Input/Output Format

```elixir
# Standardized Strategy Input
%{
  problem_type: :planning | :temporal | :optimization,
  domain: %Domain.Core{},
  state: %AriaEngine.StateV2{},
  goals: [term()],
  constraints: %{},
  options: %{}
}

# Standardized Strategy Output  
%{
  status: :success | :failure | :error,
  result: term(),
  performance: %{
    execution_time_ms: integer(),
    memory_usage: integer(),
    iterations: integer()
  },
  metadata: %{
    strategy_name: string(),
    strategy_version: string(),
    problem_characteristics: %{}
  }
}
```

### Strategy Comparison Framework

```elixir
defmodule AriaEngine.HybridPlanner.StrategyComparison do
  def compare_strategies(problem, strategy_list, metrics) do
    results = Enum.map(strategy_list, fn strategy ->
      execute_strategy_with_metrics(strategy, problem, metrics)
    end)
    
    %{
      problem_summary: summarize_problem(problem),
      strategy_results: results,
      comparison: %{
        performance_ranking: rank_by_performance(results),
        solution_quality: compare_solution_quality(results),
        success_rates: calculate_success_rates(results)
      }
    }
  end
end
```

## MCP Tool Definitions

### Individual Strategy Testing Tools

```elixir
# Add to @tools list in MCPTools
@tools [
  {:schedule_activities, "1.0.0"},
  {:test_planning_strategy, "1.0.0"},
  {:test_temporal_strategy, "1.0.0"}, 
  {:test_state_strategy, "1.0.0"},
  {:test_domain_strategy, "1.0.0"},
  {:test_execution_strategy, "1.0.0"},
  {:test_exhort_strategy, "1.0.0"},
  {:compare_strategies, "1.0.0"},
  {:benchmark_strategies, "1.0.0"}
]
```

### Strategy Testing Workflow

```elixir
# Example: Test ExhortStrategy on constraint satisfaction problem
{
  "tool": "test_exhort_strategy",
  "params": {
    "problem_type": "constraint_satisfaction",
    "variables": [
      {"name": "x1", "domain": [1, 2, 3]},
      {"name": "x2", "domain": [1, 2, 3]}
    ],
    "constraints": [
      {"type": "alldifferent", "variables": ["x1", "x2"]}
    ],
    "objective": {"type": "minimize", "expression": "x1 + x2"}
  }
}

# Example: Compare HTN vs Exhort on same problem
{
  "tool": "compare_strategies", 
  "params": {
    "problem": {...},
    "strategies": ["HTNPlanningStrategy", "ExhortStrategy"],
    "metrics": ["execution_time", "solution_quality", "memory_usage"]
  }
}
```

## Benefits

### Development Workflow Improvements

- **Rapid Iteration**: Test strategy changes immediately through MCP
- **Isolated Debugging**: Identify issues specific to individual strategies
- **Performance Profiling**: Measure strategy performance in isolation
- **Strategy Development**: Build new strategies with immediate testing capability

### Testing and Validation

- **Unit Testing**: Test strategies as isolated units
- **Integration Testing**: Verify strategy integration with coordinator
- **Regression Testing**: Ensure strategy changes don't break existing functionality
- **Comparative Analysis**: Compare strategy performance across different problems

### Research and Development

- **Algorithm Comparison**: Compare different algorithmic approaches
- **Performance Analysis**: Identify performance bottlenecks in specific strategies
- **Problem Classification**: Understand which strategies work best for which problems
- **Strategy Selection**: Develop heuristics for automatic strategy selection

## Implementation Strategy

### Step 1: Strategy Interface Standardization
1. Define common input/output formats for all strategies
2. Create strategy wrapper base class with common functionality
3. Implement input validation and output formatting utilities

### Step 2: Individual Strategy MCP Tools
1. Add MCP tool definitions for each strategy type
2. Implement strategy wrapper classes for isolation testing
3. Create handler functions for each strategy testing tool

### Step 3: Strategy Comparison Framework
1. Implement multi-strategy execution framework
2. Create result comparison and ranking algorithms
3. Add performance benchmarking and statistical analysis

### Step 4: Integration and Testing
1. Test individual strategy tools with existing strategies
2. Validate strategy comparison framework with known problems
3. Create comprehensive test suite for new MCP tools

### Current Focus: Phase 1 Strategy Interface

Starting with standardizing the strategy interface to enable consistent testing across all strategies, including the new ExhortStrategy from ADR-109.

**Priority Order**:
1. **Phase 1**: Strategy-level MCP tools and interface standardization
2. **Phase 2**: Individual strategy wrappers and isolation testing
3. **Phase 3**: Strategy comparison and benchmarking framework
4. **Phase 4**: Integration testing and validation

## Success Criteria

### Individual Strategy Testing
- **Direct Access**: Each strategy can be tested individually through MCP tools
- **Isolation**: Strategy tests don't interfere with each other or the main system
- **Performance Metrics**: Detailed performance data available for each strategy
- **Error Isolation**: Strategy-specific errors are clearly identified and reported

### Strategy Comparison
- **Multi-Strategy Execution**: Can run multiple strategies on same problem
- **Result Comparison**: Clear comparison of strategy outputs and performance
- **Ranking and Analysis**: Automatic ranking and statistical analysis of results
- **Visualization**: Clear presentation of comparison results

### Development Workflow
- **Rapid Testing**: Strategy changes can be tested immediately
- **Debugging Support**: Issues can be isolated to specific strategies
- **Performance Monitoring**: Strategy performance can be tracked over time
- **Research Support**: Framework supports algorithm research and development

## Consequences

### Positive Consequences

**Enhanced Development Workflow**:
- Faster strategy development and testing cycles
- Better debugging and issue isolation capabilities
- Improved understanding of strategy performance characteristics

**Better Testing Coverage**:
- Individual strategy unit testing through MCP
- Comprehensive strategy comparison and validation
- Performance regression detection

**Research Enablement**:
- Algorithm comparison and analysis capabilities
- Problem classification and strategy selection research
- Performance optimization opportunities

### Negative Consequences

**Increased Complexity**:
- Additional MCP tools to maintain and document
- Strategy wrapper layer adds abstraction overhead
- More complex testing and validation requirements

**Development Overhead**:
- Strategy interface standardization effort
- Wrapper implementation for each strategy
- Comparison framework development and maintenance

## Risks and Mitigation

### Risk: Strategy Interface Complexity
**Impact**: MEDIUM  
**Probability**: MEDIUM  
**Mitigation**: 
- Start with simple, common interface patterns
- Evolve interface based on actual strategy needs
- Maintain backward compatibility with existing strategies

### Risk: Performance Overhead
**Impact**: LOW  
**Probability**: MEDIUM  
**Mitigation**:
- Minimize wrapper overhead through efficient implementation
- Use lazy evaluation and caching where appropriate
- Profile and optimize hot paths in testing framework

### Risk: Maintenance Burden
**Impact**: MEDIUM  
**Probability**: HIGH  
**Mitigation**:
- Automate wrapper generation where possible
- Use consistent patterns across all strategy wrappers
- Comprehensive documentation and examples

## Related ADRs

- **ADR-109**: Integrate CP-SAT Solver Strategy via Exhort OR-Tools
- **ADR-091**: Hybrid Planner Dependency Encapsulation
- **ADR-101**: Reconnect Scheduler with Hybrid Planner

## References

- [MCP Protocol Specification](https://spec.modelcontextprotocol.io/)
- [Strategy Pattern Documentation](https://refactoring.guru/design-patterns/strategy)
- [Elixir Testing Best Practices](https://hexdocs.pm/ex_unit/ExUnit.html)
