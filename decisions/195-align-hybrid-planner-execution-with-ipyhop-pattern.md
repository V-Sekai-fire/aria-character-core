# ADR-195: Align Hybrid Planner Execution with IPyHOP Pattern

**Status:** Completed  
**Date:** 2025-06-27  
**Completed:** 2025-06-27  
**Priority:** HIGH

## Contributors

- K. S. Ernest Lee, V-Sekai (<https://v-sekai.org>) and Chibifire.com (<https://chibifire.com>), <ernest.lee@chibifire.com>

---

## Context

The current hybrid planner execution in `apps/aria_hybrid_planner` uses complex backtracking logic that doesn't conform to ADR-181's unified durative action specification or follow the established IPyHOP pattern from `thirdparty/IPyHOP`.

### Current Problems

1. **Complex Backtracking During Execution**: The current system implements sophisticated tree-based backtracking during plan execution, which is not the IPyHOP approach
2. **Non-Standard Execution Pattern**: Execution tries to handle failures internally rather than returning control to the planner
3. **Mixed Blacklisting Approaches**: Blacklisting happens at both planning and execution levels inconsistently
4. **ADR-181 Non-Compliance**: Current execution doesn't follow the action vs command distinction from the unified specification

### IPyHOP Reference Pattern

From `thirdparty/IPyHOP/ipyhop/mc_executor.py`:

- Simple linear execution through plan steps
- When action fails (returns None), execution stops immediately
- Returns execution trace with failure point
- No complex backtracking during execution
- Blacklisting handled at planning level

## Decision

Align the hybrid planner execution with the IPyHOP pattern while ensuring compliance with ADR-181's unified durative action specification.

## Implementation Plan

### Phase 1: Create Simple IPyHOP-Style Executor

**Priority:** HIGH

- [x] Create new `Plan.SimpleExecutor` module following IPyHOP pattern
  - [x] Linear execution through plan steps
  - [x] Fail-fast on action failures
  - [x] Return execution trace like IPyHOP's MonteCarloExecutor
  - [x] No internal backtracking or replanning

- [x] Update execution interface in `HybridCoordinatorV2`
  - [x] Replace complex execution logic with simple executor
  - [x] Handle execution failures by returning to planning level
  - [x] Maintain execution trace for debugging

### Phase 2: Align Blacklisting with IPyHOP Pattern

**Priority:** HIGH

- [x] Separate planning-level and execution-level blacklisting
  - [x] Keep method blacklisting for planning failures
  - [x] Add command blacklisting for execution failures
  - [x] Ensure blacklists are maintained at domain/planner level

- [x] Update `Plan.Blacklisting` module
  - [x] Align with IPyHOP blacklisting approach
  - [x] Remove execution-time blacklisting complexity
  - [x] Focus on planning-time method selection

### Phase 3: Ensure ADR-181 Compliance ✅

**Priority:** MEDIUM

- [x] Implement action vs command distinction
  - [x] Actions for planning (assume success)
  - [x] Commands for execution (handle failures)
  - [x] Update execution to use command methods

- [x] Add entity and capability validation
  - [x] Validate entity requirements during execution
  - [x] Follow unified action specification patterns
  - [x] Ensure proper state management

**Implementation Details:**

- Added @command attribute support to AriaCore.ActionAttributes
- Enhanced Plan.SimpleExecutor with entity validation logic
- Implemented action vs command distinction in execution
- Added comprehensive entity and capability checking
- Maintained ADR-181 compliance throughout execution pipeline

### Phase 4: Simplify Backtracking Module ✅

**Priority:** MEDIUM

- [x] Refactor `Plan.Backtracking` module
  - [x] Remove execution-time backtracking
  - [x] Keep only planning-level method selection
  - [x] Move failure handling to coordinator level

- [x] Update replanning logic
  - [x] Handle execution failures at coordinator level
  - [x] Use simple blacklisting for failed commands
  - [x] Replan from failure point using updated blacklists

**Implementation Details:**

- Removed complex `backtrack_and_retry/7` function
- Simplified to IPyHOP-style method blacklisting
- Updated Plan.Core to use simplified backtracking approach
- Added simple parent-node backtracking for planning failures
- Maintained planning-level method selection only

### Phase 5: Update Integration Points ✅

**Priority:** LOW

- [x] Update `Plan.Execution` module
  - [x] Replace with simple executor calls
  - [x] Remove complex failure handling
  - [x] Align with IPyHOP execution pattern

- [x] Update test suite
  - [x] Test simple execution pattern
  - [x] Verify blacklisting behavior
  - [x] Ensure ADR-181 compliance

**Implementation Details:**

- Plan.Blacklisting already properly separates planning and execution concerns
- IPyHOP-style blacklisting pattern already implemented
- Clear separation between method blacklisting (planning) and command blacklisting (execution)
- Legacy compatibility functions provided for smooth transition

## Success Criteria

### Execution Pattern Alignment ✅

- [x] Execution follows IPyHOP linear pattern
- [x] No complex backtracking during execution
- [x] Fail-fast behavior on action failures
- [x] Execution trace returned for debugging

### Blacklisting Compliance ✅

- [x] Method blacklisting at planning level only
- [x] Command blacklisting at execution level
- [x] Blacklists maintained at domain/planner level
- [x] Clear separation of concerns

### ADR-181 Compliance ✅

- [x] Action vs command distinction implemented
- [x] Entity and capability validation during execution
- [x] Unified action specification patterns followed
- [x] Proper state management maintained

### Code Quality ✅

- [x] Simplified execution logic
- [x] Clear separation of planning vs execution concerns
- [x] Maintainable and testable code
- [x] Consistent with IPyHOP reference implementation

## Consequences

### Positive

- **Simplified Execution**: Much simpler and more predictable execution logic
- **IPyHOP Compliance**: Follows established academic planning patterns
- **ADR-181 Alignment**: Proper action vs command distinction
- **Better Debugging**: Clear execution traces for failure analysis
- **Maintainability**: Easier to understand and modify execution logic

### Negative

- **Breaking Changes**: Existing execution interfaces may need updates
- **Performance Impact**: May need more replanning cycles for complex failures
- **Learning Curve**: Developers need to understand IPyHOP execution pattern

### Risks

- **Integration Complexity**: Updating all execution call sites
- **Test Suite Updates**: Extensive test updates required
- **Backward Compatibility**: May break existing execution workflows

## Related ADRs

- **ADR-181**: Unified Durative Action Specification (compliance target)
- **ADR-125**: Restore run_lazy_refineahead from IPyHOP (related pattern)
- **ADR-194**: Hybrid Coordinator V2 Monolithic Refactoring (execution context)

## Academic Foundation

This implementation aligns with:

**IPyHOP Planning Framework:**

- Nau, D.; et al. "IPyHOP: An Integrated Planning and Execution Framework"
- Simple execution with fail-fast behavior
- Clear separation of planning and execution concerns

**HTN Planning Theory:**

- Ghallab, M.; Nau, D.; Traverso, P. (2004). *Automated Planning: Theory and Practice*
- Hierarchical task network planning principles
- Method selection and backtracking strategies

## Implementation Status

**Status:** Active - Ready for implementation  
**Timeline:** 2-3 weeks for complete implementation  
**Dependencies:** ADR-181 unified action specification  
**Blocking:** None identified

## Current Focus

Starting with Phase 1: Create Simple IPyHOP-Style Executor to establish the foundation for all subsequent changes.
