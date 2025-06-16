# ADR-082: Hierarchical STN Temporal Planner

**Status:** Active (June 16, 2025)

> **DISCLAIMER: FICTIONAL GAME SCENARIO**
>
> All references to military operations, hostage rescue scenarios, tactical operations, and related
> activities in this document are purely fictional game planning scenarios for the Aria character
> temporal reasoning system. These are not related to any real military events, actual operations,
> or real-world situations. This is entertainment software development for a fictional character AI
> system.

## Context

The reentrant goal-task planner requires integration with STN temporal constraint solving, but faces
the challenge of mixed temporal and non-temporal actions. Pure temporal actions have measurable
durations that map naturally to STN constraints, while non-temporal actions (decisions,
computations, conditions) create gaps in the temporal timeline.

The hierarchical STN composition approach addresses this by using STN boolean operations to create a
unified temporal planning architecture where non-temporal actions become natural segment boundaries.

## Decision

Implement hierarchical STN composition that unifies temporal and non-temporal planning through:

1. **Temporal Segments**: Groups of connected temporal actions become individual STNs
2. **Non-temporal Bridges**: Instantaneous actions that separate temporal segments
3. **STN Composition**: Use boolean operations (union, intersection, compose) to join segments
4. **Complexity Reduction**: O(k * (n/k)³) parallelization across segments

## Implementation Plan

### Phase 1: Core STN Planning Integration

- [x] Create STNAction module for atomic temporal actions
- [ ] Create STNMethod module for hierarchical method decomposition  
- [ ] Create STNPlanner module for goal-level coordination
- [ ] Implement temporal segment identification and boundaries

### Phase 2: Non-temporal Bridge System

- [ ] Design non-temporal action markers and bridges
- [ ] Implement segment composition with non-temporal gaps
- [ ] Add temporal consistency validation across bridges
- [ ] Create reentrant execution model integration

### Phase 3: Hierarchical Composition

- [ ] Implement parallel segment solving with O(k * (n/k)³) complexity
- [ ] Add cross-segment constraint propagation
- [ ] Create goal-level STN chaining and composition
- [ ] Integrate with existing LOD and Flow adapter systems

### Phase 4: Reentrant Execution

- [ ] Add real-time constraint updates during execution
- [ ] Implement replanning as STN constraint tightening
- [ ] Add goal change handling via STN boolean operations
- [ ] Create resource conflict detection through constraint inconsistency

## Technical Architecture

### Temporal Action Mapping

```elixir
temporal_action -> {start_timepoint, end_timepoint, duration_constraint}
non_temporal_action -> :bridge_marker
```

### STN Segment Composition

```elixir
plan = [
  temporal_segment_1,  # STN with actions A, B, C
  :non_temporal_bridge,  # Decision point
  temporal_segment_2,  # STN with actions D, E, F
  :non_temporal_bridge,  # Computation
  temporal_segment_3   # STN with actions G, H
]
```

### Complexity Benefits

- Traditional HTN: O(b^d) exponential branching
- STN Segmented: O(k * (n/k)³) where k = segments, n = total timepoints
- Natural parallelization at segment boundaries

## Success Criteria

- [ ] Every action and method maps to STN timeline elements
- [ ] Non-temporal actions handled without breaking STN paths
- [ ] Parallel segment solving with demonstrated O(k * (n/k)³) complexity
- [ ] Reentrant execution with real-time constraint updates
- [ ] Integration with existing STN boolean operations
- [ ] Consistent with AWS constant work pattern for production use

## Related ADRs

- **ADR-040**: Temporal Constraint Solver Selection (foundation)
- **ADR-081**: AWS Constant Work Pattern for STN Solving (performance)
- **ADR-034**: Definitive Temporal Planner Architecture (context)

## References

- "Temporal Constraint Networks" by Dechter, Meiri, and Pearl (1991)
- "Hierarchical Task Network Planning" literature
- Existing AriaEngine STN and Flow adapter implementations
