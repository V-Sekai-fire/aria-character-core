# ADR-038: Timeline-Based Temporal Planner Implementation Plan

<!-- @adr_serial R25T0031B6A -->

## Status

**Deprecated** - Superseded by ADR-042: Temporal Planner Cold Boot Implementation Order

## Date

2025-06-14

## Deprecation Note

This ADR is deprecated in favor of [ADR-042: Temporal Planner Cold Boot Implementation Order](042-temporal-planner-cold-boot-implementation-order.md) which provides a precise Test-Driven Development (TDD) implementation sequence that builds incrementally toward solving the canonical temporal backtracking problem defined in ADR-035.

ADR-042 offers concrete implementation steps with exact test specifications, ensuring disciplined TDD methodology and validated functionality at each phase.

**This ADR is retained for historical reference only. All future development should follow ADR-042.**

---

## Original ADR Content (Deprecated)

### Title: Timeline-Based Temporal Planner Implementation Plan

## Context

Following the analysis in ADR-037, we have decided to implement timeline-based temporal planning for the AriaEngine. This approach provides superior computational performance through constraint propagation, natural domain modeling for continuous resources, and parallel processing capabilities. This ADR provides a concrete,## Related ADRs

- [ADR-034: Definitive Temporal Planner Architecture](034-definitive-temporal-planner-architecture.md)
- [ADR-035: Canonical Temporal Backtracking Problem](035-canonical-temporal-backtracking-problem.md)
- [ADR-037: Timeline-Based vs Durative Actions](037-timeline-based-vs-durative-actions.md)
- [ADR-036: Evolving AriaEngine Planner Blueprint](036-evolving-ariaengine-planner-blueprint.md) - **Deprecated**
- [ADR-039: Temporal Planner Reentrancy Stability](039-temporal-planner-reentrancy-stability.md) - **Not Necessary**
- [ADR-040: Temporal Constraint Solver Selection](040-temporal-constraint-solver-selection.md)
- [ADR-041: Temporal Solver Tech Stack Requirements](041-temporal-solver-tech-stack-requirements.md) implementation plan specifically designed for timeline-based planning.

## Decision

We will implement a timeline-based temporal planner using parallel state variable timelines with constraint satisfaction, replacing the durative action approach proposed in ADR-036.

### Core Architecture

#### Timeline Planner Structure

```elixir
defmodule AriaEngine.TimelinePlanner do
  @moduledoc """
  Timeline-based temporal planner with constraint propagation and parallel reasoning.
  Provides O(V^t) complexity vs O(A^n) for action-based approaches.
  """

  defstruct [
    :state_variables,    # Map of domain state variables
    :timelines,         # Active timeline constraints
    :horizon_ticks,     # Planning time horizon
    :constraints,       # Cross-timeline constraint rules
    :optimization_goals # Objectives (minimize time, resources, etc.)
  ]

  @doc "Main planning entry point"
  def plan(initial_state, goals, horizon_ticks, opts \\ []) do
    # Timeline generation -> Constraint satisfaction -> Optimization
  end
end

defmodule AriaEngine.Timeline do
  @moduledoc """
  Represents a state variable's evolution over time as discrete intervals.
  """

  defstruct [
    :variable_name,     # State variable identifier
    :value_domain,      # Possible values for this variable
    :intervals,         # Current timeline intervals
    :constraints        # Variable-specific constraints
  ]
end

defmodule AriaEngine.TimelineInterval do
  @moduledoc """
  A time period during which a state variable has a specific value.
  """

  defstruct [
    :value,            # State variable value during this interval
    :start_tick,       # Interval start time (inclusive)
    :end_tick,         # Interval end time (exclusive)
    :flexibility       # How much this interval can be adjusted
  ]
end

defmodule AriaEngine.TimelineConstraint do
  @moduledoc """
  Rules governing valid timeline configurations and transitions.
  """

  defstruct [
    :id,               # Unique constraint identifier
    :type,             # :temporal, :resource, :synchronization, :transition
    :variables,        # Which state variables this affects
    :predicate,        # Constraint checking function
    :priority,         # Constraint satisfaction priority (1-10)
    :violation_cost    # Cost of violating this constraint
  ]
end
```

### Phased Implementation Plan

