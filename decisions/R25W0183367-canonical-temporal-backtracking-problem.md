# R25W0183367: Canonical Temporal Backtracking Problem Definition

<!-- @adr_serial R25W0183367 -->

## Status

Accepted

## Date

2025-06-14

## Context

The AriaEngine/TimeStrike temporal planner requires a clearly defined canonical problem that demonstrates true temporal reasoning and backtracking capabilities. This problem serves as the definitive test case for validating that the temporal planner implements mathematical backtracking rather than simple sequential action planning.

R25W017DEAF established the temporal planner architecture requirements, and this ADR defines the specific problem that must be solved to verify the implementation meets those requirements.

## Decision

**Define the Blocking Enemy Scenario as the canonical temporal backtracking problem.** This problem requires the planner to detect temporal conflicts, backtrack from failed initial plans, and generate alternative solutions that satisfy temporal constraints.

## Canonical Temporal Backtracking Problem: Maya's Adaptive Scorch Coordination

### Time System

**All temporal values use integer time ticks** to ensure deterministic behavior and avoid floating-point precision issues in temporal reasoning. This canonical problem operates on a discrete time system where:

- 1 tick = 1 unit of game time
- Movement speeds are in units/tick
- Durations are in ticks
- All temporal constraints use integer values

### Problem Setup

- **High-Level Goal**: `eliminate_soldier_patrol` (requires Goal-Task-Network decomposition)
- **Primary Agent**: Maya {3,5,0} with Scorch ability, limited vision range (8 units)
- **Supporting Agent**: Alex {4,4,0} with scouting capability and movement speed 4 units/tick
- **Target**: Soldier2 on patrol route {15,5,0} → {12,5,0} → {15,5,0} at 3 units/tick
- **Constraint**: Must eliminate Soldier2 before he reaches safety bunker at {10,5,0}
- **Imperfect Information**: Maya cannot see Soldier2's exact position without Alex's reconnaissance
- **Dynamic Elements**: Archer1 at {18,3,0} occasionally blocks line of sight, creating opportunity windows

### Goal-Task-Network Decomposition

**High-Level Goal**: `eliminate_soldier_patrol`
**Task Breakdown**:

1. **Reconnaissance Task**: Alex scouts to reveal Soldier2's patrol pattern
2. **Historical Analysis Task**: Query past positions to predict future patrol timing
3. **Coordination Task**: Synchronize Maya's Scorch with Alex's positioning
4. **Opportunity Exploitation Task**: React to dynamic tactical windows (patrol pauses, line-of-sight blocks)

### Initial State Specification

```elixir
initial_state = TemporalState.new(0)
|> TemporalState.set_temporal_object("position", "maya", {3, 5, 0}, 0)
|> TemporalState.set_temporal_object("vision_range", "maya", 8, 0)
|> TemporalState.set_temporal_object("position", "alex", {4, 4, 0}, 0)
|> TemporalState.set_temporal_object("speed", "alex", 4, 0)
|> TemporalState.set_temporal_object("position", "soldier2", {15, 5, 0}, 0)
|> TemporalState.set_temporal_object("patrol_route", "soldier2", [{15,5,0}, {12,5,0}], 0)
|> TemporalState.set_temporal_object("patrol_speed", "soldier2", 3, 0)
|> TemporalState.set_temporal_object("waypoint_pause_duration", "soldier2", 10, 0)
|> TemporalState.set_temporal_object("safety_bunker", "mission", {10, 5, 0}, 0)
|> TemporalState.set_temporal_object("position", "archer1", {18, 3, 0}, 0)
|> TemporalState.set_temporal_object("hp", "soldier2", 70, 0)

goal = %{type: :eliminate_soldier_patrol, target: "soldier2", deadline: 200}
temporal_constraints = [
  %{type: :deadline, max_time: 200},
  %{type: :vision_limit, agent: "maya", range: 8.0},
  %{type: :patrol_behavior, entity: "soldier2", waypoint_pause: 1.0},
  %{type: :dynamic_opportunities, blocking_entity: "archer1"}
]
```

### Temporal Conflict & Multi-Layer Backtracking

**Initial Plan (Simple Coordination)**:

1. Maya moves to optimal Scorch position {13,5,0}
2. Maya casts Scorch targeting Soldier2's predicted position
3. Alex provides cleanup if needed

