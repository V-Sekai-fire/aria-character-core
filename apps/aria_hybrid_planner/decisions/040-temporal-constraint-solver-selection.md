# ADR-040: Temporal Constraint Solver Selection

<!-- @adr_serial R25T0041A98 -->

## Status

Accepted

## Date

2025-06-14

## Context

ADR-038's timeline-based temporal planner requires a constraint solver to handle various types of temporal constraints including duration constraints, resource constraints, synchronization constraints, and transition constraints. There are multiple temporal network formalisms available, each with different computational properties and expressiveness.

The key constraint types identified in ADR-038 are:

- **Temporal constraints**: min/max duration, precedence relationships
- **Resource constraints**: consumption rates, capacity limits, thresholds
- **Synchronization constraints**: conditional state dependencies
- **Transition constraints**: allowable state changes

We need to select the appropriate temporal network formalism and constraint solver that balances expressiveness, computational efficiency, and implementation complexity.

## Decision

We will implement a **Simple Temporal Network with Preferences (STNP)** solver with custom extensions for resource and synchronization constraints.

### Rationale

#### Why Simple Temporal Networks (STN)?

1. **Computational Efficiency**: STN solving is polynomial time (O(n³) using Floyd-Warshall)
2. **Well-Understood**: Mature algorithms with proven correctness
3. **Sufficient Expressiveness**: Handles temporal precedence and duration constraints
4. **Real-time Capable**: Fast enough for dynamic replanning

#### Why STNP Extensions?

1. **Optimization**: Preferences allow optimizing plan quality, not just feasibility
2. **Soft Constraints**: Handle non-critical constraints that can be violated with penalties
3. **Robust Planning**: Graceful degradation when hard constraints cannot be satisfied

#### Why Custom Extensions?

STN/STNP doesn't natively handle:

- **Resource constraints**: Need custom propagation for consumption/capacity
- **Synchronization constraints**: Need conditional constraint activation
- **State transitions**: Need discrete state space reasoning

### Technical Approach

#### Core STN Solver

```elixir
defmodule AriaEngine.STNSolver do
  @moduledoc """
  Simple Temporal Network solver optimized for temporal planning workloads.
  Uses Path Consistency (PC-2) algorithm for optimal STN solving performance.
  Handles temporal precedence and duration constraints with incremental updates.
  """

  @type timepoint :: atom()
  @type constraint :: {timepoint(), timepoint(), integer(), integer()}
  @type distance_graph :: %{timepoint() => %{timepoint() => {integer(), integer()}}}

  @spec solve(constraints :: [constraint()]) :: {:ok, distance_graph()} | {:error, :inconsistent}
  def solve(constraints) do
    # Build constraint graph
    # Apply Path Consistency (PC-2) algorithm - O(n³) with early termination
    # PC-2 is specifically designed for STNs and outperforms Floyd-Warshall
    # in practice due to constraint propagation optimizations
    # Returns minimal network with tightest bounds
  end

  @spec solve_incremental(distance_graph(), [constraint()]) :: 
    {:ok, distance_graph()} | {:error, :inconsistent}
  def solve_incremental(existing_solution, new_constraints) do
    # Incremental constraint propagation for dynamic updates
    # Only propagates changes from new constraints, avoiding full recomputation
    # Critical for real-time replanning scenarios
  end

  @spec is_consistent?(distance_graph()) :: boolean()
  def is_consistent?(graph) do
    # Check diagonal elements for negative values (negative cycles)
  end

  @spec get_bounds(distance_graph(), timepoint(), timepoint()) :: {integer(), integer()}
  def get_bounds(graph, from, to) do
    # Extract temporal bounds between timepoints
  end
end
```

#### Resource Extension

```elixir
defmodule AriaEngine.ResourceConstraintSolver do
  @moduledoc """
  Resource constraint solver integrated with STN.
  Handles consumption rates, capacity limits, and thresholds.
  """

  @type resource :: atom()
  @type resource_constraint :: %{
    resource: resource(),
    intervals: [{timepoint(), timepoint()}],
    consumption_rate: number(),
    capacity_limit: number(),
    threshold: number()
  }

  @spec check_resource_feasibility([resource_constraint()], distance_graph()) ::
    {:ok, [resource_constraint()]} | {:error, :resource_conflict}
  def check_resource_feasibility(constraints, temporal_bounds) do
    # Check resource availability over time
    # Identify resource conflicts
    # Suggest constraint relaxations
  end
end
```

#### Synchronization Extension

```elixir
defmodule AriaEngine.SynchronizationSolver do
  @moduledoc """
  Synchronization constraint solver for conditional dependencies.
  Handles when-then rules and state-dependent activations.
  """

  @type sync_constraint :: %{
    condition: {atom(), any()},
    consequence: {atom(), any()},
    timepoints: [timepoint()]
  }

  @spec propagate_sync_constraints([sync_constraint()], distance_graph()) ::
    {:ok, [constraint()]} | {:error, :sync_conflict}
  def propagate_sync_constraints(sync_constraints, temporal_bounds) do
    # Evaluate conditional constraints
    # Generate additional STN constraints
    # Handle constraint activation/deactivation
  end
end
```

