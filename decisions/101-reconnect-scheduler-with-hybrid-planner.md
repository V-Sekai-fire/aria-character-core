# ADR-101: Reconnect Scheduler with Hybrid Planner

**Status:** Active (June 18, 2025)

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

### Phase 1: Fix Domain Converter Core Structure
- [ ] Update goal format to use correct StateV2 tuple order: `{subject, predicate, object}`
- [ ] Create proper actions that take `(state, args)` and return new state or `false`
- [ ] Create methods that return heterogeneous todo lists with proper structures
- [ ] Implement backtracking support with `false` returns for constraint violations

### Phase 2: Scheduler-Specific Domain Creation
- [ ] **Resource management actions**: Allocate/deallocate resources
- [ ] **Activity execution actions**: Start/complete activities  
- [ ] **Durative actions**: Time-based activity execution with proper temporal constraints
- [ ] **Constraint checking methods**: Resource availability, dependencies
- [ ] **Scheduling methods**: Complex decomposition of scheduling problems

### Phase 3: Integration Testing
- [ ] Test basic scheduling: Simple activity with resource constraints
- [ ] Test complex scenarios: Multiple activities, dependencies, resource conflicts
- [ ] Test backtracking: Impossible constraints trigger proper backtracking
- [ ] Verify scheduler works end-to-end with hybrid planner

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

- **ADR-100**: Extract scheduler remove MCP
- **ADR-089**: Migrate planner to StateV2 subject predicate fact
- **ADR-086**: Implement durative actions

## Notes

The Multigoal.ex file may have incorrect tuple ordering and should be investigated as part of this work to ensure consistency across the system.
