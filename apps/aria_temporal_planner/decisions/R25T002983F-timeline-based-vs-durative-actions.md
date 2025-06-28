# ADR-037: Timeline-Based Temporal Planning vs Durative Actions

<!-- @adr_serial R25T002983F -->

## Status

Proposed

## Date

2025-06-14

## Context

The current temporal planning architecture (ADR-035, ADR-036) uses durative actions with explicit start/end times and dependencies. This ADR explores an alternative approach using timeline-based planning, where instead of modeling individual actions with durations, we model multiple parallel timelines that represent different aspects of the system state over time.

In traditional durative action planning, we have:

- Actions with explicit duration (e.g., "move from A to B takes 5 ticks")
- Dependencies between actions (e.g., "action B cannot start until action A finishes")
- Resource constraints and scheduling

In timeline-based planning, we have:

- State variables that change over time on parallel timelines
- Timeline constraints that define valid state transitions
- Synchronization points between timelines
- Temporal intervals representing persistent states rather than instantaneous actions

## Decision

We propose to evaluate timeline-based temporal planning as an alternative to durative actions for the AriaEngine temporal planner.

### Timeline-Based Architecture

#### Core Concepts

1. **Timeline**: A sequence of state values over time for a specific state variable

   - Example: `robot_location` timeline: [A(0-10), B(10-15), C(15-25)]
   - Example: `battery_level` timeline: [100(0-8), 75(8-16), 50(16-24)]

2. **State Variable**: A domain-specific attribute that changes over time

   - Discrete: `robot_location`, `gripper_state`, `door_status`
   - Continuous: `battery_level`, `fuel_amount`, `temperature`

3. **Timeline Constraint**: Rules governing valid state transitions

   - Duration constraints: "robot must stay at location for minimum 2 ticks"
   - Transition constraints: "battery can only decrease or stay same"
   - Synchronization: "gripper can only be 'open' when robot is at 'pickup_location'"

4. **Temporal Interval**: A period during which a state variable has a specific value
   - Format: `value(start_tick, end_tick)`
   - Intervals must be contiguous (no gaps) on each timeline

#### Implementation Structure

```elixir
defmodule AriaEngine.TimelinePlanner do
  @moduledoc """
  Timeline-based temporal planner using parallel state variable timelines
  instead of durative actions with dependencies.
  """

  defstruct [
    :timelines,      # %{state_variable => [intervals]}
    :constraints,    # Timeline constraint rules
    :horizon,        # Planning horizon in ticks
    :sync_points     # Cross-timeline synchronization requirements
  ]
end

defmodule AriaEngine.Timeline do
  defstruct [
    :variable_name,  # State variable this timeline tracks
    :intervals,      # [%{value: any(), start: integer(), end: integer()}]
    :constraints     # Rules for this specific timeline
  ]
end

defmodule AriaEngine.TimelineConstraint do
  defstruct [
    :type,          # :duration, :transition, :synchronization
    :variable,      # Which state variable(s) this affects
    :rule,          # The constraint logic
    :priority       # Constraint satisfaction priority
  ]
end
```

#### Planning Process

1. **Goal Decomposition**: Convert high-level goals into required timeline end states

   - Goal: "Robot at C with object" → timelines must end with `robot_location=C` and `carried_object=target`

2. **Timeline Generation**: For each state variable, generate possible timeline sequences

   - Use domain knowledge to enumerate valid state transitions
   - Apply duration constraints to determine minimum/maximum interval lengths

3. **Constraint Satisfaction**: Find timeline combinations that satisfy all constraints

   - Temporal constraints (durations, sequences)
   - Resource constraints (battery consumption, fuel usage)
   - Synchronization constraints (cross-timeline dependencies)

4. **Solution Optimization**: Select timeline combination that optimizes objectives
   - Minimize total time (earliest completion)
   - Minimize resource consumption
   - Maximize robustness (slack time)

### Comparison: Timeline vs Durative Actions

#### Timeline-Based Planning

**Advantages:**

- **Natural State Modeling**: Directly represents how domain state evolves over time
- **Parallel Reasoning**: Multiple timelines can be reasoned about independently then synchronized
- **Continuous Variables**: Better handling of resources that change continuously (battery, fuel)
- **Temporal Flexibility**: Easier to represent activities that can be interrupted or extended
- **Domain Expressiveness**: More natural for domains with complex state dependencies

**Disadvantages:**