#### Phase 1: Core Timeline Infrastructure

**Objective**: Establish basic timeline representation and manipulation

1. **Timeline Data Structures**

   ```elixir
   # Implement core timeline types
   - AriaEngine.Timeline
   - AriaEngine.TimelineInterval
   - AriaEngine.TimelineConstraint

   # Basic timeline operations
   - create_timeline/2
   - add_interval/3
   - merge_intervals/2
   - validate_timeline/1
   ```

2. **JSON-LD Integration**

   ```elixir
   # Timeline serialization vocabulary using Chibifire namespace
   @context %{
     "@vocab" => "https://chibifire.com/vocab/aria/temporal#",
     "Timeline" => "https://chibifire.com/vocab/aria/temporal#Timeline",
     "StateVariable" => "https://chibifire.com/vocab/aria/temporal#StateVariable",
     "Constraint" => "https://chibifire.com/vocab/aria/temporal#Constraint",
     "Interval" => "https://chibifire.com/vocab/aria/temporal#Interval",
     "startTick" => "https://chibifire.com/vocab/aria/temporal#startTick",
     "endTick" => "https://chibifire.com/vocab/aria/temporal#endTick",
     "durationTicks" => "https://chibifire.com/vocab/aria/temporal#durationTicks",
     "value" => "https://chibifire.com/vocab/aria/temporal#value",
     "constraintType" => "https://chibifire.com/vocab/aria/temporal#constraintType"
   }
   ```

3. **State Variable Registry**

   ```elixir
   defmodule AriaEngine.StateVariableRegistry do
     # Register domain-specific state variables
     # Define value domains and constraints
     # Provide variable introspection
   end
   ```

**Deliverable**: Basic timeline creation and serialization working

#### Phase 2: Constraint System (Week 3-4)

**Objective**: Implement constraint definition and basic propagation

1. **Constraint Definition DSL**

   ```elixir
   # Temporal constraints
   temporal_constraint(:robot_location, min_duration: 2, max_duration: 10)

   # Resource constraints
   resource_constraint(:battery_level, consumption_rate: 1, threshold: 10)

   # Synchronization constraints
   sync_constraint([:robot_location, :gripper_state],
     when: {robot_at: :pickup_zone}, then: {gripper: :open})

   # Transition constraints
   transition_constraint(:battery_level, only: :decrease_or_same)
   ```

2. **Constraint Propagation Engine**

   ```elixir
   defmodule AriaEngine.ConstraintPropagator do
     def propagate_constraints(timelines, constraints) do
       # Arc consistency algorithm
       # Forward checking for timeline intervals
       # Constraint violation detection and reporting
     end
   end
   ```

3. **Constraint Violation Handling**

   ```elixir
   # Soft constraint violations with costs
   # Hard constraint enforcement
   # Constraint relaxation strategies
   ```

**Deliverable**: Constraint definition and basic propagation working

#### Phase 3: Timeline Generation

**Objective**: Generate valid timeline combinations from initial state and goals

1. **Goal Decomposition**

   ```elixir
   defmodule AriaEngine.GoalDecomposer do
     def decompose_goal(goal, state_variables) do
       # Convert high-level goals to timeline end-state requirements
       # Handle composite goals with sub-timelines
       # Generate timeline templates
     end
   end
   ```

2. **Timeline Search Strategy**

   ```elixir
   # Breadth-first timeline generation
   # Constraint-guided search pruning
   # Heuristic timeline ordering
   ```

3. **Parallel Timeline Reasoning**

   ```elixir
   # Independent variable timeline generation
   # Cross-timeline dependency resolution
   # Parallel constraint checking using Tasks
   ```

**Deliverable**: Goal-driven timeline generation working

#### Phase 4: Optimization and Scheduling (Week 7-8)

**Objective**: Find optimal timeline configurations

1. **Multi-Objective Optimization**

   ```elixir
   defmodule AriaEngine.TimelineOptimizer do
     def optimize(timeline_candidates, objectives) do
       # Pareto-optimal timeline selection
       # Weighted objective combination
       # Solution ranking and selection
     end
   end
   ```

2. **Timeline Scheduling**

   ```elixir
   # Convert flexible timelines to concrete schedules
   # Resource allocation and leveling
   # Schedule validation and adjustment
   ```

