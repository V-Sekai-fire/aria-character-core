# ADR-037: Timeline-Based Temporal Planning vs Durative Actions

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
- **Computational Tractability**: Well-studied algorithms with known complexity bounds
- **Intuitive Modeling**: Actions directly correspond to things agents do
- **Simpler Implementation**: Critical Path Method provides straightforward scheduling
- **Clear Dependencies**: Action dependencies are explicit and easy to verify
- **Proven Approach**: Extensively used in automated planning and project management

**Disadvantages:**
- **Limited State Modeling**: Actions represent instantaneous state changes, not continuous evolution
- **Resource Modeling**: Awkward representation of continuously changing resources
- **Inflexibility**: Hard to represent interruptible or variable-duration activities
- **Artificial Granularity**: Must choose specific action granularity that may not match domain

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

## Arguments For Timeline Planning

1. **Better Domain Modeling**: Many real-world domains are naturally modeled as state evolution over time rather than discrete actions

2. **Resource Integration**: Continuous resources (battery, fuel, memory) are first-class citizens rather than awkward side effects

3. **Flexibility**: Can represent complex temporal patterns like overlapping activities, variable durations, and interruptions

4. **Parallel Reasoning**: Different aspects of the system can be planned independently and then synchronized

5. **Rich Temporal Constraints**: Can express complex temporal relationships that are difficult in action-based planning

## Arguments Against Timeline Planning

1. **Computational Explosion**: State space can grow exponentially with the number of timelines and possible values

2. **Algorithm Complexity**: Requires sophisticated constraint satisfaction and optimization algorithms

3. **Implementation Burden**: Much more complex to implement correctly than critical path scheduling

4. **Debugging Difficulty**: Timeline inconsistencies are harder to diagnose than action dependency violations

5. **Overkill for Simple Domains**: Many planning problems don't need the expressiveness of timeline planning

## Recommendation

For the current AriaEngine temporal planner implementation, I recommend **staying with durative actions** for the following reasons:

1. **Implementation Priority**: Given the current codebase and timeline, the simpler durative action approach allows faster delivery of working temporal planning

2. **Domain Fit**: The initial use cases (character movement, simple resource management) are well-suited to action-based planning

3. **Proven Algorithms**: Critical Path Method provides optimal scheduling with well-understood performance characteristics

4. **Future Migration Path**: The JSON-LD data model can accommodate timeline-based planning later if needed

However, timeline-based planning should be **reconsidered for future versions** when:
- Complex resource management becomes important
- Continuous state variables need first-class support  
- Interruptible or variable-duration activities are required
- Domain complexity exceeds action-based modeling capabilities

## Implementation Notes

If timeline-based planning is pursued in the future:

1. **Start with Hybrid Approach**: Use timelines for continuous resources while keeping actions for discrete activities

2. **Constraint Solver Integration**: Consider integrating with constraint programming libraries like `constraint` or `gecode_ex`

3. **Domain-Specific Languages**: Develop DSLs for expressing timeline constraints naturally

4. **Incremental Planning**: Implement timeline planning incrementally rather than full replanning

## Related ADRs

- [ADR-034: Definitive Temporal Planner Architecture](034-definitive-temporal-planner-architecture.md)
- [ADR-035: Canonical Temporal Backtracking Problem](035-canonical-temporal-backtracking-problem.md)  
- [ADR-036: Evolving AriaEngine Planner Blueprint](036-evolving-ariengine-planner-blueprint.md)

## Consequences

### If Timeline Planning is Adopted

**Positive:**
- More expressive temporal reasoning capabilities
- Better handling of continuous state variables
- More natural domain modeling for complex scenarios
- Foundation for advanced temporal planning features

**Negative:**
- Significantly increased implementation complexity
- Higher computational requirements
- Longer development timeline
- Risk of over-engineering for current requirements

### If Durative Actions are Retained

**Positive:**
- Faster implementation and delivery
- Well-understood algorithms and performance
- Simpler debugging and validation
- Good fit for current domain requirements

**Negative:**  
- Limited expressiveness for complex temporal scenarios
- Awkward handling of continuous resources
- May require refactoring for advanced use cases
- Less flexible temporal constraint modeling

This ADR serves as a foundation for future architectural decisions as the temporal planning requirements evolve.
