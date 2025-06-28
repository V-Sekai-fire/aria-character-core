# R25W1547587: Align Hybrid Planner Execution with IPyHOP Pattern

<!-- @adr_serial R25W1547587 -->

**Status:** Active  
**Date:** 2025-06-27  
**Priority:** HIGH

## Contributors

- K. S. Ernest Lee, V-Sekai (<https://v-sekai.org>) and Chibifire.com (<https://chibifire.com>), <ernest.lee@chibifire.com>

---

## Context

The current hybrid planner execution in `apps/aria_hybrid_planner` uses complex backtracking logic that doesn't conform to R25W1398085's unified durative action specification or follow the established IPyHOP pattern from `thirdparty/IPyHOP`.

### Current Problems

1. **Complex Backtracking During Execution**: The current system implements sophisticated tree-based backtracking during plan execution, which is not the IPyHOP approach
2. **Non-Standard Execution Pattern**: Execution tries to handle failures internally rather than returning control to the planner
3. **Mixed Blacklisting Approaches**: Blacklisting happens at both planning and execution levels inconsistently
4. **R25W1398085 Non-Compliance**: Current execution doesn't follow the action vs command distinction from the unified specification

### IPyHOP Reference Pattern

From `thirdparty/IPyHOP/ipyhop/mc_executor.py`:

- Simple linear execution through plan steps
- When action fails (returns None), execution stops immediately
- Returns execution trace with failure point
- No complex backtracking during execution
- Blacklisting handled at planning level

## Decision

Align the hybrid planner execution with the IPyHOP pattern while ensuring compliance with R25W1398085's unified durative action specification.

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

### Phase 3: Ensure R25W1398085 Compliance ✅

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
- Maintained R25W1398085 compliance throughout execution pipeline

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
  - [x] Ensure R25W1398085 compliance

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

### R25W1398085 Compliance ✅

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
- **R25W1398085 Alignment**: Proper action vs command distinction
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

- **R25W1398085**: Unified Durative Action Specification (compliance target)
- **R25W0839F8C**: Restore run_lazy_refineahead from IPyHOP (related pattern)
- **R25W153B3FE**: Hybrid Coordinator V2 Monolithic Refactoring (execution context)

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

## Current Implementation Status

**Status:** Substantially Complete with Quality Issues  
**Last Verified:** 2025-06-27  

### ✅ **Completed Work**

**Core Architecture Implemented:**
- `Plan.SimpleExecutor` module with IPyHOP-style linear execution
- `Plan.Blacklisting` with proper planning/execution separation
- `HybridCoordinatorV2` integration using new executor
- `Plan.Backtracking` simplified to planning-level only
- `@command` attribute support in `AriaCore.ActionAttributes`

**Major Features Working:**
- Linear execution with fail-fast behavior
- Execution trace generation for debugging
- Method vs command blacklisting separation
- Action vs command distinction in execution
- Legacy compatibility maintained

### ⚠️ **Outstanding Issues**

**Code Quality Issues:**
- Multiple compilation warnings (type mismatches, unused variables)
- Type violations in `validate_temporal_consistency/2` return handling
- Unused alias warnings across multiple modules

**Incomplete Implementation:**
- Entity validation has placeholder TODOs in `Plan.SimpleExecutor`
- Domain API integration gaps (`get_action_metadata/2` always returns error)
- Missing comprehensive test coverage for new execution pattern

**Specific Technical Debt:**
```elixir
# In Plan.SimpleExecutor.get_action_metadata/2
{:error, "metadata_not_available"}  # Always fails - needs domain API
```

### 🔧 **Remaining Work**

**Phase 6: Quality and Completeness** ⚠️

**Priority:** HIGH

- [ ] Fix compilation warnings and type mismatches
  - [ ] Resolve `validate_temporal_consistency/2` return type issues
  - [ ] Remove unused variables and aliases
  - [ ] Fix type violations in pattern matching

- [ ] Complete entity validation implementation
  - [ ] Implement `get_action_metadata/2` in domain API
  - [ ] Complete entity registry integration
  - [ ] Add proper capability checking

- [ ] Add comprehensive test coverage
  - [ ] Test IPyHOP execution pattern
  - [ ] Test blacklisting behavior
  - [ ] Test R25W1398085 compliance
  - [ ] Test failure scenarios and execution traces

**Phase 7: Integration Verification** ⚠️

**Priority:** MEDIUM

- [ ] Verify end-to-end execution workflows
- [ ] Test with real domain implementations
- [ ] Validate performance characteristics
- [ ] Ensure backward compatibility

## Success Criteria Updates

### Code Quality ⚠️

- [ ] ~~Simplified execution logic~~ ✅ **DONE**
- [ ] ~~Clear separation of planning vs execution concerns~~ ✅ **DONE**
- [ ] ~~Maintainable and testable code~~ ⚠️ **PARTIAL** - needs test coverage
- [ ] ~~Consistent with IPyHOP reference implementation~~ ✅ **DONE**
- [ ] **NEW:** Clean compilation without warnings
- [ ] **NEW:** Complete entity validation implementation
- [ ] **NEW:** Comprehensive test coverage

## Current Focus

**Immediate Priority:** Fix code quality issues and complete entity validation implementation to achieve true completion status.
