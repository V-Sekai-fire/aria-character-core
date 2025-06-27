# R25W071D281: Fix Membrane Pipeline Implementation and Testing

<!-- @adr_serial R25W071D281 -->

**Status:** Active (Paused)
**Date:** June 20, 2025  
**Priority:** HIGH

## Context

R25W0670D79 successfully established the Membrane Framework pipeline architecture and basic structure for MCP strategy testing. However, the implementation has critical issues that prevent the pipeline from functioning correctly.

### Current State

**Architecture Completed (R25W0670D79):**

- ✅ Membrane dependencies and format definitions
- ✅ Basic pipeline element structure (MCPSource, filters, sinks)
- ✅ Pipeline management framework
- ✅ MCP Tools V2 interface design

**Implementation Issues:**

- ❌ 13 failing membrane tests
- ❌ MCPSource not sending buffers properly
- ❌ Pipeline configuration updates not working
- ❌ Message flow broken between elements
- ❌ PlannerSink incomplete
- ❌ Element communication protocols not working

### Test Failure Analysis

From recent test run:

```
82 tests, 13 failures

Key failures:
- MCPRequest format integration not receiving expected buffer messages
- Pipeline configuration updates not persisting
- Element communication timeouts
- Buffer flow interruptions
```

## Decision

Fix the Membrane pipeline implementation to achieve full functionality and pass all tests. Focus on debugging and completing the core pipeline functionality rather than adding new features.

## Implementation Plan

### Phase 1: MCPSource Buffer Flow Fix ✅ COMPLETED

**File**: `lib/aria_engine/membrane/mcp_source.ex`

**Issues Fixed:**

- [x] MCPSource not sending buffers when receiving MCP requests ✅
- [x] Pipeline configuration messages not updating state properly ✅
- [x] Demand-based flow control not working correctly ✅
- [x] Format compatibility issues between pipeline elements identified ✅
- [x] FormatTransformerFilter integration added to pipeline configurations ✅

**Completed Tasks:**

- [x] Verified `handle_info({:mcp_request, mcp_params}, _ctx, state)` sends buffers correctly ✅
- [x] Fixed `handle_demand` flow control ✅
- [x] Fixed `handle_info({:configure_pipeline, config}, _ctx, state)` state updates ✅
- [x] Verified buffer creation and output pad sending ✅
- [x] **End-to-end test now passes successfully** ✅

### Phase 2: Element Communication Protocol ✅ PARTIALLY COMPLETED

**Files**: All membrane elements

**Issues Fixed:**

- [x] Buffer messages flowing between elements ✅
- [x] Format compatibility between input/output pads ✅
- [x] Flow control and backpressure handling ✅
- [x] Element linking and pad connections ✅

**Completed Tasks:**

- [x] Verified input/output pad format specifications match ✅
- [x] Fixed element linking in pipeline specs ✅
- [x] Ensured proper buffer forwarding in filters ✅
- [x] Tested element-to-element communication ✅
- [x] **PlanFilter updated to use new PlanTransformer format** ✅
- [x] **PlannerFilter disconnected from Scheduler, now uses HybridCoordinatorV2** ✅

**Remaining Issues:**

- ⚠️ Missing PlanTransformer module (warning only)
- ⚠️ Missing HybridCoordinatorV2 module (warning only)
- ⚠️ Missing planning_result.ex format file (warning only)

### Phase 3: Test Infrastructure Alignment

**Files**: `test/aria_engine/membrane/*_test.exs`

**Issues to Fix:**

- [ ] Test expectations not matching actual Membrane behavior
- [ ] Message patterns incorrect for Membrane testing framework
- [ ] Timeout values too short for pipeline processing
- [ ] Test setup not properly initializing pipelines

**Debug Tasks:**

- [ ] Review Membrane testing documentation for correct patterns
- [ ] Adjust test expectations to match actual message flow
- [ ] Increase timeouts for pipeline processing
- [ ] Fix test pipeline initialization

### Phase 4: Complete Missing Implementations

**PlannerSink Implementation:**

- [ ] Complete `handle_buffer` implementation
- [ ] Add HybridCoordinatorV2 integration
- [ ] Implement error handling for planning failures
- [ ] Add telemetry for planning execution

**PipelineManager Fixes:**

- [ ] Fix pipeline creation and lifecycle management
- [ ] Complete dynamic topology configuration
- [ ] Add proper supervision and error recovery
- [ ] Fix status monitoring and metrics

**MCP Tools V2 Integration:**

