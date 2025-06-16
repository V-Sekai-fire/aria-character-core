# ADR-083: STN Timeline Segmentation Strategy

**Status:** Superseded (June 16, 2025)

**Superseded by:** [ADR-099: STN Bridge Reentrant Planner Architecture](099-stn-bridge-reentrant-planner-architecture.md)

> **DISCLAIMER: FICTIONAL GAME SCENARIO**
>
> All references to military operations, hostage rescue scenarios, tactical operations, and related activities in this document are purely fictional game planning scenarios for the Aria character temporal reasoning system. These are not related to any real military events, actual operations, or real-world situations. This is entertainment software development for a fictional character AI system.

## Context

The core challenge in temporal planning is that not all actions are inherently temporal. Some actions have measurable duration (temporal actions), while others are instantaneous logical decisions (non-temporal actions). STN bridges solve this fundamental mismatch by creating a hierarchical architecture that converts non-temporal actions into temporal timeline elements.

## What Are STN Bridges?

**STN Bridges** are compositional units that connect temporal segments (actions with duration) and non-temporal actions (instantaneous decisions) into a unified temporal timeline. They work by treating non-temporal actions as zero-duration "decision points" that create natural boundaries between temporal segments.

### Hierarchical Bridge Architecture

STN bridges create a hierarchical decomposition:

```
Planning Level    │ Bridge Type           │ Duration
─────────────────┼──────────────────────┼─────────────
Goals            │ Goal Achievement      │ Spans multiple methods
Methods          │ Method Selection      │ Instantaneous decision
Actions          │ Action Execution      │ Measured duration (temporal)
Conditions       │ State Validation      │ Instantaneous check
```

## Decision

Implement STN bridges as the primary mechanism for integrating temporal and non-temporal planning through hierarchical decomposition that converts logical decisions into temporal timeline elements.

## How STN Bridges Work

### Converting Non-Temporal to Temporal

STN bridges convert non-temporal actions into temporal elements through **hierarchical decomposition**:

1. **Non-temporal actions** (method selection, condition checking) become **instantaneous timepoints**
2. **Temporal actions** (movement, equipment use) become **duration segments**
3. **Bridge connections** link timepoints and segments into a continuous timeline

### Real-World Example: Mission Planning

Consider a fictional game scenario where a character must complete a mission:

#### Non-Temporal Actions (Logical Decisions)

```
IF equipment_ready THEN proceed_to_waypoint
IF path_blocked THEN find_alternate_route
IF detected THEN switch_to_stealth_mode
```

#### Temporal Actions (Measurable Duration)

```
[5 min] Equipment check
[20 min] Movement to waypoint
[10 min] Stealth approach
```

#### STN Bridge Integration

```
Timeline: [T+0] → [T+5] → [T+5] → [T+25] → [T+25] → [T+35]
          │       │       │       │        │       │
          Start   Check   Decision Movement Decision Approach
                  (5min)  (0min)  (20min)  (0min)  (10min)
```

### Hierarchical Bridge Types

#### 1. Method Selection Bridges

- **Purpose**: Choose which method to execute for a given task
- **Duration**: Instantaneous (0 duration)
- **Function**: Connect task goals to method execution segments

```elixir
%STNBridge{
  type: :method_selection,
  duration: 0,
  preconditions: [goal_active],
  effects: [method_selected],
  connects: {:task_goal, :method_execution}
}
```

#### 2. Condition Validation Bridges

- **Purpose**: Check preconditions and state requirements
- **Duration**: Instantaneous (0 duration)
- **Function**: Validate that conditions are met before proceeding

```elixir
%STNBridge{
  type: :condition_check,
  duration: 0,
  preconditions: [state_conditions],
  effects: [validation_result],
  connects: {:previous_action, :next_action}
}
```

#### 3. Action Execution Bridges

- **Purpose**: Execute actual temporal actions with measurable duration
- **Duration**: Variable (based on action)
- **Function**: Perform the actual work that takes time

```elixir
%STNBridge{
  type: :action_execution,
  duration: {5, 30},  # 5-30 minute range
  preconditions: [action_ready],
  effects: [action_completed],
  connects: {:start_timepoint, :end_timepoint}
}
```

### Hierarchical Composition Process

1. **Goal Decomposition**: Break high-level goals into sub-goals
2. **Method Selection**: Choose methods to achieve each sub-goal (Bridge)
3. **Action Planning**: Determine specific actions for each method
4. **Temporal Sequencing**: Order actions with timing constraints
5. **Bridge Insertion**: Add instantaneous decision points between temporal segments

## Implementation Plan

### Phase 1: Core STN Bridge Framework

- [ ] Create `AriaEngine.STNBridge` module for bridge composition
- [ ] Implement bridge types: method_selection, condition_check, action_execution
- [ ] Add hierarchical bridge composition with parent-child relationships
- [ ] Create bridge-to-timeline conversion functions

