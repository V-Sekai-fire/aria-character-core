# ADR-177: Modular MiniZinc Architecture Refactoring

**Status:** Active  
**Date:** 2025-06-24  
**Priority:** HIGH

## Context

The current `aria_minizinc` app contains multiple problem domains (multiply, STN, goal solving, validation) in a single application, leading to encapsulation leaking and maintenance difficulties. The user has requested extracting functionality into separate apps with better boundaries.

## Decision

Refactor the MiniZinc constraint solving system into a modular architecture with:

1. **Foundation Layer**: `aria_minizinc_executor` - Pure MiniZinc execution via Porcelain
2. **Domain-Specific Apps**: Individual apps for each problem domain with common prefix

## Implementation Plan

### Phase 1: Foundation Infrastructure ✅ COMPLETE
- [x] Create `aria_minizinc_executor` app
- [x] Extract Executor, ExecutorBehaviour, Application modules
- [x] Move template rendering logic and EEx processing
- [x] Create clean `exec/3` interface
- [x] Migrate core dependencies (Porcelain, Jason, Timex)
- [x] Implement MiniZinc availability checking
- [x] Create comprehensive test suite

### Phase 2: Domain-Specific Apps
- [x] Create `aria_minizinc_multiply` app
  - [x] Extract multiply functionality and templates
  - [x] Implement dual solver strategy (MiniZinc + Fixpoint fallback)
  - [x] Migrate multiply tests and mocks
- [x] Create `aria_minizinc_stn` app
  - [x] Extract STN functionality and templates
  - [x] Implement dual solver strategy (MiniZinc + Fixpoint CP solver)
  - [x] Migrate STN tests
- [ ] Create `aria_minizinc_goal` app
  - [ ] Extract goal solving functionality
  - [ ] Migrate goal templates and tests
- [ ] Create `aria_minizinc_validation` app
  - [ ] Extract validation solver functionality
  - [ ] Migrate validation tests

### Phase 3: Integration and Cleanup
- [ ] Update all consumers to use specific domain apps
- [ ] Remove original `aria_minizinc` app
- [ ] Update umbrella dependencies
- [ ] Verify encapsulation boundaries
- [ ] Update documentation

## Target Architecture

```
apps/aria_minizinc_executor/     # Foundation: Porcelain execution
apps/aria_minizinc_multiply/     # Arithmetic operations
apps/aria_minizinc_stn/          # Temporal constraint solving  
apps/aria_minizinc_goal/         # Planning constraint solving
apps/aria_minizinc_validation/   # Pipeline validation
```

## Dependency Graph

```
aria_minizinc_multiply ──┐
aria_minizinc_stn ──────┼── aria_minizinc_executor
aria_minizinc_goal ─────┤
aria_minizinc_validation ┘
```

## Dual Solver Strategy

Each domain app implements both MiniZinc and Fixpoint fallback:

```elixir
defmodule AriaMinizincMultiply do
  def solve(params, options \\ []) do
    case Keyword.get(options, :solver, :auto) do
      :minizinc -> solve_with_minizinc(params, options)
      :fixpoint -> solve_with_fixpoint(params, options)
      :auto -> auto_select_solver(params, options)
    end
  end
end
```

## Benefits

- **Encapsulation**: Clear boundaries prevent cross-contamination
- **Independent Testing**: Each domain tested in isolation
- **Dependency Management**: Apps only include required dependencies
- **Deployment Flexibility**: Independent scaling and deployment
- **Solver Flexibility**: MiniZinc with Fixpoint fallback per domain

## Success Criteria

- [ ] All existing functionality preserved
- [ ] Clean encapsulation boundaries established
- [ ] No cross-app module dependencies
- [ ] All tests passing
- [ ] Dual solver strategy working in each domain app

## Related ADRs

- **ADR-126**: MiniZinc multigoal optimization with fallback
- **ADR-128**: STN solver MiniZinc fallback implementation

## Current Focus

Starting with Phase 1: Create the foundation `aria_minizinc_executor` app to establish the infrastructure layer.