### Integration Architecture

```elixir
defmodule AriaEngine.TemporalConstraintSolver do
  @moduledoc """
  Unified temporal constraint solver combining STN with custom extensions.
  """

  alias AriaEngine.{STNSolver, ResourceConstraintSolver, SynchronizationSolver}

  @type constraint_set :: %{
    temporal: [STNSolver.constraint()],
    resource: [ResourceConstraintSolver.resource_constraint()],
    synchronization: [SynchronizationSolver.sync_constraint()]
  }

  @spec solve(constraint_set()) :: {:ok, solution()} | {:error, reason :: atom()}
  def solve(%{temporal: temporal, resource: resource, synchronization: sync}) do
    with {:ok, stn_solution} <- STNSolver.solve(temporal),
         {:ok, resource_solution} <- ResourceConstraintSolver.check_resource_feasibility(resource, stn_solution),
         {:ok, additional_constraints} <- SynchronizationSolver.propagate_sync_constraints(sync, stn_solution),
         {:ok, final_solution} <- STNSolver.solve(temporal ++ additional_constraints) do
      {:ok, %{
        temporal_bounds: final_solution,
        resource_allocations: resource_solution,
        active_sync_constraints: additional_constraints
      }}
    else
      error -> error
    end
  end
end
```

## Alternatives Considered

### Temporal Constraint Networks (TCN)

- **Pros**: More expressive than STN, handles disjunctive constraints
- **Cons**: NP-complete solving, too complex for real-time use
- **Verdict**: Overkill for our constraint types

### Disjunctive Temporal Networks (DTN)

- **Pros**: Handles alternative plans, resource scheduling
- **Cons**: Exponential search space, implementation complexity
- **Verdict**: Too complex for initial implementation

### Conditional Simple Temporal Networks (CSTN)

- **Pros**: Native conditional constraint support
- **Cons**: More complex than needed, execution semantics unclear
- **Verdict**: Unnecessary complexity

### Simple Temporal Networks (STN) Only

- **Pros**: Simplest, fastest, well-understood
- **Cons**: Insufficient expressiveness for resource/sync constraints
- **Verdict**: Too limited for our needs

## Implementation Phases

### Phase 1: Core STN Solver

- Implement Floyd-Warshall with interval arithmetic
- Basic inconsistency detection
- Unit tests with simple temporal constraints

### Phase 2: Resource Extension

- Resource consumption modeling
- Capacity constraint checking
- Resource conflict detection

### Phase 3: Synchronization Extension

- Conditional constraint evaluation
- Dynamic constraint activation
- Integration with STN core

### Phase 4: Performance Optimization

- Incremental constraint propagation
- Constraint preprocessing
- Caching and memoization

## Consequences

### Positive

- **Polynomial Time**: O(n³) solving enables real-time performance
- **Extensible**: Modular design allows adding new constraint types
- **Well-Founded**: STN theory provides mathematical guarantees
- **Practical**: Handles all constraint types identified in ADR-038

### Negative

- **Custom Implementation**: Need to implement extensions ourselves
- **Limited Expressiveness**: Cannot handle arbitrary disjunctive constraints
- **Complexity**: Multi-layer solving adds implementation complexity

### Risk Mitigation

- **Incremental Development**: Build core STN first, add extensions gradually
- **Extensive Testing**: Comprehensive test suite for each constraint type
- **Performance Monitoring**: Benchmark against real-world planning scenarios

## Related ADRs

- [ADR-034: Definitive Temporal Planner Architecture](034-definitive-temporal-planner-architecture.md) - Architecture foundation
- [ADR-035: Canonical Temporal Backtracking Problem](035-canonical-temporal-backtracking-problem.md) - Test case requiring PC-2 algorithm
- [ADR-037: Timeline-Based vs Durative Actions](037-timeline-based-vs-durative-actions.md) - Timeline approach requiring constraint solver
- [ADR-038: Timeline-Based Temporal Planner Implementation](038-timeline-based-temporal-planner-implementation.md) - Deprecated implementation details
- [ADR-041: Temporal Solver Tech Stack Requirements](041-temporal-solver-tech-stack-requirements.md) - Implementation tech stack
- [ADR-042: Cold Boot Implementation Order](042-temporal-planner-cold-boot-implementation-order.md) - STN solver implementation sequence
- [ADR-043: Total Order to Partial Order Transformation](043-total-order-to-partial-order-transformation.md) - PC-2 parallelization algorithm

This constraint solver selection provides the optimal balance of expressiveness, performance, and implementation feasibility for the timeline-based temporal planner architecture.
