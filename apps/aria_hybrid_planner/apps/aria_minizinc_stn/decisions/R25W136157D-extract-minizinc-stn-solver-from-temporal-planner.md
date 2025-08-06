# R25W136157D: Extract MiniZinc STN Solver from Temporal Planner

<!-- @adr_serial R25W136157D -->

**Status:** Completed  
**Date:** 2025-06-24  
**Completion Date:** 2025-06-24  
**Priority:** HIGH

## Context

The `aria_temporal_planner` app currently contains MiniZinc-based STN solving functionality in `Timeline.Internal.STN.MiniZincSolver`. However, there's already a dedicated `aria_minizinc_stn` app that provides the same functionality with a cleaner interface. This creates duplication and inconsistency in the codebase.

### Current State

**In aria_temporal_planner:**

- `Timeline.Internal.STN.MiniZincSolver` module
- Calls `Executor.exec("stn_temporal", template_vars: template_vars)`
- Integrated into the main STN module via delegation
- Uses `AriaEngine.MiniZinc.Executor` from aria_engine_core

**In aria_minizinc_stn:**

- `AriaMinizincStn` module with clean public API
- Same MiniZinc template (`stn_temporal.mzn.eex`)
- Uses `AriaMinizincExecutor.exec()` directly
- Comprehensive error handling and validation

### Problems

1. **Code duplication:** Nearly identical STN solving logic in two places
2. **Inconsistent interfaces:** Different APIs for the same functionality
3. **Maintenance burden:** Changes need to be made in multiple places
4. **Dependency confusion:** Temporal planner bypasses dedicated STN app

## Decision

Extract the MiniZinc STN solving functionality from `aria_temporal_planner` and replace it with calls to the dedicated `aria_minizinc_stn` app.

## Implementation Plan

### Phase 1: Update Dependencies

- [x] Add `aria_minizinc_stn` dependency to `aria_temporal_planner/mix.exs`
- [x] Remove direct `AriaEngine.MiniZinc.Executor` usage from temporal planner

### Phase 2: Replace MiniZincSolver Module

- [x] Update `Timeline.Internal.STN.MiniZincSolver` to delegate to `AriaMinizincStn`
- [x] Maintain existing interface for backward compatibility
- [x] Update error handling to match new delegation pattern

### Phase 3: Clean Up and Test

- [x] Remove duplicate constraint conversion logic
- [x] Update tests to verify delegation works correctly
- [x] Ensure all existing functionality is preserved

### Phase 4: Documentation

- [x] Update module documentation to reflect delegation
- [x] Document the architectural change in relevant ADRs

## Success Criteria

- [x] `aria_temporal_planner` successfully delegates STN solving to `aria_minizinc_stn`
- [x] All existing tests pass without modification
- [x] No duplicate STN solving logic remains in temporal planner
- [x] Clean separation of concerns between temporal planning and STN solving

## Benefits

- **Reduced duplication:** Single source of truth for STN solving
- **Better separation of concerns:** Temporal planner focuses on planning, not constraint solving
- **Improved maintainability:** Changes to STN solving only need to be made in one place
- **Consistent API:** All STN solving goes through the same interface

## Risks

- **Interface compatibility:** Need to ensure delegation maintains existing behavior
- **Dependency management:** Adding new dependency between apps
- **Testing complexity:** Need to verify delegation doesn't break existing functionality

## Related ADRs

- **R25W135339D**: Modular MiniZinc Architecture Refactoring
- **R25W086088D**: STN Solver MiniZinc Fallback Implementation
