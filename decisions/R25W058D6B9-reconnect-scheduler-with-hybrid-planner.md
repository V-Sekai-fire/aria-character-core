# R25W058D6B9: Reconnect Scheduler with Hybrid Planner

<!-- @adr_serial R25W058D6B9 -->

**Status:** Completed (June 18, 2025)

## Context

The scheduler module (`lib/aria_engine/scheduler.ex`) is currently disconnected from the hybrid planner due to incorrect domain converter implementation. The domain converter creates invalid structures that don't match the hybrid planner's expected todo list format, causing planning failures.

### Key Issues Identified

1. **Wrong goal tuple order**: Current converter uses predicate-first format, but StateV2 requires subject-first: `{subject, predicate, object}`
2. **Invalid method returns**: Methods return strings instead of proper goal tuples
3. **Missing action structure**: Actions not properly formatted as `{:action_name, [args]}`
4. **No backtracking support**: Methods don't return `false` for impossible constraints
5. **Incorrect durative action references**: Not using proper `{:durative_action_name, [args]}` format

### Hybrid Planner Todo List Format

Methods must return heterogeneous todo lists containing:

```elixir
[
  {"task_name", [args]},                    # Task (string name)
  {:action_name, [args]},                   # Action (atom name)
  {:durative_action_name, [args]},          # Durative Action (atom name)
  {subject, predicate, object},             # StateV2 Goal (subject first!)
  %Multigoal{goals: [goal_list]},          # Multigoal with StateV2 goals
  # ... any mix of the above, or `false` to backtrack
]
```

### Required Function Signatures

- **Actions**: `(AriaEngine.StateV2.t(), args) -> AriaEngine.StateV2.t() | false`
- **Methods**: `(args, AriaEngine.StateV2.t()) -> todo_list | false`

## Decision

Rewrite the scheduler domain converter to create a proper hybrid planner domain with correct StateV2 goal format and todo list structures.

## Implementation Plan

### Phase 1: Fix Domain Converter Core Structure ✅ COMPLETED

- [x] Update goal format to use correct StateV2 tuple order: `{subject, predicate, object}`
- [x] Create proper actions that take `(state, args)` and return new state or `false`
- [x] Create methods that return heterogeneous todo lists with proper structures
- [x] Implement backtracking support with `false` returns for constraint violations

### Phase 2: Scheduler-Specific Domain Creation ✅ COMPLETED

- [x] **Resource management actions**: Allocate/deallocate resources
- [x] **Activity execution actions**: Start/complete activities  
- [x] **Durative actions**: Time-based activity execution with proper temporal constraints
- [x] **Constraint checking methods**: Resource availability, dependencies
- [x] **Scheduling methods**: Complex decomposition of scheduling problems

### Phase 3: Integration Testing ✅ COMPLETED

- [x] Test basic scheduling: Simple activity with resource constraints
- [x] Test complex scenarios: Multiple activities, dependencies, resource conflicts
- [x] Test backtracking: Impossible constraints trigger proper backtracking
- [x] Verify scheduler works end-to-end with hybrid planner

## Success Criteria

- Scheduler can successfully create domains that work with hybrid planner
- Methods return proper todo lists with correct StateV2 goal tuples
- Actions and durative actions execute correctly through the planner
- Backtracking works when constraints cannot be satisfied
- Integration tests pass for realistic scheduling scenarios

## Consequences

### Positive

- Scheduler becomes fully functional with hybrid planner
- Enables sophisticated scheduling with resource constraints and temporal planning
- Proper separation of concerns between scheduling logic and planning execution
- Supports complex scenarios with backtracking and constraint satisfaction

### Risks

- Requires careful attention to StateV2 goal tuple order
- Must ensure all method returns match expected todo list format
- Integration complexity between scheduler domain and hybrid planner

## Related ADRs

- **R25W057B149**: Extract scheduler remove MCP
- **R25W046434A**: Migrate planner to StateV2 subject predicate fact
- **ADR-086**: Implement durative actions
- **R25W0670D79**: MCP Strategy Testing Interface using Membrane Framework Pipeline (supersedes direct MCP integration)

## Future Integration with Membrane Framework

**Note**: This ADR establishes the core scheduler-planner integration. Future work in R25W0670D79 will migrate the MCP interface to use a Membrane Framework pipeline architecture:

```
MCPSource → PlanFilter → PlannerSink → MCPSink
```

This will provide:

- Process isolation for scheduler execution
- Better fault tolerance and error recovery
- Individual strategy testing capabilities
- Dynamic pipeline reconfiguration
- Improved scalability for concurrent requests

The scheduler integration completed in this ADR will serve as the foundation for the Membrane pipeline's PlannerSink element.

## Completion Summary

**Completed:** June 18, 2025

### What Was Accomplished

1. **Core Integration Completed**: Successfully updated `lib/aria_engine/scheduler.ex` to use `HybridPlanner.HybridCoordinator` instead of direct `Plan` calls
2. **Namespace Fixes Applied**: Fixed all `PlannerAdapter` references to use proper `AriaEngine.PlannerAdapter` namespace across the codebase
3. **Domain Converter Fixed**: Completely rewrote domain converter to use task methods with durative actions
4. **Task Method Implementation**: Created proper task methods for each activity ID that return correct todo lists
5. **Durative Actions Added**: Implemented full durative action support with temporal constraints and resource management
6. **Test Success**: All scheduler tests now pass (9/9) with proper hybrid planner integration

### Key Changes Made

- **scheduler.ex**: Updated `schedule_activities/3` to use `HybridPlanner.HybridCoordinator.plan/4`
- **Multiple files**: Fixed namespace references from `PlannerAdapter` to `AriaEngine.PlannerAdapter`
- **hybrid_coordinator.ex**: Updated Plan module references for proper integration
- **domain_converter.ex**: Complete rewrite to create task methods for activity IDs instead of goal methods
- **Durative Actions**: Added proper durative action structs with conditions, effects, and temporal constraints
- **Method Returns**: Fixed all methods to return proper todo lists with correct StateV2 goal tuples

### Current State

The scheduler is now fully functional with the hybrid planner. All integration is working correctly:

- Task methods properly decompose activities into executable plans
- Durative actions handle temporal scheduling with resource allocation
- Dependencies and constraints are properly managed
- All scheduler tests pass consistently

### Test Results

```
Running ExUnit with seed: 846494, max_cases: 24
Excluding tags: [:type_check_strict]

.........
Finished in 0.1 seconds (0.1s async, 0.00s sync)
9 tests, 0 failures
```

The scheduler can now successfully:

- Schedule simple activities with dependencies
- Handle resource constraints and allocation
- Process activities with timing information
- Manage verbose logging and analysis
- Handle edge cases like missing durations and empty dependencies

## Notes

The Multigoal.ex file may have incorrect tuple ordering and should be investigated as part of future work to ensure consistency across the system.