### Phase 2: Non-Temporal to Temporal Conversion

- [ ] **Method Selection Bridges** - Convert method choices to timeline points
- [ ] **Condition Validation Bridges** - Convert logical checks to timeline validation
- [ ] **Goal Achievement Bridges** - Convert goal completion to timeline milestones
- [ ] **State Transition Bridges** - Convert state changes to timeline events

### Phase 3: Hierarchical Bridge Composition

- [ ] Implement parent-child bridge relationships
- [ ] Add bridge inheritance and constraint propagation
- [ ] Create bridge network validation and consistency checking
- [ ] Add bridge optimization for temporal efficiency

### Phase 4: Integration with Planning System

- [ ] Integrate bridges with solution tree planning
- [ ] Add bridge-aware replanning and failure recovery
- [ ] Create bridge visualization for debugging and analysis
- [ ] Add performance monitoring for bridge composition overhead

## Implementation Details

### Bridge Composition Algorithm

```elixir
# Convert mixed temporal/non-temporal plan to pure temporal timeline
def compose_stn_bridges(plan_steps) do
  plan_steps
  |> Enum.map(&classify_action_type/1)
  |> Enum.chunk_by(&(&1.type))
  |> Enum.flat_map(&create_bridge_segment/1)
  |> validate_temporal_consistency()
end

defp classify_action_type(action) do
  case action do
    {method, _args} when is_atom(method) -> 
      %{type: :temporal, action: action, duration: get_duration(method)}
    
    {:condition, condition} -> 
      %{type: :non_temporal, action: action, duration: 0}
    
    {:goal, goal} ->
      %{type: :bridge, action: action, duration: 0}
  end
end

defp create_bridge_segment(action_group) do
  case action_group do
    [%{type: :temporal} | _] = temporal_actions ->
      # Create temporal segment with duration constraints
      create_temporal_segment(temporal_actions)
      
    [%{type: :non_temporal} | _] = logical_actions ->
      # Create instantaneous bridge points
      create_decision_bridges(logical_actions)
      
    [%{type: :bridge} | _] = bridge_actions ->
      # Create hierarchical bridge composition
      create_hierarchical_bridges(bridge_actions)
  end
end
```

### Hierarchical Bridge Network

```
High-Level Goal: "Complete Mission"
├── Method Selection Bridge (0 duration)
│   ├── Temporal Segment: Equipment Check (5 min)
│   ├── Condition Bridge: Equipment Status (0 duration)
│   └── Temporal Segment: Movement (20 min)
├── Condition Bridge: Path Status (0 duration)
│   ├── Temporal Segment: Normal Route (15 min)
│   └── Temporal Segment: Alternate Route (25 min)
└── Goal Achievement Bridge (0 duration)
```

### Bridge Timeline Conversion

Non-temporal actions become **decision points** that connect temporal segments:

```
Original Mixed Plan:
[Equipment Check] → IF ready → [Move to Waypoint] → IF detected → [Stealth Mode]

STN Bridge Timeline:
[T+0-5: Equipment] → [T+5: Decision] → [T+5-25: Movement] → [T+25: Decision] → [T+25-35: Stealth]
```

### Temporal Consistency Validation

STN bridges maintain temporal consistency through:

1. **Bridge Timepoint Validation**: Ensure decision points don't violate temporal ordering
2. **Segment Duration Constraints**: Validate that temporal segments have realistic durations
3. **Cross-Bridge Dependencies**: Ensure that bridge decisions don't create temporal conflicts
4. **Global Timeline Coherence**: Verify that the complete timeline is temporally consistent

## Success Criteria

- STN bridges successfully convert all non-temporal actions to temporal timeline elements
- Hierarchical bridge composition maintains logical relationships while adding temporal structure
- Bridge networks validate temporal consistency across decision points and action segments
- Integration with solution tree planning preserves reentrant planning capabilities

## Consequences

**Positive:**

- **Unified temporal representation**: All planning elements (temporal and non-temporal) exist in the same timeline
- **Hierarchical clarity**: Clear separation between logical decisions and temporal execution
- **Debugging visibility**: Bridge structure makes planning decisions explicit and traceable
- **Temporal consistency**: Automatic validation prevents temporally impossible plans

**Risks:**

- **Complexity overhead**: Bridge composition adds computational complexity to planning
- **Learning curve**: Developers need to understand bridge concepts and hierarchical structure
- **Debugging complexity**: Bridge networks can become complex for large planning scenarios
- **Performance impact**: Bridge validation and composition may slow planning performance

## Related ADRs

- **ADR-089**: STN Bridge Reentrant Planner Architecture (bridge implementation details)
- **ADR-099**: STN Bridge Reentrant Planner Architecture (canonical bridge architecture)
- **ADR-082**: Elixir Flow Parallel STN Processing (bridge performance optimization)
- **ADR-034**: Definitive Temporal Planner Architecture (planning context)