- **Computational Complexity**: Potentially exponential state space for timeline combinations
- **Constraint Satisfaction**: More complex constraint solving compared to simple action scheduling
- **Implementation Complexity**: Requires sophisticated timeline reasoning algorithms
- **Less Intuitive**: Actions are more intuitive than state variable timelines for many domains
- **Validation Difficulty**: Harder to verify timeline consistency compared to action sequences

#### Durative Action Planning (Current Approach)

**Advantages:**

- **Simple Implementation**: Critical Path Method is well-understood and straightforward
- **Intuitive Modeling**: Actions directly correspond to things agents do
- **Clear Dependencies**: Action dependencies are explicit and easy to verify
- **Proven Approach**: Extensively used in automated planning and project management

**Disadvantages:**

- **Exponential Action Explosion**: Complex plans require exponentially many actions to represent properly
- **Limited State Modeling**: Actions represent instantaneous state changes, not continuous evolution
- **Resource Modeling**: Awkward representation of continuously changing resources
- **Inflexibility**: Hard to represent interruptible or variable-duration activities
- **Sequential Bottleneck**: All actions must be sequenced even when they could be independent
- **Replanning Cost**: Changing one action often requires replanning the entire sequence

### Example Comparison

#### Scenario: Robot picking up an object

**Durative Action Approach:**

```
Actions:
- move_to_pickup(robot, A, B) [duration: 5 ticks]
- open_gripper(robot) [duration: 1 tick]
- pick_up_object(robot, object) [duration: 2 ticks]
- close_gripper(robot) [duration: 1 tick]

Dependencies:
- open_gripper must complete before pick_up_object
- move_to_pickup must complete before open_gripper
- pick_up_object must complete before close_gripper
```

**Timeline Approach:**

```
Timelines:
- robot_location: [A(0-5), B(5-15)]
- gripper_state: [closed(0-6), open(6-8), closed(8-15)]
- carried_object: [none(0-8), target(8-15)]
- battery_level: [100(0-5), 95(5-8), 90(8-15)]

Constraints:
- robot must be at B when gripper opens
- object can only be picked up when gripper is open
- battery decreases by 1 per tick during movement, 2 per tick during manipulation
```

### Computational Complexity Analysis

#### **Action-Based Complexity**

- **State Space**: O(A^n) where A is average action branching factor, n is plan length
- **Dependency Resolution**: O(A^2) for each action added
- **Replanning**: O(A^n) complete regeneration when any action changes
- **Resource Tracking**: Additional O(R\*A^n) where R is number of resources

#### **Timeline-Based Complexity**

- **State Space**: O(V^t) where V is values per timeline, t is number of timelines
- **Constraint Propagation**: O(C\*V^2) where C is number of constraints
- **Replanning**: O(V^k) where k is number of affected timelines (k << t)
- **Resource Integration**: O(V^t) - resources are native timeline variables

**Key Insight**: For complex domains, t << n (fewer timelines than actions) and constraint propagation dramatically reduces the effective search space, making timeline planning computationally superior.

## Arguments For Timeline Planning

1. **Better Domain Modeling**: Many real-world domains are naturally modeled as state evolution over time rather than discrete actions

2. **Resource Integration**: Continuous resources (battery, fuel, memory) are first-class citizens rather than awkward side effects

3. **Flexibility**: Can represent complex temporal patterns like overlapping activities, variable durations, and interruptions

4. **Parallel Reasoning**: Different aspects of the system can be planned independently and then synchronized

5. **Rich Temporal Constraints**: Can express complex temporal relationships that are difficult in action-based planning

6. **Computational Advantages**:
   - **Constraint Propagation**: Timeline constraints can eliminate large portions of the search space early
   - **Decomposition**: Independent timelines can be solved separately, reducing exponential blowup
   - **Incremental Planning**: Only affected timelines need replanning when conditions change
   - **Pruning Efficiency**: Invalid timeline combinations can be detected and pruned faster than invalid action sequences
   - **Parallel Processing**: Timeline reasoning can be parallelized across multiple cores more effectively

## Arguments Against Timeline Planning

1. **Initial Implementation Complexity**: Requires sophisticated constraint satisfaction algorithms upfront

2. **Learning Curve**: Team needs to understand timeline reasoning concepts and debugging

3. **Domain Knowledge Requirements**: Requires careful modeling of state variables and constraints

4. **Tool Ecosystem**: Fewer existing libraries and tools compared to action-based planning

## Recommendation

For the AriaEngine temporal planner implementation, I recommend **adopting timeline-based planning** for the following computational and architectural reasons:

