# R25W052DE7D: Fix KHR Interactivity Planner Goal Processing Pipeline

<!-- @adr_serial R25W052DE7D -->

**Status:** Obsolete - KHR System Deleted  
**Date:** 2025-06-18  
**Deletion Date:** 2025-06-18  
**Priority:** ~~HIGH~~ N/A

## Obsolescence Reason

This ADR is now obsolete as the entire KHR_interactivity system has been deleted from the project. The KHR node library, domain implementation, tests, and all related infrastructure have been removed. This ADR is preserved for historical reference only.

## Context

Following the successful architectural improvements in R25W051BA69, the KHR Interactivity planner tests now have proper 4-layer architecture but are failing due to planner goal processing pipeline issues.

### Current State

**Test Results**: 6 tests, 1 passing, 5 failing

- ✅ Direct action execution works (architectural validation confirmed)
- ❌ Planner-based tests fail with "No methods found for goal: ok"

### Root Cause

The HTN planner cannot find methods for KHR goals like `{"math/pi", [1]}`. The domain registration shows 22 actions and 44 task methods are available, but the planner's goal → method resolution pipeline is not connecting KHR goals to their corresponding task methods.

### Specific Error Pattern

```
** (RuntimeError) No methods found for goal: ok
```

This suggests the planner is receiving malformed goals or the goal format doesn't match the expected task method signatures in the KHR domain.

### Domain Registration Status

- **Actions**: 22 KHR math actions registered correctly
- **Task Methods**: 44 task methods available
- **Direct Execution**: Works perfectly (proves actions and domain are functional)
- **Planner Integration**: Failing at goal → method resolution step

## Decision

Investigate and fix the planner goal processing pipeline to enable proper HTN planning for KHR Interactivity nodes.

## Implementation Plan

### Phase 1: Goal Format Investigation (PRIORITY: HIGH)

- [x] Analyze the exact goal format being passed to the planner
- [x] Compare goal format with task method signatures in KHR domain
- [x] Identify format mismatch between test goals and domain expectations
- [x] Document expected vs actual goal structure

### Phase 2: Method Resolution Debugging (PRIORITY: HIGH)

- [x] Add debug logging to planner method resolution process
- [x] Trace goal → method matching logic for KHR domain
- [x] Identify why "No methods found for goal: ok" occurs
- [x] Verify task method naming conventions match planner expectations

### Phase 3: Goal Processing Fix (PRIORITY: HIGH)

- [x] Fix goal format to match task method signatures
- [x] Update test goal construction to use correct format
- [x] Ensure goal parameters align with method parameter expectations
- [x] Test goal → method resolution with corrected format

### Phase 4: Integration Testing (PRIORITY: MEDIUM)

- [ ] Verify all 5 failing tests now pass with corrected goal processing
- [ ] Test complete planner → execution → validation flow
- [ ] Ensure no regression in direct action execution
- [ ] Validate scene state updates work through full pipeline

### Phase 5: Documentation and Patterns (PRIORITY: LOW)

- [ ] Document correct goal format for KHR node testing
- [ ] Create examples of proper goal construction
- [ ] Update test patterns for future KHR node additions
- [ ] Add debugging guides for similar planner integration issues

## Technical Investigation Areas

### Goal Format Analysis

- **Current format**: `{"math/pi", [1]}` (suspected format)
- **Expected format**: Unknown - needs investigation
- **Parameter mapping**: How goal parameters map to task method arguments
- **Domain-specific conventions**: KHR domain naming and structure requirements

### Method Resolution Pipeline

- **Goal parsing**: How planner parses incoming goals
- **Method matching**: Algorithm for finding compatible task methods
- **Parameter validation**: How goal parameters are validated against method signatures
- **Error handling**: Why "No methods found" instead of more specific error

### Integration Points

- **Test → Planner**: How tests construct and pass goals to planner
- **Planner → Domain**: How planner queries domain for available methods
- **Domain → Methods**: How domain returns method information to planner
- **Method → Execution**: How selected methods are executed

## Success Criteria

1. **Goal Resolution**: Planner successfully finds methods for KHR goals like `{"math/pi", [1]}`
2. **Test Passing**: All 6 KHR planner tests pass (currently 1/6 passing)
3. **Pipeline Integrity**: Complete planner → execution → scene → validation flow works
4. **Error Clarity**: Clear error messages when goal → method resolution fails
5. **Documentation**: Proper patterns documented for future KHR node testing

## Consequences

### Positive

- **Complete KHR Testing**: Full planner integration enables comprehensive KHR node testing
- **Pipeline Validation**: Proves end-to-end planning and execution works for KHR nodes
- **Future Scalability**: Establishes working patterns for additional KHR node types
- **Debugging Capability**: Clear understanding of goal → method resolution process

### Risks

- **Complex Debugging**: Planner internals may be difficult to trace and debug
- **Format Dependencies**: Goal format changes might affect other domain types
- **Integration Complexity**: Multiple systems (planner, domain, execution) must align
- **Regression Potential**: Fixes might break existing non-KHR planning functionality

## Related ADRs

- **R25W051BA69**: Fix KHR Interactivity Planner Test Architecture (architectural foundation)
- **R25W0498AC9**: AST to GLTF KHR_interactivity Translation (domain implementation)
- **R25W0503071**: KHR_interactivity Systematic Verification Plan (testing strategy)
- **R25W0489307**: Hybrid Planner Dependency Encapsulation (planner system)

## Notes

This ADR focuses specifically on the planner integration issues identified after the architectural improvements in R25W051BA69. The architectural foundation is solid - the issue is in the goal processing pipeline that connects test goals to domain task methods.

**Key insight**: Direct action execution works perfectly, proving the domain and actions are correctly implemented. The failure is specifically in the planner's ability to resolve goals to methods, not in the underlying KHR functionality.

## Completion Summary

**Root Cause Identified**: Task methods in `math_constants.ex` were returning malformed tuples `[{:ok, state, []}]` instead of proper subtask lists.

**Solution Applied**:

- Fixed task methods to return correct format: `[{"khr_math_pi", [node_index]}]`
- Updated debug script to use correct StateV2 fact ordering (subject-predicate-fact)

**Result**: Planning now succeeds for KHR math constant nodes like `{"math/pi", [1]}`.

**Files Modified**:

- `lib/aria_engine/node_library/khr_interactivity/math_constants.ex` - Fixed task method return format
- `debug_tuple_conversion.exs` - Corrected StateV2 fact pattern matching

**Verification**: Debug script confirms planning pipeline now works correctly with proper task decomposition: `{"math/pi", [1]}` → `{"khr_math_pi", [1]}`.
