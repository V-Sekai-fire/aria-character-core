# R25W025F371: Replace Membrane Workflows with Flow Pipelines for Parallel Processing

<!-- @adr_serial R25W025F371 -->

## Status

**Accepted**

## Date

2025-06-15

## Context

The current Membrane-based workflow system shows severe coordination overhead issues, particularly in multi-core scenarios. Test results from `aria_engine/test/membrane_workflow_test.exs` reveal:

- **Coordination Overhead**: 91.9% (target: <20%)
- **Efficiency**: 8.1% (target: >80%)
- **Actual Speedup**: 1.0x on 12 cores (expected: ~10x)
- **Coordination Scaling**: Poor scaling beyond 2 cores

This directly contradicts R25W023C3DB's architecture requirements for "Multi-core STN solving using Flow pipelines" and "Parallel Solving" capabilities.

### Current Problem

The Membrane workflow system was designed for streaming media processing, not computational parallelism. Its pipeline coordination model creates bottlenecks that prevent effective multi-core utilization:

```elixir
# Current Membrane approach (inefficient)
def test_backflow_gpu_convergence_with_work_stealing(action_count, core_count) do
  # Membrane's pipeline coordination creates bottlenecks
  # Each core waits for coordination messages
  # Result: 91.9% coordination overhead
end
```

### R25W023C3DB Specification

R25W023C3DB explicitly specified Flow for parallel processing:

```elixir
# Performance optimization
{:flow, "~> 1.2"},                 # Parallel processing pipelines

# Concurrency Requirements
- **Parallel Solving**: Multi-core STN solving using Flow pipelines
```

However, the implementation deviated to use Membrane, leading to the current performance issues.

## Decision

**Replace Membrane workflows with Flow-based parallel processing** for all computational parallelism use cases, while maintaining Membrane only for appropriate streaming scenarios.

### Flow-Based Architecture

**Core Principle**: Use Flow's staged parallel processing for CPU-bound computational tasks:

```elixir
defmodule AriaEngine.FlowWorkflow do
  @moduledoc "Flow-based parallel processing for computational workloads"
  
  def parallel_action_processing(actions, core_count \\ System.schedulers_online()) do
    actions
    |> Flow.from_enumerable(stages: core_count)
    |> Flow.map(&process_single_action/1)
    |> Flow.partition()
    |> Flow.reduce(fn -> [] end, fn action_result, acc -> [action_result | acc] end)
    |> Enum.to_list()
  end
  
  def parallel_constraint_solving(constraints, core_count \\ System.schedulers_online()) do
    constraints
    |> Flow.from_enumerable(stages: core_count)
    |> Flow.map(&solve_constraint/1)
    |> Flow.partition()
    |> Flow.reduce(fn -> %{} end, fn result, acc -> Map.merge(acc, result) end)
    |> Enum.to_list()
    |> List.first()
  end
  
  defp process_single_action(action) do
    # Process individual action without coordination overhead
    # Each stage works independently
    AriaEngine.ActionProcessor.execute(action)
  end
  
  defp solve_constraint(constraint) do
    # Solve individual constraint using available CPU
    # Flow automatically distributes work across cores
    AriaEngine.ConstraintSolver.solve(constraint)
  end
end
```

### Performance Expectations