- [ ] Complete pipeline-based `schedule_activities` implementation
- [ ] Fix element configuration validation
- [ ] Add pipeline management tools
- [ ] Test end-to-end MCP integration

### Phase 5: Performance and Reliability

**Optimization Tasks:**

- [ ] Optimize buffer processing performance
- [ ] Add proper error recovery mechanisms
- [ ] Implement backpressure handling
- [ ] Add comprehensive telemetry

**Reliability Tasks:**

- [ ] Add element failure recovery
- [ ] Implement pipeline health monitoring
- [ ] Add graceful shutdown procedures
- [ ] Test fault tolerance scenarios

## Success Criteria

### Functional Requirements

- [ ] **All Tests Pass**: 0 failing membrane tests
- [ ] **Buffer Flow**: Messages flow correctly through entire pipeline
- [ ] **Configuration Updates**: Pipeline configuration changes work properly
- [ ] **Element Communication**: All elements communicate correctly
- [ ] **End-to-End**: Complete MCP request → response flow works

### Technical Requirements

- [ ] **MCPSource**: Properly sends buffers on MCP requests
- [ ] **Filters**: Transform data correctly between formats
- [ ] **PlannerSink**: Executes planning via HybridCoordinatorV2
- [ ] **MCPSink**: Formats responses correctly
- [ ] **PipelineManager**: Manages pipeline lifecycle properly

### Integration Requirements

- [ ] **MCP Tools**: All MCP tools work with pipeline
- [ ] **Testing**: Comprehensive test coverage with all tests passing
- [ ] **Telemetry**: Proper monitoring and metrics
- [ ] **Documentation**: Updated documentation reflecting working implementation

## Implementation Strategy

### Updated Approach: Focus on STDIO MCP Testing

**Decision**: After implementing format conversion filters and analyzing the complexity of the Membrane pipeline testing approach, we've decided to focus on **stdio MCP in, stdio MCP out** testing strategy instead of complex pipeline validation scripts.

**Rationale**:

- Pipeline configurations now have proper format conversion filters
- STDIO MCP testing provides more direct, reliable testing approach
- Existing `scripts/stdio_mcp_end_to_end_test.exs` already provides effective testing framework
- Reduces complexity while maintaining comprehensive testing coverage

### Debugging Approach

1. **Start with MCPSource**: Fix the most basic element first
2. **Test in Isolation**: Test each element independently before integration
3. **Follow Message Flow**: Trace messages through the entire pipeline
4. **Use Membrane Debugging**: Leverage Membrane's built-in debugging tools
5. **Incremental Testing**: Fix one test at a time
6. **STDIO MCP Testing**: Use stdio MCP approach for end-to-end validation

### Development Process

1. **Fix MCPSource buffer sending**
2. **Verify element-to-element communication**
3. **Complete missing implementations**
4. **Fix all failing tests**
5. **Add comprehensive integration tests using STDIO MCP approach**

## Related ADRs

- **R25W0670D79**: MCP Strategy Testing Interface using Membrane Framework Pipeline (foundation)
- **R25W058D6B9**: Reconnect Scheduler with Hybrid Planner (PlannerSink integration)
- **R25W070D1AF**: Membrane Planning Pipeline Integration (related pipeline work)

## Consequences

### Positive

- **Working Pipeline**: Functional Membrane pipeline for MCP strategy testing
- **Test Coverage**: Comprehensive test suite with all tests passing
- **Reliability**: Robust error handling and fault tolerance
- **Performance**: Optimized pipeline processing
- **Maintainability**: Clean, debugged implementation

### Risks

- **Debugging Complexity**: Membrane pipeline debugging can be challenging
- **Time Investment**: Fixing all issues may take significant time
- **Integration Challenges**: Multiple elements must work together correctly
- **Test Complexity**: Membrane testing patterns may be complex

### Mitigation Strategies

- **Incremental Approach**: Fix one element at a time
- **Membrane Documentation**: Leverage official Membrane testing guides
- **Isolation Testing**: Test elements independently before integration
- **Community Support**: Use Membrane community resources for debugging help

## Timeline

**Week 1**: Phase 1 (MCPSource fixes)
**Week 2**: Phase 2 (Element communication)
**Week 3**: Phase 3 (Test infrastructure)
**Week 4**: Phase 4 (Missing implementations)
**Week 5**: Phase 5 (Performance and reliability)

This ADR focuses on completing the implementation work started in R25W0670D79 and achieving a fully functional Membrane pipeline for MCP strategy testing.