**Multi-Layer Conflicts**:

1. **Imperfect Information Conflict**:
   - Maya cannot see Soldier2 from her starting position (distance > 8 units)
   - Initial plan fails because Maya lacks target information

2. **Temporal Prediction Conflict**:
   - Alex scouts and reveals Soldier2's patrol pattern with waypoint pauses
   - Historical state queries show Soldier2 pauses at {12,5,0} for 10 ticks every cycle
   - Initial timing prediction fails to account for patrol complexity

3. **Dynamic Opportunity Conflict**:
   - Archer1 moves and blocks line of sight at tick 50, creating opportunity window
   - Original plan timing conflicts with newly discovered tactical advantage

4. **Cascading Timeline Conflict**:
   - Alex's scouting mission delays Maya's positioning by 30 ticks
   - Maya's delayed timing conflicts with Soldier2's safety bunker approach
   - Entire coordination sequence requires replanning

### Required Multi-Phase Backtracking Solutions

The temporal planner must demonstrate progressive backtracking through multiple planning phases:

#### Phase 1: Information Gathering Backtracking

**Initial Failure**: Maya cannot target unseen enemy
**Backtrack Decision**: Deploy Alex for reconnaissance mission

- Alex scouts to {14,5,0} to observe patrol pattern (25 tick travel time)
- Historical state reconstruction: Query Soldier2's last 3 positions
- Pattern analysis: Discover waypoint pause behavior at {12,5,0}
- **New timeline**: Reconnaissance complete at tick 25, pattern known at tick 30

#### Phase 2: Temporal Coordination Backtracking  

**Secondary Failure**: Simple coordination timing conflicts with patrol complexity
**Backtrack Decision**: Exploit waypoint pause windows

- Maya positions at {11,5,0} to catch Soldier2 during pause at {12,5,0}
- Alex coordinates arrival to support attack during pause window
- **Timing window**: Soldier2 pauses at tick 40 for 10 tick duration
- **Verification**: `scorch_cast_time == pause_window_start && pause_duration >= cast_time`

#### Phase 3: Opportunity Window Backtracking

**Tertiary Failure**: Archer1 creates line-of-sight obstruction at critical moment
**Backtrack Decision**: Exploit archer's movement for tactical advantage

- Archer1 blocks view at tick 50, preventing enemy awareness of approach
- Maya uses concealment window to reposition for optimal angle
- Alex coordinates with concealment timing for surprise coordination
- **Dynamic adaptation**: `archer_block_time == maya_reposition_start`

#### Phase 4: Emergency Fallback Backtracking

**Final Conflict**: If coordination fails, Soldier2 approaches safety bunker
**Backtrack Decision**: Direct interception before bunker reach

- Calculate exact interception point between current position and bunker
- Maya uses area denial Scorch to force route change
- Alex intercepts at forced detour point
- **Last resort timing**: `interception_time < bunker_reach_time`

### Comprehensive Verification Requirements

#### 1. Goal-Task-Network Decomposition Verification

- High-level goal decomposed into executable tasks: `goal_decomposition_depth >= 2`
- Task dependencies properly sequenced: `reconnaissance_task.end_time <= coordination_task.start_time`
- Primitive actions generated from task breakdown: `primitive_actions_count >= 4`

#### 2. Multi-Agent Coordination Verification  

- Information sharing between agents: `alex_scout_data_shared_with_maya == true`
- Synchronized timing across agent actions: `coordination_window_overlap >= 5`
- No temporal conflicts in coordinated sequence: `agent_action_conflicts == 0`

#### 3. Historical State Reconstruction Verification

- Past state queries used for pattern analysis: `historical_queries_count >= 2`
- Patrol pattern successfully reconstructed: `patrol_pattern_accuracy >= 0.9`
- Prediction accuracy verified against actual movement: `prediction_error <= 0.5_units`

#### 4. Imperfect Information Management Verification

- Vision limitations properly modeled: `maya_vision_range_enforced == true`
- Reconnaissance mission changes available information: `information_state_before != information_state_after`
- Planning adapts to information acquisition: `plan_revised_after_scouting == true`

#### 5. Opportunity Window Exploitation Verification

