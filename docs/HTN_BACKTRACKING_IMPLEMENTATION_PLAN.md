# HTN Backtracking Implementation Plan

## Overview

This document outlines the implementation plan for fixing and enhancing the HTN (Hierarchical Task Network) backtracking system in AriaEngine. The plan is divided into two phases to maximize success within time constraints while delivering both immediate fixes and significant performance improvements.

## Current Problem

The HTN planning system has a critical backtracking issue where sequential tasks with interdependencies fail to explore all possible solutions. Specifically:

- **Symptom**: Tests like `[{"put_it", []}, {"need0", []}]` fail with "All task methods failed"
- **Root Cause**: When the first task (`put_it`) succeeds with one method but the second task (`need0`) fails due to state conflicts, the system doesn't backtrack to try alternative methods for the first task
- **Impact**: 3 out of 6 backtracking tests are failing

### Example Failure Case
```elixir
# Goals: [{"put_it", []}, {"need0", []}]
# Current behavior:
1. put_it uses m1 method → [{"putv", [1]}, {"getv", [1]}] → sets flag=1 ✓
2. need0 uses only method → [{"getv", [0]}] → fails because flag=1 ≠ 0 ✗
3. System gives up with "All task methods failed"

# Expected behavior:
1. put_it uses m1 method → fails overall plan
2. **BACKTRACK**: try put_it with m0 method → [{"putv", [0]}, {"getv", [0]}] → sets flag=0 ✓
3. need0 uses only method → [{"getv", [0]}] → succeeds because flag=0 = 0 ✓
```

## Phase 1: Fix Current Backtracking (Priority: High, Time: 15-30 minutes)

### Objective
Get all 6 backtracking tests passing by implementing proper cross-task backtracking.

### Technical Analysis

The issue is in the `try_plan_todos_with_backtracking` function. Currently:

1. **Sequential Processing**: Todos are processed one at a time
2. **No Cross-Task Backtracking**: When a later todo fails, the system doesn't retry earlier todos with different methods
3. **Premature Failure**: The function propagates errors up instead of exploring alternative task methods

### Required Changes

#### 1. Fix `try_task_methods_with_remaining_todos`
```elixir
# Current logic (broken):
# - Try method for current task
# - If method succeeds, combine with remaining todos
# - If combined plan fails, try next method
# - But this doesn't properly explore all combinations

# Fixed logic (needed):
# - Try method for current task
# - If method succeeds, try to plan the FULL remaining todo list
# - If the full plan fails, backtrack and try next method for current task
# - Continue until a method allows the complete plan to succeed
```

#### 2. Ensure Proper State Management
- Each method attempt must start from the same initial state
- State changes from failed attempts must not persist
- Backtracking must properly reset state

#### 3. Correct Action Accumulation
```elixir
# Fix the action accumulation order:
# - Actions should be accumulated in the correct sequence
# - Reversals should be handled properly
# - No duplicate or missing actions
```

### Implementation Steps

1. **Debug Current Flow**: Add verbose logging to understand exact failure point
2. **Fix State Reset**: Ensure each method attempt starts from clean state
3. **Fix Cross-Task Logic**: Modify `try_task_methods_with_remaining_todos` to properly handle remaining todos
4. **Test and Validate**: Run backtracking tests to confirm all 6 pass

### Success Criteria
- All 6 backtracking tests pass
- Plans return expected action sequences (e.g., `[{"putv", [0]}, {"getv", [0]}, {"getv", [0]}]`)
- No regression in existing functionality

## Phase 2: Add Parallel Sets (Priority: Medium, Time: 1-2 hours)

### Objective
Implement unordered todo sets that can be planned in parallel using Elixir processes, dramatically improving planning performance.

### Motivation

Elixir's actor model provides a unique opportunity to parallelize HTN planning in ways that traditional HTN planners cannot:

1. **Concurrent Method Exploration**: Try multiple task methods simultaneously
2. **Parallel Permutation Testing**: For unordered sets, try different orderings in parallel
3. **Fault Tolerance**: Failed planning processes don't crash the entire planner
4. **Scalability**: Leverage multi-core systems for complex planning domains

### Architecture Design

