# ADR-094: Fix KHR Interactivity Node Library Planner Test Architecture

<!-- @adr_serial R25W051BA69 -->

**Status:** Obsolete - KHR System Deleted  
**Date:** 2025-06-18  
**Deletion Date:** 2025-06-18  
**Priority:** ~~HIGH~~ N/A

## Obsolescence Reason

This ADR is now obsolete as the entire KHR_interactivity system has been deleted from the project. The KHR node library, domain implementation, tests, and all related infrastructure have been removed. This ADR is preserved for historical reference only.

## Context

The KHR Interactivity node library planner tests had fundamental architectural issues that prevented proper testing of the planned execution flow:

### Architectural Problems (Resolved)

1. **Test Isolation Issues**: GLTF scene mock was shared across all tests in setup block, causing test interference and preventing parallel execution
2. **API Layer Confusion**: Tests mixed direct StateV2 fact checking with GLTF scene execution, creating unclear boundaries
3. **Broken Execution Flow**: Tests used manual `execute_plan()` helper instead of proper `run_lazy_refineahead()` execution
4. **Missing 4-Layer Architecture**:
   - Domain layer: KHR actions ✅
   - Plan layer: Planning logic ✅  
   - Planner layer: HTN planner ✅
   - GLTF scene mock: Execution target ❌ (was not properly integrated)

### Root Cause (Resolved)

The failing assertion `StateV2.get_fact(result_state, 0, "value"), 2.718281828459045` attempted to check raw StateV2 facts instead of GLTF scene state, bypassing the proper execution architecture.

## Decision

Implemented proper 4-layer test architecture with per-test GLTF scene isolation:

1. **Independent Scene Mocks**: Each test creates its own isolated GLTF scene
2. **Proper Execution Flow**: Use `PlannerAdapter.run_lazy_refineahead()` for real execution
3. **Scene State Validation**: Check results via `GLTFSceneMock.get_node_property()`
4. **KHR Action Integration**: Ensure actions work through GLTF scene mock, not direct StateV2

## Implementation Completed

### Phase 1: Test Isolation ✅

- [x] Remove shared GLTF scene setup from test setup block
- [x] Create per-test scene initialization pattern
- [x] Update all test cases to use isolated scenes
- [x] Verify tests can run in parallel without interference

### Phase 2: Execution Flow Fix ✅

- [x] Replace manual `execute_plan()` helper with `PlannerAdapter.run_lazy_refineahead()`
- [x] Update test execution pattern to use proper planning → execution flow
- [x] Add proper error handling for execution failures
- [x] Verify plans are actually executed through the planner system

### Phase 3: State Validation Fix ✅

- [x] Replace `StateV2.get_fact()` assertions with `GLTFSceneMock.get_node_property()`
- [x] Update all test assertions to check GLTF scene state
- [x] Ensure node IDs are properly mapped between planning and execution
- [x] Add validation that scene state reflects expected node values

### Phase 4: KHR Action Integration ✅

- [x] Update KHR math actions to work through GLTF scene mock
- [x] Modify `math_e()`, `math_pi()`, etc. to use `GLTFSceneMock.set_node_property()`
- [x] Ensure action execution updates scene graph correctly
- [x] Add task method integration with scene mock

### Phase 5: Architecture Verification ✅

- [x] Add comprehensive integration tests for 4-layer flow
- [x] Verify planner → execution → scene → validation chain
- [x] Add debug logging to trace execution through layers
- [x] Document proper test patterns for future KHR node tests

## Architectural Achievements

**✅ ALL ARCHITECTURAL GOALS COMPLETED (June 18, 2025)**

1. **Test Isolation**: Each test creates independent domain and state (no shared GLTF scene)
2. **Proper Execution Flow**: Tests use `PlannerAdapter.run_lazy_refineahead()` correctly
3. **Scene State Validation**: All assertions use `GLTFSceneMock.get_node_property()`
4. **4-Layer Architecture**: Proper separation between planning, execution, and scene state
5. **Domain Registration**: Verified working (22 actions, 44 task methods)
6. **Direct Action Execution**: Confirmed working through architectural validation test

## Success Criteria ✅

1. **Test Isolation**: ✅ Tests run independently without shared state interference
2. **Proper Execution**: ✅ Tests use `run_lazy_refineahead()` for actual plan execution
3. **Scene Validation**: ✅ All assertions check GLTF scene state via mock interface
4. **Architectural Validation**: ✅ Original failing assertion pattern now works through proper scene validation
5. **Parallel Safety**: ✅ Tests can run in parallel without order dependencies
6. **4-Layer Separation**: ✅ Clear boundaries between planning, execution, and scene state

## Consequences

### Positive

- **Test Reliability**: Eliminates test interference and flaky behavior
- **Architectural Clarity**: Clear separation between planning, execution, and scene state
- **Future Scalability**: Proper pattern for testing additional KHR nodes
- **Debugging Capability**: Clear execution flow makes issues easier to trace

### Risks

- **Implementation Complexity**: Requires changes across multiple test files and KHR actions
- **Regression Potential**: Changes to execution flow could break existing functionality
- **Performance Impact**: Per-test scene creation may slow down test execution

## Related ADRs

- **ADR-092**: AST to GLTF KHR_interactivity Translation (architectural foundation)
- **ADR-093**: KHR_interactivity Systematic Verification Plan (testing strategy)
- **ADR-091**: Hybrid Planner Dependency Encapsulation (execution layer)
- **ADR-095**: Fix KHR Interactivity Planner Goal Processing Pipeline (ongoing planner integration work)

## Notes

This ADR successfully resolved the fundamental architectural mismatch where the planner worked with StateV2 facts but `run_lazy_refineahead` needed to send actions to the GLTF scene graph execution target. The implementation established proper 4-layer architecture with clear boundaries between planning and execution.

**Architectural scope completed.** Remaining planner integration issues (goal → method resolution) are addressed in ADR-095.
