# ADR-119: STN Method Bridge Segmentation Implementation

**Status:** Proposed
**Date:** June 21, 2025  
**Priority:** MEDIUM

## Context

The `TemporalPlanner.STNMethod` module currently has a TODO comment indicating the need to implement proper segmentation based on bridge action positions. The current implementation in `split_actions_by_bridges/3` creates a single segment with all actions, which doesn't leverage the hierarchical STN composition benefits that bridge actions are designed to provide.

Bridge actions are non-temporal (instantaneous) actions that act as natural breaking points for STN composition, enabling:
- O(k * (n/k)³) complexity reduction by solving segments in parallel
- Better temporal consistency across method boundaries
- Cleaner hierarchical composition of temporal plans

## Decision

Implement proper bridge-based segmentation in the `split_actions_by_bridges/3` function to:
1. Identify bridge action positions within the action sequence
2. Split STN actions into temporal segments separated by bridges
3. Create individual STN segments that can be solved independently
4. Maintain temporal ordering constraints across bridge boundaries

## Implementation Plan

### Phase 1: Bridge Position Analysis
- [ ] Implement bridge position detection within action sequences
- [ ] Create mapping between bridge actions and their temporal positions
- [ ] Handle edge cases (bridges at start/end, consecutive bridges)

### Phase 2: Segmentation Algorithm
- [ ] Implement action splitting based on bridge positions
- [ ] Create temporal segments with proper boundary constraints
- [ ] Ensure segment ordering preserves overall method semantics

### Phase 3: STN Segment Creation
- [ ] Generate individual STN segments for each temporal section
- [ ] Add bridge constraints as timepoint markers between segments
- [ ] Validate segment consistency and composition

### Phase 4: Integration and Testing
- [ ] Update `create_temporal_segments/3` to use new segmentation
- [ ] Add comprehensive tests for various bridge configurations
- [ ] Verify performance improvements with complex methods

## Success Criteria

- [ ] `split_actions_by_bridges/3` creates multiple segments when bridges are present
- [ ] Bridge actions properly separate temporal segments
- [ ] Segment composition maintains method-level temporal consistency
- [ ] Performance tests show expected O(k * (n/k)³) complexity reduction
- [ ] All existing STNMethod tests continue to pass

## Consequences

**Benefits:**
- Enables true hierarchical STN composition with complexity reduction
- Improves scalability for complex temporal planning scenarios
- Provides cleaner separation of temporal and non-temporal actions
- Supports parallel solving of method segments

**Risks:**
- Increased implementation complexity in segmentation logic
- Potential for subtle bugs in bridge constraint handling
- Need for comprehensive testing of edge cases

## Related ADRs

- **ADR-078**: Timeline module PC-2 STN implementation
- **ADR-091**: Hybrid planner dependency encapsulation

## References

- `lib/aria_engine/temporal_planner/stn_method.ex:403`
- STN Method hierarchical composition documentation