#### 1. Extended Todo Types
```elixir
@type todo_item :: 
  task() | 
  goal() | 
  Multigoal.t() |
  {:unordered_set, [todo_item()]}  # New!

# Example usage:
goals = [
  {"setup_environment", []},           # Sequential: must be first
  {:unordered_set, [                   # Parallel: any order
    {"backup_data", []},
    {"update_system", []},
    {"restart_services", []}
  ]},
  {"verify_completion", []}            # Sequential: must be last
]
```

#### 2. Parallel Planning Functions

##### Core Parallel Planner
```elixir
defp try_plan_unordered_set(domain, state, todos, actions, depth, max_depth, verbose) do
  # Generate all permutations of the todo set
  permutations = generate_permutations(todos)
  
  # Spawn a process for each permutation
  tasks = Enum.map(permutations, fn perm ->
    Task.async(fn ->
      case try_plan_todos_with_backtracking(domain, state, perm, actions, depth, max_depth, verbose) do
        {:ok, final_state, plan} -> {:success, final_state, plan, perm}
        {:error, reason} -> {:failure, reason, perm}
      end
    end)
  end)
  
  # Wait for first success or all failures
  wait_for_first_success(tasks)
end
```

##### Success Handler
```elixir
defp wait_for_first_success(tasks) do
  case Task.yield_many(tasks, 5000) do  # 5 second timeout
    results when length(results) > 0 ->
      # Check for any successful results
      case find_success(results) do
        {:ok, final_state, plan} ->
          # Kill remaining tasks for efficiency
          Enum.each(tasks, &Task.shutdown/1)
          {:ok, final_state, plan}
        
        nil ->
          # No success yet, could implement progressive timeout
          {:error, "All permutations failed"}
      end
    
    [] ->
      {:error, "Planning timeout"}
  end
end
```

#### 3. Advanced: Parallel Method Exploration

For even more aggressive parallelization:

```elixir
defp try_task_methods_parallel(domain, state, methods, args, remaining_todos, actions, depth, max_depth, verbose) do
  # Spawn a process for each method
  tasks = Enum.map(methods, fn method ->
    Task.async(fn ->
      case method.(state, args) do
        nil -> 
          {:method_failed, method}
        
        result when is_list(result) ->
          combined_todos = result ++ remaining_todos
          case try_plan_todos_with_backtracking(domain, state, combined_todos, actions, depth + 1, max_depth, verbose) do
            {:ok, final_state, final_actions} -> 
              {:method_success, final_state, final_actions, method}
            {:error, reason} -> 
              {:method_failed_planning, reason, method}
          end
      end
    end)
  end)
  
  wait_for_first_method_success(tasks)
end
```

### Integration Points

#### 1. Main Planning Function
```elixir
defp try_plan_todos_with_backtracking(domain, state, todos, actions, depth, max_depth, verbose) do
  case todos do
    [] -> 
      {:ok, state, Enum.reverse(actions)}
    
    [{:unordered_set, set_todos} | rest_todos] ->
      # Handle unordered set with parallel planning
      case try_plan_unordered_set(domain, state, set_todos, actions, depth, max_depth, verbose) do
        {:ok, new_state, new_actions} ->
          combined_actions = new_actions ++ actions
          try_plan_todos_with_backtracking(domain, new_state, rest_todos, combined_actions, depth, max_depth, verbose)
        {:error, _} = error ->
          error
      end
    
    [todo | rest_todos] ->
      # Regular sequential processing (Phase 1 logic)
      # ... existing implementation
  end
end
```

#### 2. Configuration Options
```elixir
# Planning options
@spec plan(Domain.t(), State.t(), [todo_item()], keyword()) :: plan_result()
def plan(domain, state, todos, opts \\ []) do
  max_depth = Keyword.get(opts, :max_depth, @default_max_depth)
  verbose = Keyword.get(opts, :verbose, @default_verbose)
  parallel_enabled = Keyword.get(opts, :parallel, true)  # New!
  max_parallel_tasks = Keyword.get(opts, :max_parallel_tasks, 8)  # New!
  parallel_timeout = Keyword.get(opts, :parallel_timeout, 5000)  # New!
  
  # ... planning logic
end
```

### Performance Benefits