- Dynamic opportunities detected: `opportunity_windows_detected >= 1`
- Plan timing adjusted to exploit opportunities: `timing_revised_for_opportunities == true`
- Success rate improved by opportunity exploitation: `success_probability_with_opportunities > success_probability_without`

#### 6. Multi-Phase Backtracking Evidence

- Multiple backtracking phases demonstrated: `backtrack_phases >= 3`
- Each phase addresses different conflict type: `conflict_types_addressed >= 3`
- Progressive plan refinement through backtracking: `plan_quality_improves_per_phase == true`

#### 7. Real-Time Performance Verification

- Planning time within performance bounds: `planning_time <= 10ms`
- Replanning faster than initial planning: `replan_time < initial_plan_time`
- Sub-millisecond state query response: `state_query_time <= 1ms`

### Expected API Usage

```elixir
# Goal-Task-Network Planning
{:ok, task_network} = GameEngine.decompose_goal(
  initial_state,
  %{type: :eliminate_soldier_patrol, target: "soldier2", deadline: 200}
)

# Multi-phase planning with backtracking
{:ok, plan, final_state, metadata} = GameEngine.plan_temporal_sequence(
  initial_state, 
  task_network, 
  temporal_constraints
)

# Verify comprehensive temporal planner features
assert metadata.goal_decomposition_depth >= 2
assert metadata.backtrack_phases >= 3
assert metadata.historical_queries_count >= 2
assert metadata.opportunity_windows_detected >= 1
assert metadata.planning_time <= 10.0  # milliseconds (real-world performance)
assert plan.goal_achieved == true
assert plan.temporal_conflicts_resolved == true
```

## Consequences

### Positive

- **Clear specification**: Unambiguous problem definition for temporal planner validation
- **Mathematical rigor**: Requires true temporal reasoning, not just sequential planning
- **Verifiable outcomes**: Concrete success criteria that can be automatically tested
- **Architectural validation**: Proves the temporal planner meets R25W017DEAF requirements

### Negative

- **Implementation complexity**: Requires sophisticated temporal conflict detection and resolution
- **Performance requirements**: Must solve the problem efficiently in real-time scenarios
- **Testing overhead**: All temporal planner implementations must pass this canonical test

## Implementation Requirements

Any temporal planner implementation must demonstrate:

### Core Temporal Reasoning

1. **Goal-Task-Network Decomposition**: Break high-level goals into executable task hierarchies
2. **Multi-Phase Backtracking**: Handle conflicts at information, coordination, opportunity, and emergency levels
3. **Historical State Reconstruction**: Query past states to inform future planning decisions
4. **Future State Prediction**: Accurately predict enemy behavior from historical patterns

### Advanced Features  

5. **Imperfect Information Management**: Plan with limited agent knowledge and information acquisition
6. **Dynamic Opportunity Exploitation**: Detect and exploit time-limited tactical advantages
7. **Multi-Agent Coordination**: Synchronize complex agent interactions with temporal dependencies
8. **Real-Time Performance**: Sub-millisecond state queries and fast replanning capabilities

### Mathematical Guarantees

9. **Temporal Consistency**: All agent timelines form valid temporal orderings
10. **Optimality**: Solutions minimize execution time while ensuring goal achievement
11. **Stability**: Plans remain robust under timing perturbations and information updates

## Cross-References

- **R25W017DEAF**: Definitive temporal planner architecture (establishes requirements this problem validates)
- **ADR-042**: Cold boot implementation order (uses this canonical problem as the definitive test case)
- **ADR-044**: Auto battler analogy (Maya's scenario as "auto chess round" example)
- **R25W0206D9D**: Timeline-based planning approach (validated by this canonical problem)
- **R25W02297A7**: STN solver selection (PC-2 algorithm must solve this problem efficiently)
- **R25W023C3DB**: Tech stack requirements (performance targets based on this problem)
- **R25W024014E**: Total order optimization (demonstrated through this problem's constraint solving)
- **R25W0365EF2**: Complete Temporal Planning Solver Implementation (Tasks 075-079 specifically implement this canonical problem)

This enhanced canonical problem serves as the definitive architectural requirement for temporal planner implementation and testing. Success in solving this problem validates that the temporal planner implements comprehensive temporal reasoning capabilities including Goal-Task-Network planning, multi-phase backtracking, historical state reconstruction, imperfect information management, and dynamic opportunity exploitation.
