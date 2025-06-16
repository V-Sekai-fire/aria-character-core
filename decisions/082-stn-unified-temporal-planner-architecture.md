# ADR-082: STN-Unified Temporal Planner Architecture

**Status:** Active (June 16, 2025)

> **DISCLAIMER: FICTIONAL GAME SCENARIO**
>
> All references to military operations, hostage rescue scenarios, tactical operations, and related
> activities in this document are purely fictional game planning scenarios for the Aria character
> temporal reasoning system. These are not related to any real military events, actual operations,
> or real-world situations. This is entertainment software development for a fictional character AI
> system.

## Context

The current temporal planning system and STN constraint solving operate as separate subsystems.
This creates complexity in coordinating temporal reasoning across goal decomposition, action
scheduling, and constraint satisfaction. A unified architecture where every planning element is
represented as STN segments would enable:

- **Seamless temporal reasoning:** Actions, methods, and goals share the same temporal
  representation
- **Natural parallelization:** STN segmentation maps directly to independent planning branches  
- **Complexity reduction:** O(k * (n/k)³) scaling through hierarchical decomposition
- **Reentrant execution:** STN operations naturally support plan updates and replanning

## Decision

Implement a unified temporal planner where every action, method, and goal in the reentrant
goal-task planner is represented as STN timeline segments. This creates a hierarchical STN
constraint system that leverages existing boolean operations for plan composition.

## Implementation Plan

### Phase 1: Core STN-Planner Integration

- [ ] Create `AriaEngine.TemporalPlanner.STNAction` module
  - [ ] Action → STN segment conversion with start/end timepoints
  - [ ] Precondition/effect mapping to temporal constraints
  - [ ] Resource usage as duration constraints
- [ ] Create `AriaEngine.TemporalPlanner.STNMethod` module  
  - [ ] Method decomposition to chained STN segments
  - [ ] Subtask → segment boundary constraint mapping
  - [ ] Parallel subtask → independent segment conversion
- [ ] Create `AriaEngine.TemporalPlanner.STNGoal` module
  - [ ] Goal spanning across multiple method STN chains
  - [ ] Cross-goal dependency → inter-chain constraint mapping
  - [ ] Reentrant execution feedback loops

### Phase 2: Hierarchical STN Decomposition

- [ ] Implement hierarchical STN segment management
  - [ ] Parent-child STN segment relationships
  - [ ] Constraint inheritance and propagation
  - [ ] Boundary timepoint coordination
- [ ] Create STN-based plan composition operations
  - [ ] Sequential composition via `chain/1`
  - [ ] Parallel composition via `parallel_join/1`  
  - [ ] Alternative planning via `union/2`
  - [ ] Constraint tightening via `intersection/2`
- [ ] Add STN plan execution monitoring
  - [ ] Real-time constraint value updates
  - [ ] Inconsistency detection and replanning triggers
  - [ ] Progress tracking through constraint satisfaction

### Phase 3: Reentrant Execution Model

- [ ] Implement STN-based replanning system
  - [ ] Plan updates as STN constraint modifications
  - [ ] Goal changes as STN union/intersection operations
  - [ ] Resource conflicts as constraint inconsistency resolution
- [ ] Create temporal feedback loops
  - [ ] Execution results → constraint tightening
  - [ ] Environmental changes → STN restructuring
  - [ ] Performance optimization through constraint learning
- [ ] Add multi-level parallelization
  - [ ] Action-level parallel execution
  - [ ] Method-level concurrent processing
  - [ ] Goal-level independent planning

### Phase 4: Performance Optimization

- [ ] Leverage STN constant work patterns for predictable planning performance
  - [ ] Pre-allocated segment pools for common planning patterns
  - [ ] Constant-time constraint propagation
  - [ ] Deterministic planning latency for real-time scenarios
- [ ] Implement adaptive LOD for planning granularity
  - [ ] High-resolution STNs for immediate actions
  - [ ] Lower-resolution STNs for distant planning horizons
  - [ ] Dynamic LOD adjustment based on execution proximity
- [ ] Add planning performance telemetry
  - [ ] STN operation timing and complexity metrics
  - [ ] Constraint satisfaction convergence tracking
  - [ ] Parallelization efficiency measurement

## Technical Design

### STN Action Representation

```elixir
defmodule AriaEngine.TemporalPlanner.STNAction do
  @type t :: %__MODULE__{
    action_id: String.t(),
    stn_segment: STN.segment(),
    preconditions: [temporal_constraint()],
    effects: [temporal_constraint()],
    resource_requirements: %{resource_id() => duration_constraint()},
    execution_timepoints: {start_timepoint(), end_timepoint()}
  }
end
### Hierarchical Planning Decomposition

```text
Goal STN Chain:
├── Method STN Segment 1
│   ├── Action STN Segment A
│   ├── Action STN Segment B (parallel)
│   └── Action STN Segment C (sequential)
├── Method STN Segment 2
│   └── Subgoal STN Chain (recursive)
└── Method STN Segment 3 (alternative)
```

### Complexity Benefits

- **Traditional HTN:** O(b^d) exponential branching factor
- **STN-Unified:** O(k * (n/k)³) where k = concurrent planning segments
- **Natural parallelization points:** Independent goal branches, parallel actions
- **Constraint propagation locality:** Within-segment solving, boundary merging

## Success Criteria

- [ ] All planning operations representable as STN segment operations
- [ ] Parallel planning execution with measurable speedup (target: 2-4x)
- [ ] Consistent temporal reasoning across action/method/goal levels
- [ ] Reentrant replanning with sub-millisecond constraint updates
- [ ] Integration with existing STN LOD and constant work patterns

## Consequences

### Benefits

- **Unified temporal model:** Single representation for all planning elements
- **Natural parallelization:** STN segmentation enables concurrent planning
- **Reentrant execution:** STN operations support dynamic plan modification
- **Performance predictability:** Constant work patterns eliminate planning variance
- **Compositional reasoning:** Boolean STN operations for plan combination

### Risks

- **Implementation complexity:** Significant architectural changes required
- **Learning curve:** Team needs to understand STN-planning integration
- **Migration effort:** Existing planning code requires substantial refactoring
- **Performance regression risk:** Complex integration might initially reduce performance

### Mitigation Strategies

- **Incremental implementation:** Phase-by-phase rollout with backward compatibility
- **Extensive testing:** Comprehensive test coverage for STN-planning integration
- **Performance monitoring:** Continuous measurement of planning operation timing
- **Fallback mechanisms:** Ability to disable STN integration if needed

## Related ADRs

- **ADR-040**: Temporal Constraint Solver Selection (foundation)
- **ADR-081**: AWS Constant Work Pattern for STN Solving (performance)
- **ADR-034**: Definitive Temporal Planner Architecture (planning basis)

## References

- "Temporal Constraint Networks" by Dechter, Meiri, and Pearl (1991)
- "Hierarchical Task Network Planning" by Erol, Hendler, and Nau (1994)
- "Constraint-Based Scheduling" by Baptiste, Le Pape, and Nuijten (2001)
- [AWS Builders Library - Reliability and Constant Work](https://aws.amazon.com/builders-library/reliability-and-constant-work/)
