# ADR-041: Temporal Solver Tech Stack Requirements

<!-- @adr_serial R25T005FA8D -->

## Status

Accepted

## Date

2025-06-14

## Context

Following ADR-040's selection of Simple Temporal Network with Preferences (STNP) solver with custom extensions, we need to define the complete tech stack requirements for implementing the temporal solver within the AriaEngine ecosystem.

The temporal solver must integrate with the existing Elixir/OTP umbrella application architecture, maintain compatibility with the JSON-LD serialization format (chibifire.com namespace), and provide the performance characteristics needed for real-time temporal planning.

## Decision

We will implement the temporal solver using a pure Elixir tech stack with minimal external dependencies, optimized for OTP concurrency patterns and integrated with the existing AriaEngine architecture.

### Core Tech Stack

#### Programming Language & Runtime

- **Elixir 1.15+**: Primary implementation language
- **OTP 26+**: Concurrent, fault-tolerant runtime
- **Rationale**: Consistency with existing codebase, excellent concurrency support

#### Core Dependencies

```elixir
# mix.exs dependencies for temporal solver
defp deps do
  [
    # Numerical computation
    {:nx, "~> 0.6"},                    # Tensor operations for matrix calculations
    {:explorer, "~> 0.7"},             # DataFrame operations for constraint analysis
    
    # JSON-LD serialization  
    {:jason, "~> 1.4"},                # Fast JSON parsing/encoding
    {:rdf, "~> 1.1"},                  # RDF/JSON-LD handling
    
    # Performance optimization
    {:flow, "~> 1.2"},                 # Parallel processing pipelines
    {:gen_stage, "~> 1.2"},            # Backpressure-aware streaming
    
    # Development and testing
    {:benchee, "~> 1.1", only: :dev},  # Performance benchmarking
    {:dialyxir, "~> 1.4", only: :dev}, # Static analysis
    {:credo, "~> 1.7", only: :dev},    # Code quality
    
    # Optional high-performance extensions
    {:rustler, "~> 0.30", optional: true}, # Rust NIFs for critical paths
  ]
end
```

#### Architecture Integration

```elixir
# Integration with existing AriaEngine apps
defmodule AriaEngine.TemporalSolver do
  use GenServer
  
  # Dependencies on other umbrella apps
  alias AriaEngine.{State, Goal, Plan}              # From aria_engine
  alias AriaTimestrike.{Timeline, Interval}         # From aria_timestrike
  alias AriaTimestrike.{TemporalPlanner, Constraint}     # From aria_timestrike
  
  # Integration with data storage
  alias AriaStorage.{PlanRepository, ConstraintStore}    # From aria_storage
  
  # Monitoring and telemetry
  alias AriaMonitor.{Metrics, Telemetry}                 # From aria_monitor
end
```

### Performance Requirements

#### Computational Performance

- **Constraint Solving**: O(n³) STN solving for up to 1000 timepoints
- **Memory Usage**: <100MB heap for typical planning scenarios
- **Latency**: <100ms for constraint satisfaction queries
- **Throughput**: >10 plans/second for replanning scenarios

#### Concurrency Requirements

- **Parallel Solving**: Multi-core STN solving using Flow pipelines
- **Concurrent Planners**: Multiple independent planning processes
- **Backpressure Handling**: GenStage-based constraint propagation
- **Fault Tolerance**: OTP supervision trees for solver processes

### Data Format Requirements

#### JSON-LD Schema (chibifire.com namespace)

