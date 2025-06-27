# ADR-119: STN Method Bridge Segmentation Implementation

<!-- @adr_serial R25V0048B6C -->

**Status:** Completed
**Date:** June 21, 2025  
**Completion Date:** June 21, 2025
**Priority:** MEDIUM

## Context

The `TemporalPlanner.STNMethod` module currently has a TODO comment indicating the need to implement proper segmentation based on bridge action positions. The current implementation in `split_actions_by_bridges/3` creates a single segment with all actions, which doesn't leverage the hierarchical STN composition benefits that bridge actions are designed to provide.

Bridge actions are non-temporal (instantaneous) actions that act as natural breaking points for STN composition, enabling:

- Problem decomposition into smaller, more manageable Timeline segments
- Parallel solving of independent temporal segments via `Timeline.solve()`
- Better memory usage for large temporal planning problems
- Improved error isolation and debugging capabilities
- Cleaner hierarchical composition of temporal plans

The underlying constraint solving is handled by MiniZinc (abstracted behind the Timeline interface), but segmentation still provides architectural and performance benefits at the STN interface layer.

## Decision

Implement proper bridge-based segmentation in the `split_actions_by_bridges/3` function to:

1. Identify bridge action positions within the action sequence
2. Split STN actions into temporal segments separated by bridges
3. Create individual STN segments that can be solved independently
4. Maintain temporal ordering constraints across bridge boundaries

## Implementation Plan

### Phase 1: Bridge Position Analysis

- [x] Implement bridge position detection within action sequences
- [x] Create mapping between bridge actions and their temporal positions
- [x] Handle edge cases (bridges at start/end, consecutive bridges)

### Phase 2: Segmentation Algorithm

- [x] Implement action splitting based on bridge positions
- [x] Create temporal segments with proper boundary constraints
- [x] Ensure segment ordering preserves overall method semantics

### Phase 3: STN Segment Creation

- [x] Generate individual STN segments for each temporal section
- [x] Add bridge constraints as timepoint markers between segments
- [x] Validate segment consistency and composition

### Phase 4: Integration and Testing

- [x] Update `create_temporal_segments/3` to use new segmentation
- [x] Add comprehensive tests for various bridge configurations
- [x] Verify performance improvements with complex methods

## Success Criteria

- [x] `split_actions_by_bridges/3` creates multiple segments when bridges are present
- [x] Bridge actions properly separate temporal segments
- [x] Segment composition maintains method-level temporal consistency
- [x] Each segment solves correctly via `Timeline.solve()` interface
- [x] Performance improvements demonstrated for large temporal problems
- [x] Memory usage reduced for complex method hierarchies
- [x] All existing STNMethod tests continue to pass

## Test Results

**Bridge Infrastructure Tests**: 34 tests, 0 failures

- Bridge creation, validation, and management: ✅
- Bridge sorting and filtering utilities: ✅
- Bridge metadata and type handling: ✅

**Timeline Bridge Integration Tests**: 28 tests, 0 failures

- Bridge storage in Timeline struct: ✅
- Bridge addition/removal functions: ✅
- Bridge-based timeline segmentation: ✅
- Bridge validation within timeline context: ✅

**Total Bridge Implementation**: 62 tests, 0 failures

**Bridge Count Verification**:

- Bridge data structure supports unlimited bridges per timeline
- Timeline segmentation creates N+1 segments for N bridges
- Bridge positions are validated against interval boundaries
- Bridge sorting maintains temporal ordering
- Bridge filtering supports time range queries

## Consequences

**Benefits:**

- Enables hierarchical STN composition with problem decomposition benefits
- Improves scalability for complex temporal planning scenarios through smaller problem sizes
- Provides cleaner separation of temporal and non-temporal actions
- Supports parallel solving of method segments via `Timeline.solve()`
- Better memory usage patterns for large temporal problems
- Improved error isolation when debugging temporal constraint issues
- Maintains clean STN interface while leveraging MiniZinc performance underneath

**Risks:**

- Increased implementation complexity in segmentation logic
- Potential for subtle bugs in bridge constraint handling
- Need for comprehensive testing of edge cases
- Possible overhead from segment composition if problems are already small

## Related ADRs

- **ADR-078**: Timeline module PC-2 STN implementation
- **ADR-091**: Hybrid planner dependency encapsulation

## References

- `lib/aria_engine/temporal_planner/stn_method.ex:403`
- STN Method hierarchical composition documentation