### **Computational Advantages**

1. **Superior Scalability**: Timeline constraints enable aggressive pruning of invalid combinations early in the search process, preventing exponential explosion that plagues action-based approaches

2. **Parallel Processing**: Independent timelines can be reasoned about in parallel across multiple CPU cores, providing significant speedup for complex planning problems

3. **Incremental Replanning**: When conditions change, only affected timelines need replanning rather than regenerating entire action sequences from scratch

4. **Constraint Propagation**: Timeline constraints naturally propagate across the problem, eliminating large portions of the search space automatically

5. **Memory Efficiency**: Timeline representation is more compact than equivalent action sequences, especially for long-duration plans

### **Domain Advantages**

1. **Natural Resource Modeling**: Continuous resources (battery, memory, network bandwidth) are modeled directly rather than through artificial action side-effects

2. **Real-World Alignment**: Game characters and AI agents naturally exist in continuous time with overlapping activities, which timeline planning represents directly

3. **Future-Proof Architecture**: Timeline planning handles complex temporal scenarios that action-based planning cannot express

However, timeline-based planning should be **implemented incrementally**:

**Phase 1**: Start with simple timelines for key state variables (location, resources)
**Phase 2**: Add constraint propagation and optimization
**Phase 3**: Implement full parallel timeline reasoning

The JSON-LD data model from ADR-036 is well-suited for representing timeline constraints and can accommodate this incremental approach.

## Implementation Notes

If timeline-based planning is pursued in the future:

1. **Start with Hybrid Approach**: Use timelines for continuous resources while keeping actions for discrete activities

2. **Constraint Solver Integration**: Consider integrating with constraint programming libraries like `constraint` or `gecode_ex`

3. **Domain-Specific Languages**: Develop DSLs for expressing timeline constraints naturally

4. **Incremental Planning**: Implement timeline planning incrementally rather than full replanning

## Related ADRs

- [ADR-034: Definitive Temporal Planner Architecture](034-definitive-temporal-planner-architecture.md) - Architecture foundation
- [ADR-035: Canonical Temporal Backtracking Problem](035-canonical-temporal-backtracking-problem.md) - Test case validating timeline approach
- [ADR-036: Evolving AriaEngine Planner Blueprint](036-evolving-ariengine-planner-blueprint.md) - Deprecated, replaced by later ADRs
- [ADR-040: Temporal Constraint Solver Selection](040-temporal-constraint-solver-selection.md) - Implements timeline-based constraints
- [ADR-041: Tech Stack Requirements](041-temporal-solver-tech-stack-requirements.md) - Supports timeline data structures
- [ADR-042: Cold Boot Implementation Order](042-temporal-planner-cold-boot-implementation-order.md) - Implements timeline-based approach
- [ADR-043: Total Order Optimization](043-total-order-to-partial-order-transformation.md) - Optimizes timeline constraint solving
- [ADR-044: Auto Battler Analogy](044-temporal-planner-as-auto-battler-ai.md) - Communicates timeline planning benefits

## Consequences

### If Timeline Planning is Adopted (Recommended)

**Positive:**

- **Superior Computational Performance**: Constraint propagation and parallel processing provide significant speedup
- **Better Scalability**: Timeline constraints prevent exponential search space explosion
- **Natural Domain Modeling**: Continuous resources and overlapping activities represented directly
- **Incremental Replanning**: Only affected timelines need updating when conditions change
- **Future-Proof Architecture**: Handles complex temporal scenarios that exceed action-based capabilities

**Negative:**

- **Initial Learning Curve**: Team needs to understand timeline reasoning and constraint modeling
- **Upfront Implementation**: Requires constraint satisfaction algorithms rather than simple scheduling
- **Domain Analysis Required**: Must identify appropriate state variables and constraints

### If Durative Actions are Retained

**Positive:**

- **Immediate Simplicity**: Critical Path Method is well-understood and quick to implement
- **Familiar Concepts**: Actions are intuitive for most developers
- **Existing Libraries**: More readily available scheduling algorithms

**Negative:**

- **Computational Bottlenecks**: Exponential action explosion for complex scenarios
- **Limited Expressiveness**: Cannot represent continuous resources or overlapping activities naturally
- **Expensive Replanning**: Any change requires complete action sequence regeneration
- **Technical Debt**: Will require refactoring to timeline approach for advanced use cases

This ADR serves as a foundation for future architectural decisions as the temporal planning requirements evolve.
