# R25W137069A: Extract Timeline from Temporal Planner

<!-- @adr_serial R25W137069A -->

**Status:** Active
**Date:** 2025-06-24  
**Priority:** HIGH

## Context

The `aria_temporal_planner` app contains comprehensive timeline functionality that should be extracted into a dedicated `aria_timeline` app. This extraction will:

1. **Improve modularity** - Timeline functionality can be used independently of temporal planning
2. **Reduce coupling** - Other apps can depend on timeline without pulling in planning logic
3. **Enable reuse** - Timeline system can be used across multiple applications
4. **Clarify responsibilities** - Separate timeline management from planning algorithms

## Current Timeline Components in aria_temporal_planner

### Core Timeline Modules

- `Timeline` - Main timeline interface with interval management and STN integration
- `Timeline.Interval` - Temporal interval representation with Allen's algebra
- `Timeline.Bridge` - Temporal relations classification and STN constraint generation
- `Timeline.AgentEntity` - Agent vs entity distinction for temporal participants
- `TimelineGraph` - Entity timeline graph architecture with LOD management

### Supporting Modules

- `Timeline.Internal.STN` - Simple Temporal Network implementation
- `Timeline.Internal.STN.Core` - Core STN operations
- `Timeline.Internal.STN.Operations` - STN set operations
- `Timeline.Internal.STN.Units` - Time unit conversion and LOD management
- `Timeline.Internal.STN.MiniZincSolver` - MiniZinc integration (to be moved to aria_minizinc_stn)

### Timeline Utilities

- `Timeline.AllenRelations` - Allen's interval algebra implementation
- `Timeline.IntervalOperations` - Interval manipulation utilities
- `Timeline.BridgeOperations` - Bridge management operations
- `Timeline.TimeConverter` - Time format conversion utilities
- `Timeline.TimelineBuilder` - Timeline construction utilities
- `Timeline.TimelineSegmenter` - Timeline segmentation logic

### Agent/Entity Management

- `Timeline.AgentEntity.*` - Complete agent/entity management subsystem
- `TimelineGraph.*` - Entity timeline graph with LOD and scheduling

### Test Coverage

- Comprehensive test suite covering all timeline functionality
- Integration tests for STN solving
- Bridge validation tests
- Agent/entity management tests

## Decision

Extract timeline functionality into a new `aria_timeline` app with the following structure:

```
apps/aria_timeline/
├── lib/
│   ├── timeline.ex                    # Main Timeline module
│   ├── timeline_graph.ex              # TimelineGraph module
│   ├── timeline/
│   │   ├── interval.ex                # Interval representation
│   │   ├── bridge.ex                  # Temporal relations bridge
│   │   ├── agent_entity.ex            # Agent/entity distinction
│   │   ├── allen_relations.ex         # Allen's algebra
│   │   ├── interval_operations.ex     # Interval utilities
│   │   ├── bridge_operations.ex       # Bridge utilities
│   │   ├── time_converter.ex          # Time conversion
│   │   ├── timeline_builder.ex        # Timeline construction
│   │   ├── timeline_segmenter.ex      # Timeline segmentation
│   │   ├── agent_entity/              # Agent/entity subsystem
│   │   │   ├── agent_management.ex
│   │   │   ├── entity_management.ex
│   │   │   ├── capability_management.ex
│   │   │   ├── state_transitions.ex
│   │   │   ├── property_management.ex
│   │   │   ├── ownership_management.ex
│   │   │   └── validation.ex
│   │   └── internal/
│   │       ├── stn.ex                 # STN interface
│   │       └── stn/
│   │           ├── core.ex            # Core STN operations
│   │           ├── operations.ex      # STN set operations
│   │           └── units.ex           # Time units and LOD
│   └── timeline_graph/
│       ├── entity_manager.ex          # Entity management
│       ├── lod_manager.ex             # Level of Detail management
│       ├── scheduler.ex               # Scheduling operations
│       ├── environmental_processes.ex # Environmental effects
│       └── time_converter.ex          # Time conversion utilities
├── test/
│   ├── timeline_test.exs
│   ├── timeline_graph_test.exs
│   └── timeline/                      # Complete test migration
└── decisions/                         # Timeline-specific ADRs
```

## Implementation Plan

### Phase 1: Create aria_timeline App Structure ✅ COMPLETED

- [x] Create new `apps/aria_timeline` directory
- [x] Set up `mix.exs` with appropriate dependencies
- [x] Create basic directory structure
- [x] Set up `.formatter.exs` and other config files

### Phase 2: Move Core Timeline Modules ✅ COMPLETED

- [x] Move `Timeline` module to `apps/aria_timeline/lib/timeline.ex`
- [x] Move `TimelineGraph` module to `apps/aria_timeline/lib/timeline_graph.ex`
- [x] Move `Timeline.Interval` to `apps/aria_timeline/lib/timeline/interval.ex`
- [x] Move `Timeline.Bridge` to `apps/aria_timeline/lib/timeline/bridge.ex`
- [x] Move `Timeline.AgentEntity` to `apps/aria_timeline/lib/timeline/agent_entity.ex`

### Phase 3: Move Supporting Modules ✅ COMPLETED

- [x] Move `Timeline.Internal.STN` and submodules (excluding MiniZincSolver)
- [x] Move `Timeline.AllenRelations` to `apps/aria_timeline/lib/timeline/allen_relations.ex`
- [x] Move `Timeline.IntervalOperations` to `apps/aria_timeline/lib/timeline/interval_operations.ex`
- [x] Move `Timeline.BridgeOperations` to `apps/aria_timeline/lib/timeline/bridge_operations.ex`
- [x] Move utility modules (TimeConverter, TimelineBuilder, TimelineSegmenter)