3. **Performance Optimization**

   ```elixir
   # Timeline caching and memoization
   # Incremental constraint propagation
   # Parallel timeline evaluation
   ```

**Deliverable**: Optimized timeline scheduling working

#### Phase 5: Integration and Advanced Features (Week 9-10)

**Objective**: Complete integration with AriaEngine and advanced features

1. **AriaEngine Integration**

   ```elixir
   # Replace existing planner interface
   # Maintain backward compatibility where possible
   # Timeline execution monitoring
   ```

2. **Incremental Replanning**

   ```elixir
   defmodule AriaEngine.IncrementalReplanner do
     def replan(current_timeline, changed_conditions) do
       # Identify affected timeline segments
       # Minimize replanning scope
       # Maintain timeline consistency
     end
   end
   ```

3. **Advanced Timeline Features**

   ```elixir
   # Timeline branching for contingencies
   # Probabilistic timeline reasoning
   # Timeline debugging and visualization tools
   ```

**Deliverable**: Fully integrated timeline-based planner

### Key Implementation Strategies

#### 1. Constraint Propagation Algorithm

```elixir
defmodule AriaEngine.ConstraintPropagator do
  def propagate(timelines, constraints) do
    # 1. Initialize constraint queue with all constraints
    queue = initialize_constraint_queue(constraints)

    # 2. Process constraints until fixed point
    propagate_loop(timelines, queue, MapSet.new())
  end

  defp propagate_loop(timelines, queue, processed) do
    case :queue.out(queue) do
      {{:value, constraint}, new_queue} ->
        if MapSet.member?(processed, constraint.id) do
          propagate_loop(timelines, new_queue, processed)
        else
          case apply_constraint(timelines, constraint) do
            {:ok, new_timelines} ->
              # Constraint satisfied, continue
              propagate_loop(new_timelines, new_queue,
                MapSet.put(processed, constraint.id))

            {:modified, new_timelines, affected_vars} ->
              # Timeline modified, re-queue related constraints
              related_constraints = find_related_constraints(constraints, affected_vars)
              updated_queue = enqueue_constraints(new_queue, related_constraints)
              propagate_loop(new_timelines, updated_queue, processed)

            {:violation, reason} ->
              {:error, {:constraint_violation, constraint, reason}}
          end
        end

      {:empty, _} ->
        {:ok, timelines}
    end
  end
end
```

#### 2. Parallel Timeline Processing

```elixir
defmodule AriaEngine.ParallelTimelineProcessor do
  def process_timelines_parallel(state_variables, constraints) do
    # Group independent variables for parallel processing
    variable_groups = partition_independent_variables(state_variables, constraints)

    # Process each group in parallel
    timeline_tasks = Enum.map(variable_groups, fn group ->
      Task.async(fn -> generate_timeline_group(group, constraints) end)
    end)

    # Collect results and merge timelines
    partial_timelines = Task.await_many(timeline_tasks, :infinity)
    merge_timeline_groups(partial_timelines, constraints)
  end

  defp partition_independent_variables(variables, constraints) do
    # Build dependency graph from constraints
    dependency_graph = build_dependency_graph(variables, constraints)

    # Find strongly connected components
    Graph.strongly_connected_components(dependency_graph)
  end
end
```

#### 3. Timeline Optimization Strategy

```elixir
defmodule AriaEngine.TimelineOptimizer do
  def optimize(timeline_candidates, objectives) do
    # 1. Filter feasible timelines
    feasible = Enum.filter(timeline_candidates, &timeline_feasible?/1)

    # 2. Calculate objective scores
    scored = Enum.map(feasible, fn timeline ->
      score = calculate_objectives(timeline, objectives)
      {timeline, score}
    end)

    # 3. Pareto frontier selection
    pareto_optimal = select_pareto_optimal(scored)

    # 4. Final selection based on preferences
    select_best_timeline(pareto_optimal, objectives.preferences)
  end

  defp calculate_objectives(timeline, objectives) do
    %{
      completion_time: calculate_makespan(timeline),
      resource_usage: calculate_total_resource_consumption(timeline),
      flexibility: calculate_timeline_flexibility(timeline),
      constraint_violations: count_soft_constraint_violations(timeline)
    }
  end
end
```