```json
{
  "@context": {
    "@vocab": "https://chibifire.com/vocab/aria/temporal#",
    "Constraint": "https://chibifire.com/vocab/aria/temporal#Constraint",
    "Timepoint": "https://chibifire.com/vocab/aria/temporal#Timepoint", 
    "STNConstraint": "https://chibifire.com/vocab/aria/temporal#STNConstraint",
    "ResourceConstraint": "https://chibifire.com/vocab/aria/temporal#ResourceConstraint",
    "SyncConstraint": "https://chibifire.com/vocab/aria/temporal#SyncConstraint",
    "from": "https://chibifire.com/vocab/aria/temporal#fromTimepoint",
    "to": "https://chibifire.com/vocab/aria/temporal#toTimepoint", 
    "minDuration": "https://chibifire.com/vocab/aria/temporal#minDuration",
    "maxDuration": "https://chibifire.com/vocab/aria/temporal#maxDuration",
    "resource": "https://chibifire.com/vocab/aria/temporal#resource",
    "consumptionRate": "https://chibifire.com/vocab/aria/temporal#consumptionRate",
    "capacityLimit": "https://chibifire.com/vocab/aria/temporal#capacityLimit"
  },
  "@type": "ConstraintSet",
  "constraints": [
    {
      "@type": "STNConstraint",
      "from": "start_pickup",
      "to": "end_pickup", 
      "minDuration": 5,
      "maxDuration": 15
    },
    {
      "@type": "ResourceConstraint",
      "resource": "battery_level",
      "intervals": [["start_pickup", "end_pickup"]],
      "consumptionRate": 2.5,
      "capacityLimit": 100
    }
  ]
}
```

#### Elixir Struct Definitions

```elixir
defmodule AriaEngine.TemporalSolver.Constraint do
  @moduledoc "Temporal constraint definitions with JSON-LD serialization"
  
  @derive Jason.Encoder
  defstruct [:id, :type, :from, :to, :min_duration, :max_duration, :metadata]
  
  @type t :: %__MODULE__{
    id: String.t(),
    type: :stn | :resource | :synchronization,
    from: atom(),
    to: atom(), 
    min_duration: integer(),
    max_duration: integer(),
    metadata: map()
  }
end

defmodule AriaEngine.TemporalSolver.Solution do
  @moduledoc "Temporal solver solution with bounds and allocations"
  
  @derive Jason.Encoder
  defstruct [:timepoint_bounds, :resource_allocations, :constraint_violations, :metadata]
  
  @type t :: %__MODULE__{
    timepoint_bounds: %{atom() => %{atom() => {integer(), integer()}}},
    resource_allocations: %{atom() => [{integer(), integer(), number()}]},
    constraint_violations: [String.t()],
    metadata: map()
  }
end
```

### Implementation Architecture

#### Core Modules

```elixir
# Supervision tree
defmodule AriaEngine.TemporalSolver.Supervisor do
  use Supervisor
  
  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end
  
  def init(_init_arg) do
    children = [
      {AriaEngine.TemporalSolver.STNSolver, []},
      {AriaEngine.TemporalSolver.ResourceSolver, []},
      {AriaEngine.TemporalSolver.SyncSolver, []},
      {AriaEngine.TemporalSolver.Manager, []},
    ]
    
    Supervisor.init(children, strategy: :one_for_one)
  end
end

# High-performance numerical computation
defmodule AriaEngine.TemporalSolver.Matrix do
  @moduledoc "Matrix operations using Nx for STN solving"
  
  import Nx.Defn
  
  @spec floyd_warshall(Nx.Tensor.t()) :: Nx.Tensor.t()
  defn floyd_warshall(distance_matrix) do
    # Implement Floyd-Warshall with Nx tensors for GPU acceleration
  end
  
  @spec detect_negative_cycle(Nx.Tensor.t()) :: boolean()
  defn detect_negative_cycle(distance_matrix) do
    # Check diagonal for negative values
  end
end

# Concurrent constraint propagation
defmodule AriaEngine.TemporalSolver.ConstraintPropagator do
  use GenStage
  
  def start_link(opts) do
    GenStage.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  def init(opts) do
    {:producer_consumer, opts}
  end
  
  def handle_events(constraints, _from, state) do
    # Parallel constraint propagation using Flow
    propagated = 
      constraints
      |> Flow.from_enumerable()
      |> Flow.partition()
      |> Flow.map(&propagate_constraint/1)
      |> Flow.reduce(fn -> [] end, fn constraint, acc -> [constraint | acc] end)
      |> Enum.to_list()
    
    {:noreply, propagated, state}
  end
end
```

