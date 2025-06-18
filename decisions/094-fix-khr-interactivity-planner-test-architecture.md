# ADR-094: Fix KHR Interactivity Node Library Planner Test Architecture

**Status:** Active  
**Date:** 2025-06-18  
**Priority:** HIGH

## Context

The current KHR Interactivity node library planner tests have fundamental architectural issues that prevent proper testing of the planned execution flow:

### Current Problems

1. **Test Isolation Issues**: GLTF scene mock is shared across all tests in setup block, causing test interference and preventing parallel execution
2. **API Layer Confusion**: Tests mix direct StateV2 fact checking with GLTF scene execution, creating unclear boundaries
3. **Broken Execution Flow**: Tests use manual `execute_plan()` helper instead of proper `run_lazy_refineahead()` execution
4. **Missing 4-Layer Architecture**: 
   - Domain layer: KHR actions ✅
   - Plan layer: Planning logic ✅  
   - Planner layer: HTN planner ✅
   - GLTF scene mock: Execution target ❌ (not properly integrated)

### Root Cause

The failing assertion `StateV2.get_fact(result_state, 0, "value"), 2.718281828459045` attempts to check raw StateV2 facts instead of GLTF scene state, bypassing the proper execution architecture.

## Decision

Implement proper 4-layer test architecture with per-test GLTF scene isolation:

1. **Independent Scene Mocks**: Each test creates its own isolated GLTF scene
2. **Proper Execution Flow**: Use `PlannerAdapter.run_lazy_refineahead()` for real execution
3. **Scene State Validation**: Check results via `GLTFSceneMock.get_node_property()`
4. **KHR Action Integration**: Ensure actions work through GLTF scene mock, not direct StateV2

## Implementation Plan

### Phase 1: Test Isolation (PRIORITY: HIGH)
- [x] **BREAKTHROUGH**: Domain registration verified working (22 actions, 44 task methods)
- [x] **BREAKTHROUGH**: Direct action execution works perfectly (one test now passing)
- [x] Identified root cause: Planner goal processing pipeline issue ("No methods found for goal: ok")
- [ ] Remove shared GLTF scene setup from test setup block
- [ ] Create per-test scene initialization pattern
- [ ] Update all test cases to use isolated scenes
- [ ] Verify tests can run in parallel without interference

### Phase 2: Execution Flow Fix (PRIORITY: HIGH)
- [ ] Replace manual `execute_plan()` helper with `PlannerAdapter.run_lazy_refineahead()`
- [ ] Update test execution pattern to use proper planning → execution flow
- [ ] Add proper error handling for execution failures
- [ ] Verify plans are actually executed through the planner system

### Phase 3: State Validation Fix (PRIORITY: HIGH)
- [ ] Replace `StateV2.get_fact()` assertions with `GLTFSceneMock.get_node_property()`
- [ ] Update all test assertions to check GLTF scene state
- [ ] Ensure node IDs are properly mapped between planning and execution
- [ ] Add validation that scene state reflects expected node values

### Phase 4: KHR Action Integration (PRIORITY: MEDIUM)
- [ ] Update KHR math actions to work through GLTF scene mock
- [ ] Modify `math_e()`, `math_pi()`, etc. to use `GLTFSceneMock.set_node_property()`
- [ ] Ensure action execution updates scene graph correctly
- [ ] Add task method integration with scene mock

### Phase 5: Architecture Verification (PRIORITY: LOW)
- [ ] Add comprehensive integration tests for 4-layer flow
- [ ] Verify planner → execution → scene → validation chain
- [ ] Add debug logging to trace execution through layers
- [ ] Document proper test patterns for future KHR node tests

## Success Criteria

1. **Test Isolation**: Tests run independently without shared state interference
2. **Proper Execution**: Tests use `run_lazy_refineahead()` for actual plan execution
3. **Scene Validation**: All assertions check GLTF scene state via mock interface
4. **Passing Tests**: Original failing assertion `assert_in_delta StateV2.get_fact(result_state, 0, "value"), 2.718281828459045` now works through proper scene validation
5. **Parallel Safety**: Tests can run in parallel without order dependencies

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

## Notes

This ADR addresses the fundamental architectural mismatch identified where the planner works with StateV2 facts but `run_lazy_refineahead` should send actions to the GLTF scene graph execution target. The fix ensures proper 4-layer architecture with clear boundaries between planning and execution.