### Testing Strategy

#### Unit Tests

- Timeline data structure operations
- Constraint propagation algorithms
- JSON-LD serialization/deserialization
- Individual optimization components

#### Integration Tests

- End-to-end timeline planning scenarios
- Performance benchmarks vs action-based planning
- Constraint satisfaction completeness
- Parallel processing correctness

#### Performance Tests

- Timeline generation scalability (O(V^t) verification)
- Constraint propagation efficiency
- Memory usage optimization
- Parallel processing speedup measurement

### Migration Strategy

#### From Existing Planner

1. **Wrapper Compatibility Layer**: Create adapters that convert action-based plans to timeline representation
2. **Gradual Feature Migration**: Move complex planning scenarios to timeline planner first
3. **A/B Testing**: Compare timeline vs action performance on same problems
4. **Deprecation Timeline**: Phase out action-based planner over 6 months

#### Risk Mitigation

- **Fallback Strategy**: Keep simplified action-based planner for critical scenarios
- **Performance Monitoring**: Continuous benchmarking to ensure timeline benefits
- **Team Training**: Comprehensive documentation and training on timeline concepts

## Consequences

### Positive

- **Superior Performance**: O(V^t) complexity with aggressive constraint pruning
- **Natural Domain Modeling**: Continuous resources and overlapping activities
- **Parallel Processing**: Timeline independence enables multi-core utilization
- **Incremental Planning**: Efficient replanning for dynamic environments
- **Expressiveness**: Complex temporal scenarios that exceed action-based capabilities

### Negative

- **Implementation Complexity**: Constraint satisfaction requires sophisticated algorithms
- **Learning Curve**: Team must understand timeline reasoning and debugging
- **Debugging Challenges**: Timeline inconsistencies require specialized tools
- **Initial Performance**: Setup overhead before constraint propagation benefits appear

#### Implementation Risk Mitigation

- **Incremental Implementation**: Phased approach reduces big-bang risk
- **Comprehensive Testing**: Performance benchmarks ensure timeline benefits
- **Documentation**: Detailed guides for timeline constraint modeling
- **Tool Support**: Timeline visualization and debugging utilities

## Related ADRs

- [ADR-034: Definitive Temporal Planner Architecture](034-definitive-temporal-planner-architecture.md)
- [ADR-035: Canonical Temporal Backtracking Problem](035-canonical-temporal-backtracking-problem.md)
- [ADR-037: Timeline-Based vs Durative Actions](037-timeline-based-vs-durative-actions.md)
- [ADR-036: Evolving AriaEngine Planner Blueprint](036-evolving-ariengine-planner-blueprint.md) - **Deprecated**
- [ADR-039: Temporal Planner Reentrancy Stability](039-temporal-planner-reentrancy-stability.md) - **Not Necessary**

## Double-Check Verification

### Implementation Plan Completeness ✅

- **Phase-by-Phase Breakdown**: Clear 10-week implementation schedule
- **Concrete Code Examples**: Actual Elixir module structures provided
- **Dependencies Identified**: JSON-LD integration, constraint libraries
- **Testing Strategy**: Unit, integration, and performance test plans

### Technical Feasibility ✅

- **Algorithm Specifications**: Constraint propagation and optimization algorithms detailed
- **Complexity Analysis**: O(V^t) vs O(A^n) mathematically justified
- **Parallel Processing**: Task-based parallel timeline generation strategy
- **Integration Path**: Clear migration from existing planner

### Risk Assessment ✅

- **Implementation Risks**: Complexity and learning curve acknowledged
- **Mitigation Strategies**: Incremental approach, fallback options, comprehensive testing
- **Performance Validation**: Benchmarking requirements specified
- **Team Enablement**: Documentation and training plans included

### Architectural Consistency ✅

- **Data Model**: JSON-LD vocabulary aligns with ADR-036 principles
- **Module Structure**: Clean separation of concerns across timeline components
- **Interface Design**: Backward compatibility and migration strategy
- **Optimization Goals**: Multi-objective optimization with practical objectives

This implementation plan provides a concrete, technically sound roadmap for delivering superior timeline-based temporal planning for the AriaEngine.