### Development Requirements

#### Testing Infrastructure

- **Unit Tests**: ExUnit for individual solver components
- **Property Tests**: StreamData for constraint solving properties
- **Integration Tests**: Full planning scenarios with real temporal data
- **Performance Tests**: Benchee for optimization verification
- **Load Tests**: Concurrent solving under high load

#### Development Tooling

- **Static Analysis**: Dialyzer for type checking
- **Code Quality**: Credo for style and complexity analysis
- **Documentation**: ExDoc for API documentation
- **Profiling**: :fprof and :eprof for performance analysis

#### Optional Performance Extensions

```elixir
# Rust NIF for critical performance paths
defmodule AriaEngine.TemporalSolver.Native do
  use Rustler, otp_app: :aria_engine, crate: "temporal_solver_native"
  
  # Fallback to pure Elixir if NIF fails to load
  def floyd_warshall_native(_matrix), do: :erlang.nif_error(:nif_not_loaded)
  
  def floyd_warshall(matrix) do
    case floyd_warshall_native(matrix) do
      {:error, :nif_not_loaded} -> 
        AriaEngine.TemporalSolver.Matrix.floyd_warshall(matrix)
      result -> 
        result
    end
  end
end
```

### Deployment Requirements

#### Runtime Configuration

- **Environment Variables**: Solver parameters and performance tuning
- **OTP Applications**: Proper startup dependencies and supervision
- **Memory Management**: Garbage collection tuning for large constraint sets
- **Monitoring**: Telemetry integration for performance metrics

#### Scalability Considerations

- **Horizontal Scaling**: Multiple solver instances for different planning domains
- **Vertical Scaling**: Multi-core utilization with Flow and GenStage
- **Memory Scaling**: Efficient constraint representation and cleanup
- **Network Scaling**: Distributed solving for large planning problems

## Consequences

### Positive

- **Pure Elixir**: Consistent with existing codebase, excellent OTP integration
- **High Performance**: Nx/Flow enable efficient numerical computation
- **Fault Tolerant**: OTP supervision provides robustness
- **Extensible**: Modular architecture allows performance optimization
- **JSON-LD Native**: Seamless integration with chibifire.com namespace

### Negative

- **Implementation Complexity**: Need to implement STN algorithms from scratch
- **Learning Curve**: Team needs to understand temporal constraint solving
- **Performance Tuning**: May require optimization for large-scale scenarios
- **Memory Usage**: Constraint graphs can consume significant memory

### Risk Mitigation

- **Incremental Implementation**: Start with simple STN, add complexity gradually
- **Performance Monitoring**: Continuous benchmarking and optimization
- **Fallback Strategies**: Pure Elixir implementations with optional Rust NIFs
- **Comprehensive Testing**: Property-based testing for constraint solving correctness

## Related ADRs

- [ADR-034: Definitive Temporal Planner Architecture](034-definitive-temporal-planner-architecture.md) - Architecture foundation
- [ADR-035: Canonical Temporal Backtracking Problem](035-canonical-temporal-backtracking-problem.md) - Performance requirements from test case
- [ADR-037: Timeline-Based vs Durative Actions](037-timeline-based-vs-durative-actions.md) - Timeline approach requiring tech stack
- [ADR-038: Timeline-Based Temporal Planner Implementation](038-timeline-based-temporal-planner-implementation.md) - Deprecated implementation details
- [ADR-040: Temporal Constraint Solver Selection](040-temporal-constraint-solver-selection.md) - PC-2 algorithm implementation requirements
- [ADR-042: Cold Boot Implementation Order](042-temporal-planner-cold-boot-implementation-order.md) - TDD implementation using this tech stack
- [ADR-043: Total Order to Partial Order Transformation](043-total-order-to-partial-order-transformation.md) - Performance optimization requirements

This tech stack provides a robust, performant, and maintainable foundation for implementing the temporal constraint solver within the AriaEngine ecosystem.
