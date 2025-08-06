# R25W135339D: Modular MiniZinc Architecture Refactoring

<!-- @adr_serial R25W135339D -->

**Status:** Completed  
**Date:** 2025-06-24  
**Completion Date:** 2025-06-24  
**Priority:** HIGH

## Context

The current `aria_minizinc` app contains multiple problem domains (multiply, STN, goal solving, validation) in a single application, leading to encapsulation leaking and maintenance difficulties. The user has requested extracting functionality into separate apps with better boundaries.

## Decision

Refactor the MiniZinc constraint solving system into a modular architecture with:

1. **Foundation Layer**: `aria_minizinc_executor` - Pure MiniZinc execution via Porcelain
2. **Domain-Specific Apps**: Individual apps for each problem domain with common prefix
3. **MiniZinc-Only Strategy**: All domain apps use pure MiniZinc constraint solving without fallback mechanisms

**TOMBSTONED**: The original dual solver strategy with Fixpoint fallback has been removed in favor of a simplified, MiniZinc-only approach.

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
  - [x] ~~Implement dual solver strategy (MiniZinc + Fixpoint fallback)~~ **TOMBSTONED**
  - [x] Migrate multiply tests and mocks
- [x] Create `aria_minizinc_stn` app
  - [x] Extract STN functionality and templates
  - [x] ~~Implement dual solver strategy (MiniZinc + Fixpoint CP solver)~~ **TOMBSTONED**
  - [x] Migrate STN tests
- [x] Create `aria_minizinc_goal` app
  - [x] Extract goal solving functionality and templates
  - [x] ~~Implement dual solver strategy~~ **TOMBSTONED**
  - [x] Migrate goal tests
- [x] Validation functionality (integrated into STN app)
  - [x] ValidationSolver is wrapper around STN temporal solving
  - [x] No separate app needed - handled by aria_minizinc_stn

### Phase 2.5: Fixpoint Fallback Tombstoning ✅ COMPLETE

- [x] Remove all Fixpoint fallback code from domain apps
- [x] Update APIs to MiniZinc-only strategy
- [x] Clean up dependencies (remove `:fixpoint` from mix.exs files)
- [x] Update documentation to reflect architectural decision
- [x] Fix MiniZinc output parsing to handle structured executor responses
- [x] Verify all domain app tests pass with MiniZinc-only strategy

### Phase 3: Integration and Cleanup ✅ COMPLETE

- [x] Update all consumers to use specific domain apps (no external consumers found)
- [x] Remove original `aria_minizinc` app
- [x] Update umbrella dependencies (domain apps are standalone)
- [x] Verify encapsulation boundaries (all tests pass)
- [x] Update documentation (ADR updated with final architecture)

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

## MiniZinc-Only Strategy

Each domain app implements pure MiniZinc constraint solving:

```elixir
defmodule AriaMinizincMultiply do
  def solve(params, options \\ []) do
    solve_with_minizinc(params, options)
  end
end
```

**Architectural Decision**: All fallback mechanisms have been tombstoned in favor of:

- **Simplified APIs**: Direct MiniZinc execution without solver selection complexity
- **Fail-fast behavior**: Clear error reporting when MiniZinc is unavailable
- **Consistent architecture**: All domain apps follow the same MiniZinc-only pattern

## Benefits

- **Encapsulation**: Clear boundaries prevent cross-contamination
- **Independent Testing**: Each domain tested in isolation
- **Dependency Management**: Apps only include required dependencies
- **Deployment Flexibility**: Independent scaling and deployment
- **Simplified Architecture**: Pure MiniZinc approach eliminates fallback complexity
- **Consistent Behavior**: All domain apps follow the same execution pattern

## Success Criteria

- [x] All existing functionality preserved
- [x] Clean encapsulation boundaries established
- [x] No cross-app module dependencies
- [x] All tests passing
- [x] MiniZinc-only strategy implemented in each domain app
- [x] All fallback code removed and dependencies cleaned up

## Related ADRs

- **R25W0849E89**: MiniZinc multigoal optimization with fallback
- **R25W086088D**: STN solver MiniZinc fallback implementation

## Change Log

### June 24, 2025

- **TOMBSTONED**: Fixpoint fallback strategy removed from all domain apps
- **Architectural Decision**: Converted to MiniZinc-only strategy for simplified, consistent behavior
- **Rationale**: Fixpoint CP solver implementations were incomplete/broken, causing compilation issues
- **Impact**: All domain apps now use pure MiniZinc constraint solving without fallback complexity

## Current Focus

**COMPLETED**: All phases successfully implemented. The modular MiniZinc architecture is now fully operational with clean encapsulation boundaries and simplified MiniZinc-only constraint solving across all domain apps.
