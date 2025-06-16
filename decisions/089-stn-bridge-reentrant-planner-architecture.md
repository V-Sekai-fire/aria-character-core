# ADR-089: STN Bridge Reentrant Planner Architecture

**Status:** Superseded (June 19, 2025)

**Superseded by:** [ADR-099: STN Bridge Reentrant Planner Architecture](099-stn-bridge-reentrant-planner-architecture.md)

> **DISCLAIMER: FICTIONAL GAME SCENARIO**
>
> All references to military operations, hostage rescue scenarios, tactical operations, and related
> activities in this document are purely fictional game planning scenarios for the Aria character
> temporal reasoning system. These are not related to any real military events, actual operations,
> or real-world situations. This is entertainment software development for a fictional character AI
> system.

## Context

The AriaEngine planner has evolved from a dual-API system (non-reentrant todo lists + reentrant solution trees) to a unified reentrant architecture based on solution trees. The concept of "STN bridges" represents the critical interface between temporal planning (using Simple Temporal Networks) and non-temporal logical planning.

The previous architecture maintained separate temporal and logical planning subsystems, creating coordination complexity and preventing seamless reasoning across different types of constraints and actions.

## Decision

Implement a unified reentrant planner architecture where:

1. **STN Bridges** serve as the interface between temporal constraints (duration, scheduling) and logical constraints (preconditions, effects, goals).

2. **Solution Trees** are the primary data structure for all planning, replacing non-reentrant todo lists entirely.

3. **Temporal and Non-Temporal Planning** are unified through STN bridge composition, where temporal actions map to STN segments and non-temporal actions create logical links between temporal segments.

## STN Bridge Concept

An **STN Bridge** is a compositional unit that connects:

- **Temporal segments** (actions with measurable duration)
- **Logical transitions** (instantaneous state changes)
- **Constraint relationships** (ordering, timing, resource conflicts)

### Real-World Planning Analogy

Consider planning a complex day with both temporal and logical constraints:

#### Temporal Planning Example

```
Morning: [7:00-8:30] Commute to office (90 min duration)
         [8:30-12:00] Morning meetings (3.5 hour duration)
         [12:00-13:00] Lunch break (1 hour duration)
         [13:00-17:00] Afternoon work (4 hour duration)
         [17:00-18:30] Commute home (90 min duration)
```

#### Non-Temporal Planning Example

```
Logical decisions:
- IF morning traffic is heavy, THEN leave 15 minutes early
- IF lunch meeting is scheduled, THEN skip regular lunch break
- IF urgent email arrives, THEN prioritize response over scheduled tasks
```

#### STN Bridge Integration

The STN bridge connects these:

```
STN Segment: [7:00-8:30] Commute
  ↓ (logical bridge)
Condition: Check traffic status
  ↓ (temporal adjustment)
STN Segment: [8:30-12:00] Meetings (may start 8:15 if early departure)
```

## Implementation Architecture

### Core Types (in `planner.ex`)

```elixir
@type stn_bridge :: %{
  temporal_segment: stn_segment() | nil,
  logical_conditions: [condition()],
  effects: [effect()],
  constraints: [constraint()]
}

@type solution_tree :: %{
  root: solution_node(),
  bridges: [stn_bridge()],
  temporal_network: stn_network(),
  logical_state: world_state()
}
```

### Planning Process

1. **Goal Decomposition**: Break complex goals into sub-goals using solution trees
2. **Action Selection**: Choose actions that satisfy preconditions and advance toward goals
3. **STN Bridge Creation**: For each action, create bridge connecting temporal and logical aspects
4. **Constraint Propagation**: Use STN solving for temporal constraints, logical solving for conditions
5. **Solution Validation**: Ensure temporal feasibility and logical consistency

### Example Planning Scenario (Fictional Game Context)

**Goal**: Character must reach extraction point within 45 minutes while avoiding detection

**Temporal Actions** (STN Segments):

- [T+0 to T+5] Equipment check (5 min)
- [T+5 to T+30] Movement to waypoint (25 min)
- [T+30 to T+45] Final approach (15 min)

**Non-Temporal Actions** (Logical Bridges):

- IF detection_risk > threshold THEN switch_to_stealth_route
- IF equipment_check FAILS THEN abort_mission
- IF waypoint_compromised THEN recalculate_path

**STN Bridge Composition**:

```
[Equipment Check: 0-5min] 
  → (Bridge: equipment_status_check) 
  → [Movement: 5-30min OR abort]
  → (Bridge: detection_assessment)
  → [Final Approach: 30-45min OR alternate_route: 30-50min]
```

## Benefits

1. **Unified Planning Model**: Single solution tree structure handles all planning types
2. **Reentrant Architecture**: Planning can be paused, modified, and resumed at any point
3. **Temporal-Logical Integration**: STN bridges provide seamless reasoning across constraint types
4. **Scalable Complexity**: Solution trees can represent arbitrarily complex planning scenarios
5. **Debug Visibility**: Clear separation of temporal segments and logical bridges aids debugging

## Migration from Previous Architecture

This ADR supersedes:

- **ADR-082**: Elixir Flow Parallel STN Processing (focused on optimization, not architecture)
- **ADR-083**: STN Timeline Segmentation Strategy (subsumed into STN bridge concept)
- **ADR-090**: Hierarchical STN Temporal Planner (replaced by unified solution tree approach)
- **ADR-091**: STN-Unified Temporal Planner Architecture (refined into STN bridge concept)

The migration involves:

1. Moving all solution tree logic from `plan.ex` to `planner.ex`
2. Removing non-reentrant todo list API
3. Implementing STN bridge composition in solution tree evaluation
4. Updating all planner clients to use reentrant solution tree API

## Success Criteria

- [ ] All planning operations use solution trees (no todo list remnants)
- [ ] STN bridges successfully connect temporal and logical planning
- [ ] Reentrant planning supports pause/resume/modification at any point
- [ ] Performance matches or exceeds previous dual-API system
- [ ] Clear debugging capabilities for complex temporal-logical interactions

## References

- [Simple Temporal Networks (STN)](https://en.wikipedia.org/wiki/Simple_temporal_network)
- [Hierarchical Task Network (HTN) Planning](https://en.wikipedia.org/wiki/Hierarchical_task_network)
- [AriaEngine Planner Module](/apps/aria_engine/lib/aria_engine/planner.ex)