### Phase 4: Move Agent/Entity Management ✅ COMPLETED

- [x] Move complete `Timeline.AgentEntity.*` subsystem
- [x] Move complete `TimelineGraph.*` subsystem
- [x] Ensure all agent/entity functionality is preserved

### Phase 5: Move Test Suite ✅ COMPLETED

- [x] Move all timeline-related tests to `apps/aria_timeline/test/`
- [x] Remove duplicate timeline tests from `apps/aria_temporal_planner/test/`
- [x] Remove timeline_test.exs and timeline_graph_test.exs from temporal planner
- [x] Remove entire timeline/ test directory from temporal planner
- [x] Eliminate test duplication between apps
- [x] Verify test coverage is maintained

### Phase 6: Update Dependencies ✅ COMPLETED

- [x] Update `aria_temporal_planner/mix.exs` to depend on `aria_timeline`
- [x] **CRITICAL**: Remove timeline modules from `aria_temporal_planner`
- [x] Update import statements across the codebase
- [ ] Update other apps that use timeline functionality (future work)

### Phase 7: Handle MiniZinc Integration ✅ COMPLETED

- [x] **CRITICAL**: Remove MiniZincSolver from `aria_temporal_planner`
- [x] Ensure STN solving works through aria_minizinc_stn dependency
- [x] Verify temporal planner compiles with new dependencies

### Phase 8: Documentation and ADR Migration

- [ ] Move timeline-specific ADRs to `apps/aria_timeline/decisions/`
- [ ] Update README files
- [ ] Update module documentation
- [ ] Create migration guide for external users

## Current State Analysis

**✅ Successfully Extracted to aria_timeline:**

- All core timeline modules and functionality
- Complete agent/entity management subsystem
- All timeline graph components
- Comprehensive test suite
- Internal STN implementation

**✅ Successfully Removed from aria_temporal_planner:**

- All duplicate timeline modules removed
- MiniZincSolver removed (functionality available via aria_minizinc_stn)
- Temporal planner now properly depends on aria_timeline
- No timeline code duplication remains

**✅ CRITICAL ISSUE RESOLVED:**
The timeline module duplication has been eliminated. The `aria_temporal_planner` now correctly uses `aria_timeline` as a dependency without any local timeline code.

## Immediate Next Steps Required

### Step 1: Update aria_temporal_planner Dependencies

1. Add `aria_timeline` dependency to `apps/aria_temporal_planner/mix.exs`
2. Add `aria_minizinc_stn` dependency to replace MiniZincSolver functionality

### Step 2: Remove Duplicate Timeline Modules

**Files to be removed from `apps/aria_temporal_planner/lib/`:**

- `timeline.ex`
- `timeline_graph.ex`
- `timeline/` (entire directory and all contents)
- `timeline_graph/` (entire directory and all contents)

### Step 3: Update Import Statements

Update all files in `aria_temporal_planner` that import timeline modules to use the new `aria_timeline` app modules.

### Step 4: Handle MiniZinc Integration

- Remove `timeline/internal/stn/minizinc_solver.ex` from temporal planner
- Update any references to use `aria_minizinc_stn` instead

### Step 5: Test and Verify

- Run full test suite to ensure no functionality is broken
- Verify that `aria_temporal_planner` works correctly with `aria_timeline` dependency
- Confirm no timeline code remains in `aria_temporal_planner`

## Dependencies

### aria_timeline will depend on

- `aria_engine_core` - For AriaEngine.State integration
- `aria_minizinc_stn` - For STN solving functionality
- `jason` - For JSON serialization
- `libgraph` - For graph operations

### Apps that will depend on aria_timeline

- `aria_temporal_planner` - For timeline functionality
- `aria_hybrid_planner` - For timeline integration
- `aria_scheduler` - For timeline-based scheduling
- Any other apps using timeline functionality

## Success Criteria

- [ ] All timeline functionality extracted to `aria_timeline` app
- [ ] All tests pass in new location
- [ ] `aria_temporal_planner` successfully uses `aria_timeline` as dependency
- [ ] No timeline code remains in `aria_temporal_planner`
- [ ] Documentation updated and migration guide created
- [ ] All existing functionality preserved
- [ ] Clean separation between timeline and planning concerns

## Risks and Mitigation

### Risk: Breaking Changes

- **Mitigation:** Maintain exact API compatibility during extraction
- **Mitigation:** Comprehensive testing at each phase

### Risk: Circular Dependencies

- **Mitigation:** Careful dependency analysis before extraction
- **Mitigation:** Use of dependency injection where needed

### Risk: Test Failures

- **Mitigation:** Move tests incrementally with modules
- **Mitigation:** Run full test suite after each phase

### Risk: Lost Functionality

- **Mitigation:** Systematic verification of all moved modules
- **Mitigation:** Comparison testing between old and new implementations

## Related ADRs

- **R25W136157D**: Extract MiniZinc STN Solver from Temporal Planner
- **R25W135339D**: Modular MiniZinc Architecture Refactoring
- **R25W0389D35**: Timeline Module PC-2 STN Implementation
- **ADR-046**: Interval Notation Usability (agent vs entity)
- **R25W1108E80**: Critical Zero Duration Contract Violation

## Notes

This extraction is part of the broader modularization effort to create focused, reusable components. The timeline system is mature and well-tested, making it an ideal candidate for extraction into a dedicated app.

The extraction will improve the overall architecture by:

1. Reducing the size and complexity of `aria_temporal_planner`
2. Making timeline functionality available to other apps
3. Creating clearer boundaries between different system concerns
4. Enabling independent development and testing of timeline features