#### 1. Speed Improvements
- **Permutation Exploration**: For n unordered todos, explore all n! orderings simultaneously
- **Method Backtracking**: Try all methods for a task in parallel rather than sequentially
- **Early Termination**: First successful plan wins, others are terminated

#### 2. Scalability
- **Multi-Core Utilization**: Leverage all available CPU cores
- **Memory Efficiency**: Each process has isolated memory, prevents memory leaks
- **Fault Isolation**: Planning failures in one process don't affect others

#### 3. Real-World Applications
```elixir
# Example: Complex deployment planning
deployment_goals = [
  {"validate_environment", []},
  {:unordered_set, [
    {"backup_database", []},
    {"scale_down_services", []},
    {"update_configurations", []},
    {"prepare_rollback", []}
  ]},
  {"deploy_application", []},
  {:unordered_set, [
    {"run_smoke_tests", []},
    {"update_monitoring", []},
    {"notify_stakeholders", []}
  ]},
  {"verify_deployment", []}
]
```

### Implementation Steps

1. **Extend Type System**: Add `{:unordered_set, [todo_item()]}` support
2. **Implement Permutation Generator**: Efficient permutation generation for sets
3. **Add Task Management**: Process spawning, monitoring, and cleanup
4. **Implement Timeout Handling**: Progressive timeouts and graceful degradation
5. **Add Configuration**: Parallel planning options and limits
6. **Performance Testing**: Benchmark against sequential planning
7. **Documentation**: Usage examples and best practices

### Success Criteria
- Unordered sets plan successfully with correct results
- Parallel planning shows measurable performance improvements
- System remains stable under concurrent load
- Memory usage remains bounded
- No deadlocks or race conditions

## Risk Assessment

### Phase 1 Risks (Low)
- **Complexity**: Limited scope, well-understood problem
- **Regression**: Minimal risk due to focused changes
- **Time**: High confidence in 15-30 minute estimate

### Phase 2 Risks (Medium)
- **Concurrency Bugs**: Process management complexity
- **Performance**: May not show benefits for simple domains
- **Resource Usage**: Could consume more memory/CPU
- **Integration**: Requires careful integration with existing code

## Timeline

| Phase | Task | Estimated Time | Priority |
|-------|------|----------------|----------|
| 1 | Debug current backtracking flow | 5-10 min | High |
| 1 | Fix cross-task backtracking logic | 10-15 min | High |
| 1 | Test and validate fixes | 5-10 min | High |
| 2 | Design parallel architecture | 15-20 min | Medium |
| 2 | Implement basic parallel planning | 30-45 min | Medium |
| 2 | Add advanced features (parallel methods) | 20-30 min | Low |
| 2 | Testing and optimization | 15-20 min | Medium |

**Total Estimated Time**: 2-2.5 hours maximum

## Expected Outcomes

### Phase 1 Success
- ✅ All backtracking tests pass
- ✅ Correct action sequences generated
- ✅ Robust cross-task backtracking
- ✅ Foundation for Phase 2

### Phase 2 Success
- ✅ Parallel planning capability
- ✅ Significant performance improvements
- ✅ Unique competitive advantage
- ✅ Scalable architecture for complex domains

## Future Enhancements

### Phase 3: Advanced Features (Future)
1. **Adaptive Parallelism**: Dynamic adjustment based on domain complexity
2. **Distributed Planning**: Planning across multiple nodes
3. **Plan Caching**: Memoization of successful subplans
4. **Progressive Planning**: Iterative refinement of plans
5. **Machine Learning Integration**: Learning optimal method orderings

### Phase 4: Enterprise Features (Future)
1. **Plan Visualization**: GraphQL-based plan inspection
2. **Real-time Monitoring**: Live planning performance metrics
3. **Resource Constraints**: CPU/memory limits for planning processes
4. **Priority Queues**: Weighted planning based on goal importance

## Conclusion

This two-phase approach provides:

1. **Immediate Value**: Phase 1 fixes critical functionality
2. **Long-term Advantage**: Phase 2 creates unique competitive differentiation
3. **Risk Management**: Incremental delivery reduces failure risk
4. **Architectural Foundation**: Proper base for future enhancements

The combination of fixed backtracking and parallel planning will make AriaEngine's HTN planner significantly more powerful and performant than traditional implementations, while leveraging Elixir's unique strengths in concurrent systems.
