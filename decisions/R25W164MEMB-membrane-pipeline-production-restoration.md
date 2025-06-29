# R25W164MEMB: Membrane Pipeline Production Restoration

**Status:** Active  
**Date:** June 28, 2025  
**Priority:** HIGH

## Context

The aria_membrane_pipeline currently uses mock implementations instead of the real Membrane Framework. This was identified in R25W070D1AF as needing restoration to a full production pipeline. The current state includes:

- Mock implementations in `lib/membrane_mock/`
- Incomplete pipeline topology
- Missing production elements (PlanFilter, ResponseFilter, ScheduleFilter)
- No real Membrane Framework integration

## Decision

Implement a comprehensive restoration of the membrane pipeline to use the real Membrane Framework with full production topology as outlined in the implementation plan.

## Implementation Plan

### Phase 1: Dependencies and Infrastructure ⚡️ HIGH PRIORITY

**File**: `apps/aria_membrane_pipeline/mix.exs`

**Missing/Required**:

- [x] Add `membrane_core ~> 1.0` dependency
- [x] Add `membrane_file_plugin ~> 0.17` (if needed for file operations)
- [x] Add `membrane_hackney_plugin ~> 0.11` (if needed for HTTP)
- [x] Remove `:mox` dependency conflict (no longer needed)
- [x] Run `mix deps.get` to resolve dependencies

**Implementation Patterns Needed**:

- [x] Clean dependency resolution
- [x] Remove mock infrastructure completely

### Phase 2: Format Definitions 🔧 HIGH PRIORITY

**Files**: `lib/membrane/format/` directory

**Missing/Required**:

- [x] Create `mcp_request.ex` - Define MCPRequest format
- [x] Create `planning_params.ex` - Define PlanningParams format  
- [x] Create `planning_result.ex` - Define PlanningResult format
- [x] Create `mcp_response.ex` - Define MCPResponse format

**Implementation Patterns Needed**:

- [x] Membrane format struct definitions
- [x] Type specifications for each format

### Phase 3: Pipeline Elements Migration 🔧 HIGH PRIORITY

**Files**:

- `lib/membrane/mcp_source.ex`
- `lib/membrane/planner_filter.ex`
- `lib/membrane/mcp_sink.ex`

**Missing/Required**:

- [ ] Convert MCPSource to real Membrane.Source
- [ ] Convert PlannerFilter to real Membrane.Filter  
- [ ] Convert MCPSink to real Membrane.Sink
- [ ] Implement proper `handle_demand/4` and `handle_playing/2`
- [ ] Add real format specifications and flow control
- [ ] Keep existing business logic intact

**Implementation Patterns Needed**:

- [ ] Real Membrane behaviour implementations
- [ ] Proper pad definitions and buffer handling
- [ ] Flow control mechanisms

### Phase 4: Missing Production Elements 🔧 HIGH PRIORITY

**Files**:

- `lib/membrane/plan_filter.ex` (NEW)
- `lib/membrane/response_filter.ex` (NEW)
- `lib/membrane/schedule_filter.ex` (NEW)

**Missing/Required**:

- [ ] Implement PlanFilter (MCPRequest → PlanningParams)
- [ ] Implement ResponseFilter (PlanningResult → MCPResponse)
- [ ] Implement ScheduleFilter (schedule_activities specific transformations)
- [ ] Integrate with existing `AriaEngine.HybridPlanner.PlanTransformer`
- [ ] Add comprehensive error handling and telemetry

**Implementation Patterns Needed**:

- [ ] Membrane.Filter behaviour implementations
- [ ] Data transformation logic
- [ ] Error recovery patterns

### Phase 5: Pipeline Manager 📋 MEDIUM PRIORITY

**File**: `lib/membrane/pipeline_manager.ex` (NEW)

**Missing/Required**:

- [ ] Create production pipeline manager
- [ ] Support testing topology: `MCPSource → ScheduleFilter → EchoFilter → ResponseFilter → MCPSink`
- [ ] Support production topology: `MCPSource → PlanFilter → PlannerFilter → ResponseFilter → MCPSink`
- [ ] Dynamic pipeline switching based on configuration
- [ ] Supervision tree integration

**Implementation Patterns Needed**:

- [ ] Membrane.Pipeline behaviour
- [ ] Dynamic topology management
- [ ] Configuration-based pipeline selection

### Phase 6: Integration and Testing 🔧 MEDIUM PRIORITY

**Files**: Test suite updates

**Missing/Required**:

- [ ] Convert `test/membrane_mock_test.exs` to use real Membrane testing
- [ ] Add integration tests for full pipeline
- [ ] Performance benchmarking against existing MCP interface
- [ ] Error recovery testing
- [ ] End-to-end planning pipeline tests

**Implementation Patterns Needed**:

- [ ] Membrane testing patterns
- [ ] Integration test structure
- [ ] Performance validation

### Phase 7: Configuration and Documentation 📋 LOW PRIORITY

**Files**: Configuration and documentation

**Missing/Required**:

- [ ] Add pipeline configuration to application config
- [ ] Environment-specific pipeline selection
- [ ] Telemetry and monitoring setup
- [ ] Update README with Membrane Framework usage
- [ ] API documentation for pipeline elements
- [ ] Migration guide from mock to production

## Implementation Strategy

### Step 1: Dependency Resolution

1. Fix mix.exs dependency conflicts
2. Add real Membrane Framework dependencies
3. Remove mock infrastructure completely

### Step 2: Format Foundation

1. Create all format definitions first
2. Establish type contracts between pipeline elements
3. Validate format compatibility

### Step 3: Element Migration

1. Convert existing elements to real Membrane one by one
2. Maintain existing business logic
3. Add proper flow control and error handling

### Step 4: Missing Elements Implementation

1. Implement PlanFilter, ResponseFilter, ScheduleFilter
2. Integrate with existing AriaEngine components
3. Add comprehensive testing

### Step 5: Pipeline Integration

1. Create pipeline manager with dynamic topology support
2. Add configuration and monitoring
3. Performance validation and documentation

### Current Focus: Phase 1 - Dependencies and Infrastructure

Starting with dependency resolution because all subsequent work depends on having the real Membrane Framework available. The mock infrastructure must be completely removed to avoid conflicts.

## Success Criteria

- [ ] All mock implementations deleted
- [ ] Real Membrane Framework dependencies added and working
- [ ] Full production pipeline topology implemented
- [ ] All existing tests converted and passing
- [ ] New integration tests for production pipeline
- [ ] Performance matches or exceeds existing MCP interface
- [ ] Comprehensive error handling and telemetry
- [ ] Documentation updated for Membrane usage

## Related ADRs

- **R25W070D1AF**: Membrane Planning Pipeline Integration (parent ADR)
- **R25W071D281**: Fix Membrane Pipeline Implementation

## Timeline

**Target completion:** 7 days (July 5, 2025)

**Phase breakdown:**

- Phase 1-2: Days 1-2 (Dependencies + Formats)
- Phase 3-4: Days 2-4 (Element Migration + New Elements)  
- Phase 5-6: Days 4-6 (Pipeline Manager + Testing)
- Phase 7: Days 6-7 (Configuration + Documentation)