**Target Performance Characteristics** (based on Flow's design):

- **Coordination Overhead**: <5% (vs current 91.9%)
- **Efficiency**: >90% (vs current 8.1%)
- **Actual Speedup**: 8-10x on 12 cores (vs current 1.0x)
- **Memory Usage**: Lower due to reduced coordination

**Flow Advantages for Computational Work**:

1. **Staged Processing**: Each stage operates independently
2. **Automatic Load Balancing**: Work distributed evenly across cores
3. **Backpressure Management**: Built-in flow control
4. **Low Coordination Overhead**: Minimal inter-stage communication

## Rationale

### Why Flow vs Membrane for Computational Tasks?

| Aspect | Flow | Membrane |
|--------|------|----------|
| **Design Purpose** | Parallel computation | Streaming media |
| **Coordination Model** | Staged independence | Pipeline synchronization |
| **CPU Utilization** | High (90%+) | Low (8%) |
| **Memory Overhead** | Low | High |
| **Backpressure** | Built-in | Manual |
| **Core Scaling** | Linear | Poor (plateau at 2 cores) |

### When to Use Each Technology

**Use Flow For**:

- ✅ CPU-intensive computational tasks
- ✅ Parallel constraint solving
- ✅ Batch action processing
- ✅ Mathematical computations (STN solving)
- ✅ Data transformation pipelines

**Use Membrane For**:

- ✅ Streaming audio/video processing
- ✅ Real-time data streams
- ✅ Media format conversion
- ❌ ~~General computational parallelism~~ (poor performance)

### R25W023C3DB Compliance

This change brings the implementation into compliance with R25W023C3DB's specification:

```elixir
# R25W023C3DB specification (now being implemented correctly)
{:flow, "~> 1.2"},                 # Parallel processing pipelines

# Concurrency Requirements
- **Parallel Solving**: Multi-core STN solving using Flow pipelines ✅
- **Concurrent Planners**: Multiple independent planning processes ✅  
- **Backpressure Handling**: GenStage-based constraint propagation ✅
```

## Implementation Plan

### Phase 1: Core Flow Integration (Immediate)

1. **Add Flow dependency** to `aria_engine/mix.exs`
2. **Create FlowWorkflow module** with parallel processing functions
3. **Replace test failing scenarios** with Flow-based implementations
4. **Verify performance improvements** in coordination overhead test

### Phase 2: Workflow Migration (Near-term)

1. **Migrate computational workflows** from Membrane to Flow
2. **Preserve Membrane** for appropriate streaming use cases
3. **Update documentation** to reflect technology boundaries
4. **Performance benchmarking** to validate improvements

### Phase 3: Architecture Refinement (Future)

1. **Optimize Flow stages** for specific computational patterns
2. **Integration with Nx tensors** for mathematical operations
3. **Resource constraint solving** using Flow parallelism
4. **Advanced backpressure tuning** for planning scenarios

## Test Changes Required

### Current Failing Test Fix

```elixir
# Replace this Membrane test:
test "Membrane coordination overhead: 1 core vs all cores" do
  # Current implementation with 91.9% overhead
end

# With this Flow test:
test "Flow parallel processing efficiency: 1 core vs all cores" do
  action_count = 500
  all_cores = System.schedulers_online()

  # Test 1: Single core Flow pipeline
  {single_time_us, single_result} = :timer.tc(fn ->
    test_flow_parallel_processing(action_count, 1)
  end)

  # Test 2: All cores Flow pipelines  
  {all_cores_time_us, all_cores_result} = :timer.tc(fn ->
    test_flow_parallel_processing(action_count, all_cores)
  end)

  # Calculate actual efficiency
  speedup = (single_time_us / all_cores_time_us)
  efficiency = speedup / all_cores
  
  # Flow should achieve >80% efficiency vs Membrane's 8%
  assert efficiency > 0.8, "Flow efficiency should exceed 80%"
  assert speedup > (all_cores * 0.7), "Should achieve 70%+ of theoretical speedup"
end

defp test_flow_parallel_processing(action_count, core_count) do
  actions = generate_test_actions(action_count)
  
  results = AriaEngine.FlowWorkflow.parallel_action_processing(actions, core_count)
  
  %{
    processed_count: length(results),
    total_time_ms: measure_processing_time(results)
  }
end
```

## Consequences

### Positive

- **Dramatic Performance Improvement**: From 8% to >90% CPU utilization efficiency
- **True Multi-Core Scaling**: Linear scaling across available cores
- **Reduced Coordination Overhead**: From 91.9% to <5%
- **R25W023C3DB Compliance**: Proper implementation of specified architecture
- **Lower Memory Usage**: Reduced coordination state and messaging overhead
- **Better Resource Utilization**: Effective use of available hardware

### Negative

- **Migration Effort**: Need to rewrite existing Membrane computational workflows
- **Technology Mix**: Two parallel processing technologies in codebase (Flow + Membrane)
- **Learning Curve**: Team needs to understand Flow vs Membrane use cases

### Neutral

- **Dependency Addition**: Flow library addition (already specified in R25W023C3DB)
- **Test Updates**: Need to update performance tests to reflect new technology

## Success Criteria

1. **Performance Test Passes**: Flow coordination overhead test shows >80% efficiency
2. **Multi-Core Scaling**: Achieve 70%+ of theoretical speedup on available cores
3. **Memory Efficiency**: Reduced memory usage compared to Membrane approach
4. **Code Quality**: Clean separation between Flow and Membrane use cases
5. **Documentation Updated**: Clear guidelines on when to use each technology

This ADR corrects the architectural deviation from R25W023C3DB and resolves the critical performance bottleneck identified in the failing tests.
