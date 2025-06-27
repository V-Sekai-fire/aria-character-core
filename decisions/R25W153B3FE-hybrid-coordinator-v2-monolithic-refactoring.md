# R25W153B3FE: HybridCoordinatorV2 Monolithic Refactoring

<!-- @adr_serial R25W153B3FE -->

**Status:** Completed  
**Date:** June 27, 2025  
**Completed:** June 27, 2025  
**Priority:** HIGH

## Context

HybridCoordinatorV2 currently implements the Function As Object pattern as described by Martin Fowler, where strategy objects are stored as data and operations are delegated across multiple specialized modules. This creates unnecessary complexity and indirection for a system that doesn't require runtime strategy swapping.

### Current Architecture Issues

1. **Function As Object Anti-pattern**: The coordinator stores strategy modules as struct fields and delegates all operations to separate modules
2. **Excessive Delegation**: Main module contains only `defdelegate` calls to 5 operation modules
3. **Scattered Logic**: Functionality split across Constructor, PlanningOperations, ExecutionOperations, ReplanningOperations, and StrategyManagement
4. **Runtime Strategy Injection**: Complex dependency injection system for strategies that are never swapped at runtime
5. **Performance Overhead**: Multiple levels of indirection for every operation

### Current Structure

```
HybridCoordinatorV2 (main module - only defdelegate calls)
├── Constructor (strategy injection and validation)
├── PlanningOperations (HTN planning logic)
├── ExecutionOperations (plan execution)
├── ReplanningOperations (failure recovery)
└── StrategyManagement (strategy replacement and metrics)

Struct: %{planning_strategy, temporal_strategy, state_strategy, domain_strategy, logging_strategy, execution_strategy, metadata}
```

## Decision

Refactor HybridCoordinatorV2 from Function As Object pattern to a monolithic design by:

1. **Consolidating all logic** into the main `HybridCoordinatorV2` module
2. **Removing strategy injection** and implementing default strategy logic directly
3. **Eliminating operation modules** and their delegation pattern
4. **Simplifying the struct** to remove strategy dependencies
5. **Maintaining API compatibility** for existing callers

## Implementation Plan

### Phase 1: Analyze Default Strategy Implementations

- [x] Read and understand all default strategy modules:
  - [x] `HTNPlanningStrategy` - planning logic (wraps Plan.Core)
  - [x] `STNTemporalStrategy` - temporal constraints (MiniZinc-based STN)
  - [x] `StateV2Strategy` - state management (AriaEngine.State operations)
  - [x] `DomainStrategy` - domain queries (domain metadata and validation)
  - [x] `LoggerStrategy` - logging operations (Elixir Logger wrapper)
  - [x] `LazyExecutionStrategy` - plan execution (lazy refinement model)

### Phase 2: Create Monolithic Implementation

- [x] Backup current implementation files
- [x] Inline all operation module functions into main module:
  - [x] Move Constructor functions (new/2, new_default/1, validation)
  - [x] Move PlanningOperations functions (plan/5, validate_plan/4)
  - [x] Move ExecutionOperations functions (execute/5)
  - [x] Move ReplanningOperations functions (replan/6)
  - [x] Move StrategyManagement functions (simplified versions)
- [x] Replace strategy calls with direct implementations
- [x] Simplify struct to remove strategy fields

### Phase 3: Maintain API Compatibility

- [x] Keep all existing public function signatures unchanged
- [x] Ensure `new/2` accepts strategies parameter but ignores it
- [x] Maintain backward compatibility for all callers
- [x] Preserve existing error handling and return types

### Phase 4: Testing and Validation

- [x] Run existing test suite to verify compatibility
- [x] Test that all public APIs work unchanged
- [x] Verify performance improvements from reduced indirection
- [x] Update documentation to reflect monolithic design

### Phase 5: Cleanup

- [x] Remove unused operation module files
- [x] Remove strategy infrastructure modules if no longer needed
- [x] Update module documentation
- [x] Commit consolidated implementation

## Target Structure

```elixir
defmodule HybridPlanner.HybridCoordinatorV2 do
  defstruct [
    :metadata,           # Creation time, performance data
    :performance_data    # Direct metrics tracking
  ]

  # All functions implemented directly in this module
  def new(strategies, opts \\ [])           # Ignores strategies, maintains compatibility
  def new_default(opts \\ [])               # Simplified creation
  def plan(coordinator, domain, state, goals, opts \\ [])  # Direct implementation
  def execute(coordinator, domain, state, plan, opts \\ [])  # Direct implementation
  def replan(coordinator, domain, state, plan, fail_node_id, opts \\ [])  # Direct implementation
  # ... other functions implemented directly
end
```

## Success Criteria

- [ ] All existing callers work without modification
- [ ] Single module contains all hybrid planning logic
- [ ] No strategy injection or delegation patterns
- [ ] Improved performance from reduced indirection
- [ ] Simplified mental model for developers
- [ ] Reduced codebase complexity (6 modules → 1 module)

## Consequences

### Benefits

- **Simpler Architecture**: All logic in one cohesive module
- **Better Performance**: No indirection through strategy modules
- **Easier Debugging**: Single call stack, no delegation chains
- **Reduced Complexity**: Fewer abstractions and modules to maintain
- **Clearer Mental Model**: Direct implementation easier to understand

### Risks

- **Loss of Flexibility**: No runtime strategy swapping (acceptable per requirements)
- **Larger Module**: Single module will be larger but more cohesive
- **Refactoring Effort**: Significant code movement and testing required

## Related ADRs

- **R25W0489307**: Original hybrid planner dependency encapsulation (superseded)
- **R25W069348D**: HybridCoordinatorV3 implementation (different approach)

## Notes

This refactoring addresses the Function As Object anti-pattern identified in the current implementation while maintaining full backward compatibility for existing callers.
