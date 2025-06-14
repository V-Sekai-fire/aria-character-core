# ADR-035: AriaEngine Temporal Migration Strategy with Control Theory Verification

## Status

Accepted

## Date

2025-06-14

## Context

The current AriaEngine uses a predicate-subject-object (PSO) triple-based state representation that works well for classical AI planning but lacks the temporal capabilities required for the TimeStrike real-time tactical combat system. ADR-034 established that "all game entities (agents, actions, effects) use temporal state structures," and ADR-004 requires mandatory stability verification using control theory principles.

The temporal planner must handle complex temporal constraints while ensuring system stability through rigorous mathematical verification based on control theory principles, particularly Bellman optimality structures and Lyapunov stability analysis.

### Current AriaEngine Architecture

The existing AriaEngine provides:
- **AriaEngine.State**: PSO triple-based world state (`{predicate, subject} -> object`)
- **AriaEngine.Domain**: Action and method definitions for planning
- **AriaEngine.Plan**: IPyHOP-style hierarchical task network planning
- **AriaEngine.Actions**: Library of primitive actions that modify state

### Temporal Requirements

The temporal planner requires:
- **Time-indexed state**: All state changes must be timestamped and queryable by time
- **Historical queries**: Ability to reconstruct state at any point in history
- **Future state prediction**: Planning actions with temporal constraints and durations
- **Real-time execution**: Sub-millisecond state updates for game actions
- **Spatial indexing**: 3D coordinate-based queries for movement and line-of-sight

### Migration Challenge

The codebase contains extensive AriaEngine usage across multiple applications:
- **aria_timestrike**: Game engine and TUI components
- **aria_tui**: General TUI framework with AriaEngine integration
- **aria_workflow**: Workflow execution using AriaEngine planning
- **aria_workflow_system**: System-level workflow integration
- **Multiple test suites**: Comprehensive test coverage for existing AriaEngine

A complete replacement would break existing functionality and require massive simultaneous changes across the entire codebase.

## Decision

**Implement a gradual migration strategy that extends AriaEngine with temporal capabilities while maintaining backward compatibility.** This approach will allow incremental transition to temporal state management without breaking existing systems.

### Migration Architecture

1. **Temporal State Extension**: Create `AriaEngine.TemporalState` that extends `AriaEngine.State` with time-aware capabilities
2. **Hybrid Domain Support**: Enable `AriaEngine.Domain` to work with both traditional and temporal state representations
3. **Compatibility Layer**: Provide seamless interoperability between temporal and non-temporal components
4. **Incremental Adoption**: Allow applications to adopt temporal features on a per-component basis

## Temporal Data Structures & Types

The temporal planner requires comprehensive data structures that support both temporal reasoning and control-theoretic verification. These structures form the foundation for Bellman optimality analysis and stability verification.

### Temporal Actions

A `timed_action` represents a concrete action that will be executed at a specific time with full temporal and stability metadata:

```elixir
@type timed_action :: %{
  id: String.t(),                    # Unique identifier for this action
  agent_id: String.t(),              # Which agent performs this action
  action: atom(),                    # The action type (:move_to, :attack, :scorch, etc.)
  args: list(),                      # Arguments for the action
  start_time: float(),               # When this action begins (in seconds)
  duration: float(),                 # How long this action takes
  end_time: float(),                 # When this action completes (start_time + duration)
  prerequisites: [String.t()],       # IDs of actions that must complete first
  effects: [temporal_effect()],      # What changes this action makes to the world
  status: :scheduled | :executing | :completed | :cancelled,
  
  # Control theory extensions
  bellman_cost: float(),             # Bellman cost-to-go estimate
  stability_verified: boolean(),     # Lyapunov stability verification status
  control_constraints: [control_constraint()]  # Control-theoretic constraints
}
```

### Goals & Tasks with Stability Verification

Goals include control-theoretic verification requirements:

```elixir
@type goal :: %{
  id: String.t(),                    # Unique identifier
  type: :survive_encounter | :rescue_hostage | :destroy_bridge | :escape_scenario | :eliminate_all_enemies,
  priority: 1..100,                  # Higher numbers = higher priority
  deadline: float() | :none,         # Must be completed by this time (or no deadline)
  success_condition: goal_condition(),  # What defines success
  failure_condition: goal_condition(),  # What defines failure
  agents: [String.t()],              # Which agents are involved
  constraints: [temporal_constraint()], # Additional constraints
  metadata: map(),                   # Additional goal-specific data
  
  # Control theory extensions
  lyapunov_function: lyapunov_spec(),    # Stability verification function
  bellman_horizon: float(),              # Planning horizon for dynamic programming
  optimal_policy: policy_function() | nil, # Computed optimal policy
  stability_region: stability_bounds()   # Guaranteed stability region
}

@type lyapunov_spec :: %{
  function_type: :quadratic | :exponential | :custom,
  parameters: map(),                     # Function-specific parameters
  stability_margin: float(),             # Required stability margin
  verification_method: :analytical | :numerical
}

@type policy_function :: %{
  type: :linear_feedback | :nonlinear | :lookup_table,
  parameters: map(),                     # Policy parameters
  domain: [constraint()],                # Valid domain for policy
  performance_bound: float()             # Guaranteed performance bound
}

@type stability_bounds :: %{
  state_constraints: [state_constraint()],  # Valid state region
  input_constraints: [input_constraint()],  # Valid control inputs
  performance_guarantees: [performance_guarantee()]
}
```

### Temporal Constraints with Control Theory

Constraints extended with control-theoretic properties:

```elixir
@type temporal_constraint :: %{
  id: String.t(),
  type: :before | :after | :during | :meets | :overlaps | :starts | :finishes | :equals | :deadline | :cooldown,
  source: String.t(),                # ID of source action/task
  target: String.t() | nil,          # ID of target action/task (nil for absolute constraints)
  offset: float() | nil,             # Time offset (e.g., "5 seconds after")
  duration: float() | nil,           # For duration-based constraints
  condition: condition() | nil,      # Additional logical condition
  violation_penalty: float(),        # Cost of violating this constraint
  
  # Control theory extensions
  bellman_penalty: float(),          # Dynamic programming penalty function
  stability_impact: stability_impact(), # How constraint affects system stability
  control_law: control_law() | nil   # Associated control law for constraint satisfaction
}

@type control_constraint :: %{
  type: :state_bound | :input_bound | :rate_limit | :performance_bound,
  bound_type: :upper | :lower | :equality,
  value: float(),
  verification_required: boolean()
}

@type stability_impact :: %{
  lyapunov_derivative_sign: :negative | :positive | :indefinite,
  convergence_rate: float(),         # Expected convergence rate
  basin_of_attraction: [state_constraint()] # Region of guaranteed stability
}

@type control_law :: %{
  type: :proportional | :pid | :lqr | :mpc,
  gains: map(),                      # Control gains/parameters
  reference_trajectory: [reference_point()] | nil
}
```

### Bellman Optimality Structures

Core structures for dynamic programming and optimal control:

```elixir
@type bellman_state :: %{
  state_vector: [float()],           # Current state representation
  cost_to_go: float(),               # Bellman cost-to-go function value
  optimal_action: action_spec() | nil, # Optimal action from this state
  value_gradient: [float()] | nil,   # Gradient of value function
  hessian: [[float()]] | nil,        # Hessian for second-order methods
  timestamp: float(),                # Time at which this state is valid
  
  # Verification metadata
  optimality_verified: boolean(),    # Whether optimality has been verified
  stability_verified: boolean(),     # Whether stability has been verified
  convergence_bound: float() | nil,  # Bound on convergence rate
  performance_guarantee: float() | nil # Guaranteed performance bound
}

@type value_function :: %{
  type: :tabular | :linear | :neural | :polynomial,
  parameters: map(),                 # Function approximation parameters
  domain: [state_constraint()],      # Valid domain
  approximation_error: float(),      # Approximation error bound
  bellman_residual: float(),         # Bellman equation residual
  
  # Verification properties
  lipschitz_constant: float() | nil, # Lipschitz continuity constant
  smoothness_verified: boolean(),    # Whether function is sufficiently smooth
  convexity: :convex | :concave | :neither | :unknown
}

@type dynamic_programming_solution :: %{
  value_function: value_function(),
  policy_function: policy_function(),
  convergence_proof: convergence_proof(),
  optimality_proof: optimality_proof(),
  computation_metadata: %{
    iterations: non_neg_integer(),
    convergence_time: float(),
    numerical_precision: float()
  }
}
```

### World State with Control Theory Integration

Enhanced world state supporting control-theoretic analysis:

```elixir
@type temporal_world_state :: %{
  time: float(),                     # Current game time in seconds
  map: game_map(),                   # The map layout and terrain
  objects: [world_object()],         # Interactive objects (pillars, hostage, etc.)
  environmental_effects: [environmental_effect()], # Active environmental effects
  metadata: map(),                   # Additional world-specific data
  
  # Control theory extensions
  system_state: [float()],           # Continuous state vector for control analysis
  control_inputs: [float()],         # Current control inputs
  disturbances: [float()],           # External disturbances affecting the system
  
  # Verification state
  stability_status: stability_status(),
  performance_metrics: performance_metrics(),
  bellman_verification: bellman_verification_state(),
  
  # Temporal indexing for historical analysis
  state_history: [{float(), temporal_world_state()}], # Historical states
  prediction_horizon: float(),       # How far ahead predictions are valid
  uncertainty_bounds: uncertainty_specification()
}

@type stability_status :: %{
  is_stable: boolean(),
  lyapunov_value: float(),
  lyapunov_derivative: float(),
  time_to_instability: float() | :infinite,
  stability_margin: float()
}

@type performance_metrics :: %{
  current_cost: float(),
  cost_rate: float(),
  predicted_total_cost: float(),
  performance_bound_satisfied: boolean(),
  optimal_gap: float()              # Gap from optimal performance
}

@type bellman_verification_state :: %{
  bellman_residual: float(),
  optimality_gap: float(),
  convergence_verified: boolean(),
  last_verification_time: float(),
  verification_frequency: float()
}
```

## Control Theory Verification Framework

The migration strategy enforces rigorous control theory-based verification following ADR-004's mandate for stability verification.

### Bellman Optimality Verification

All temporal plans must satisfy Bellman optimality conditions:

```elixir
defmodule AriaEngine.TemporalState.BellmanVerification do
  @doc """
  Verifies that the temporal plan satisfies Bellman optimality conditions.
  
  For a discrete-time system with state x_k and control u_k:
  V*(x_k) = min_u { c(x_k, u_k) + γ * V*(f(x_k, u_k)) }
  
  Where:
  - V*(x_k) is the optimal value function
  - c(x_k, u_k) is the stage cost
  - f(x_k, u_k) is the system dynamics
  - γ is the discount factor
  """
  def verify_bellman_optimality(temporal_state, action_sequence, discount_factor \\ 0.95) do
    # Implementation details for Bellman verification
  end
  
  @doc """
  Computes the Bellman residual for a given value function approximation.
  
  The Bellman residual measures how well the current value function
  approximation satisfies the Bellman equation.
  """
  def compute_bellman_residual(value_function, state, action, next_state, reward) do
    # Implementation details for residual computation
  end
end
```

### Lyapunov Stability Verification

Following ADR-004, all plans must pass Lyapunov stability verification:

```elixir
defmodule AriaEngine.TemporalState.StabilityVerification do
  @doc """
  Verifies Lyapunov stability for the temporal planning system.
  
  For a system ẋ = f(x, u, t), we require a Lyapunov function V(x, t) such that:
  1. V(x, t) > 0 for all x ≠ 0 (positive definite)
  2. V̇(x, t) < 0 for all x ≠ 0 (negative definite derivative)
  3. V(0, t) = 0 (zero at equilibrium)
  
  This ensures asymptotic stability of the planning system.
  """
  def verify_lyapunov_stability(temporal_state, lyapunov_spec) do
    case lyapunov_spec.function_type do
      :quadratic -> verify_quadratic_lyapunov(temporal_state, lyapunov_spec)
      :exponential -> verify_exponential_lyapunov(temporal_state, lyapunov_spec)
      :custom -> verify_custom_lyapunov(temporal_state, lyapunov_spec)
    end
  end
  
  @doc """
  Computes the time derivative of the Lyapunov function along system trajectories.
  """
  def compute_lyapunov_derivative(lyapunov_function, state, dynamics) do
    # Implementation details for derivative computation
  end
end
```

### Dynamic Programming Solution Verification

```elixir
defmodule AriaEngine.TemporalState.DynamicProgramming do
  @doc """
  Solves the temporal planning problem using dynamic programming.
  
  Implements value iteration or policy iteration to find the optimal
  policy while maintaining rigorous convergence guarantees.
  """
  def solve_temporal_planning_problem(temporal_state, planning_horizon, convergence_tolerance \\ 1.0e-6) do
    %dynamic_programming_solution{
      value_function: computed_value_function,
      policy_function: computed_policy,
      convergence_proof: convergence_analysis,
      optimality_proof: optimality_analysis
    }
  end
  
  @doc """
  Verifies convergence of the dynamic programming solution.
  """
  def verify_convergence(solution, tolerance) do
    # Verify that ||V_k+1 - V_k|| < tolerance
    # and that the solution satisfies optimality conditions
  end
end
```

## Architecture Design

### Temporal State Extension

```elixir
defmodule AriaEngine.TemporalState do
  @moduledoc """
  Temporal extension of AriaEngine.State with time-indexed capabilities.
  
  Maintains backward compatibility with AriaEngine.State while adding:
  - Temporal indexing of all state changes
  - Historical state reconstruction
  - Time-based queries and constraints
  - Spatial indexing for 3D game worlds
  """
  
  @type timestamp :: DateTime.t() | float()
  @type entity_id :: String.t()
  @type temporal_event :: %{
    timestamp: timestamp(),
    change_type: :set | :remove | :update,
    predicate: String.t(),
    subject: String.t(),
    object: any(),
    source: :action | :effect | :system
  }
  
  @type t :: %__MODULE__{
    # Current state (AriaEngine.State compatibility)
    current_state: AriaEngine.State.t(),
    
    # Temporal indexing
    timestamp: timestamp(),
    event_log: [temporal_event()],
    temporal_index: %{timestamp() => AriaEngine.State.t()},
    
    # Spatial indexing for 3D coordinates
    spatial_index: %{entity_id() => {float(), float(), float()}},
    
    # Metadata
    started_at: timestamp(),
    version: non_neg_integer()
  }
```

### Compatibility Layer

The temporal state will implement the same interface as `AriaEngine.State` to ensure backward compatibility:

```elixir
# Existing AriaEngine code continues to work
temporal_state = AriaEngine.TemporalState.new()
|> AriaEngine.TemporalState.set_object("location", "player", "room1")

# But now supports temporal queries
past_state = AriaEngine.TemporalState.get_state_at(temporal_state, ~T[10:30:00])
future_prediction = AriaEngine.TemporalState.predict_state_at(temporal_state, actions, ~T[10:35:00])
```

### Enhanced Domain Support

`AriaEngine.Domain` will be extended to support temporal-aware actions:

```elixir
defmodule AriaEngine.TemporalActions do
  @doc """
  Temporal-aware movement action with duration and spatial updates.
  """
  def temporal_move(temporal_state, [agent_id, destination, duration]) do
    start_time = AriaEngine.TemporalState.current_time(temporal_state)
    end_time = start_time + duration
    
    temporal_state
    |> AriaEngine.TemporalState.set_temporal_object("position", agent_id, destination, end_time)
    |> AriaEngine.TemporalState.add_spatial_index(agent_id, destination)
    |> AriaEngine.TemporalState.log_event(:set, "position", agent_id, destination, :action)
  end
```

## Implementation Strategy

### Phase 1: Foundation with Control Theory (Week 1)

**Create Temporal State Extension with Verification**:
1. Implement `AriaEngine.TemporalState` module with full backward compatibility
2. Add temporal indexing and event logging capabilities  
3. **Implement control theory verification modules**:
   - `AriaEngine.TemporalState.BellmanVerification`
   - `AriaEngine.TemporalState.StabilityVerification` 
   - `AriaEngine.TemporalState.DynamicProgramming`
4. Add spatial indexing for 3D coordinates
5. Create comprehensive test suite covering both temporal operations and stability verification
6. Ensure seamless interoperability with existing `AriaEngine.State`

**Key Deliverables**:
- `apps/aria_engine/lib/aria_engine/temporal_state.ex`
- `apps/aria_engine/lib/aria_engine/temporal_actions.ex`
- `apps/aria_engine/lib/aria_engine/temporal_state/bellman_verification.ex`
- `apps/aria_engine/lib/aria_engine/temporal_state/stability_verification.ex`
- `apps/aria_engine/lib/aria_engine/temporal_state/dynamic_programming.ex`
- `apps/aria_engine/test/temporal_state_test.exs`
- `apps/aria_engine/test/control_theory_verification_test.exs`
- Migration documentation with control theory examples

**Control Theory Integration Requirements**:
- All temporal plans must pass Bellman optimality verification before execution
- Lyapunov stability verification mandatory for all dynamic operations
- Convergence proofs required for all iterative planning algorithms
- Performance bounds must be computed and verified for all solutions

### Phase 2: TimeStrike Integration with Verified Planning (Week 2)

**Migrate TimeStrike Components with Verification**:
1. Update `AriaTimestrike.GameEngine` to use temporal state with control theory verification
2. Migrate game action jobs to temporal-aware processing with stability checks
3. Implement real-time Bellman verification for action selection
4. Update TUI components to display temporal information and stability status
5. Comprehensive testing of temporal game mechanics with stability guarantees

**Key Changes**:
- `apps/aria_timestrike/lib/aria_timestrike/game_engine.ex` → temporal state with verification
- `apps/aria_timestrike/lib/aria_engine/game_action_job.ex` → verified temporal action processing
- `apps/aria_timestrike/lib/aria_timestrike/tui_content_provider.ex` → temporal state queries with stability display
- `apps/aria_timestrike/lib/aria_timestrike/stability_monitor.ex` → real-time stability monitoring

**Verification Requirements for TimeStrike**:
- Every game action must satisfy Bellman optimality before execution  
- Real-time Lyapunov stability monitoring with automatic recovery
- Performance bounds verified for all tactical decisions
- Convergence guaranteed for all planning iterations

### Phase 3: Gradual Ecosystem Migration (Ongoing)

**Optional Migration for Other Applications**:
1. `aria_workflow`: Maintain traditional state (workflows don't need temporal features)
2. `aria_tui`: Add temporal capabilities where beneficial, maintain compatibility
3. `aria_workflow_system`: Evaluate temporal needs on case-by-case basis

**Migration Criteria**:
- **Temporal Required**: Real-time systems, game mechanics, time-sensitive workflows
- **Temporal Optional**: General planning, static analysis, non-time-critical operations
- **Temporal Unnecessary**: Simple batch processing, configuration management

## Implementation Details

### Backward Compatibility Guarantees

1. **Interface Compatibility**: `AriaEngine.TemporalState` implements all `AriaEngine.State` functions
2. **Data Compatibility**: Existing state data can be imported into temporal state
3. **Function Compatibility**: All existing AriaEngine functions work with temporal state
4. **Test Compatibility**: Existing tests continue to pass with temporal state

### Migration Utilities

```elixir
defmodule AriaEngine.Migration do
  @doc """
  Converts traditional AriaEngine.State to AriaEngine.TemporalState.
  """
  def upgrade_to_temporal(state, initial_timestamp \\ DateTime.utc_now()) do
    AriaEngine.TemporalState.from_state(state, initial_timestamp)
  end
  
  @doc """
  Extracts current AriaEngine.State from AriaEngine.TemporalState.
  """
  def downgrade_to_traditional(temporal_state) do
    AriaEngine.TemporalState.to_state(temporal_state)
  end
end
```

### Performance Considerations

1. **Memory Management**: Temporal indexing uses configurable retention policies
2. **Query Optimization**: Spatial and temporal indexes optimized for game queries
3. **Garbage Collection**: Automatic cleanup of old temporal snapshots
4. **Lazy Loading**: Historical states reconstructed on-demand rather than stored

## Rationale

### Migration Strategy Benefits

1. **Risk Mitigation**: Gradual migration reduces the chance of breaking existing systems
2. **Backward Compatibility**: Existing code continues to work without modification
3. **Incremental Value**: Applications can adopt temporal features as needed
4. **Testing Continuity**: Existing test suites continue to validate functionality
5. **Development Velocity**: Teams can migrate at their own pace without coordination

### Technical Architecture Benefits

1. **Unified Interface**: Single state management approach across temporal and non-temporal components
2. **Performance Optimization**: Temporal features only incur overhead when used
3. **Extensibility**: Architecture supports future temporal enhancements
4. **Maintainability**: Clear separation between temporal and traditional state management

### TimeStrike Specific Benefits

1. **Real-time Capability**: Sub-millisecond state updates for game actions
2. **Historical Analysis**: Debug game states by examining temporal history
3. **Predictive Planning**: Plan actions with temporal constraints and durations
4. **Spatial Reasoning**: Efficient 3D coordinate queries for movement and combat

## Consequences

### Positive

- **Incremental Migration**: Existing systems continue to work while adopting temporal features
- **Reduced Risk**: Gradual adoption minimizes disruption to working systems
- **Enhanced Capabilities**: TimeStrike gains powerful temporal planning features with mathematical guarantees
- **Control Theory Foundation**: Rigorous stability and optimality verification ensures reliable operation
- **Performance Guarantees**: Bellman optimality provides provable performance bounds
- **Stability Assurance**: Lyapunov verification prevents system instability and planning failures
- **Future Flexibility**: Architecture supports additional temporal and control-theoretic enhancements
- **Development Efficiency**: Teams can focus on their specific migration needs with verified components

### Negative

- **Complexity Increase**: Codebase now supports both temporal and non-temporal state management
- **Computational Overhead**: Control theory verification adds computational cost to planning operations
- **Memory Overhead**: Temporal indexing and stability verification require additional memory
- **Migration Effort**: TimeStrike components require careful migration to temporal state with verification
- **Mathematical Expertise**: Developers need understanding of control theory concepts for advanced features
- **Verification Complexity**: Bellman and Lyapunov verification require sophisticated mathematical computations
- **Documentation Burden**: Need to maintain documentation for both state management approaches and control theory

### Neutral

- **Learning Curve**: Developers need to understand both temporal state concepts and control theory for TimeStrike work
- **Testing Complexity**: Test suites need to cover temporal, non-temporal, and control-theoretic scenarios
- **Performance Tuning**: Control theory verification parameters may require tuning for optimal performance

## Implementation Checklist

### Foundation Phase
- [ ] Create `AriaEngine.TemporalState` module with full `AriaEngine.State` compatibility
- [ ] Implement temporal indexing and event logging
- [ ] Add spatial indexing for 3D coordinates
- [ ] **Implement Bellman optimality verification module**
- [ ] **Implement Lyapunov stability verification module**
- [ ] **Implement dynamic programming solution verification**
- [ ] Create comprehensive test coverage for temporal operations
- [ ] **Create comprehensive test coverage for control theory verification**
- [ ] Add migration utilities and documentation
- [ ] **Document control theory verification requirements and examples**

### TimeStrike Migration Phase
- [ ] Update `AriaTimestrike.GameEngine` to use temporal state
- [ ] Migrate game action jobs to temporal processing
- [ ] **Integrate Bellman verification into action selection**
- [ ] **Integrate Lyapunov stability monitoring into real-time execution**
- [ ] Update TUI components for temporal state display
- [ ] **Add stability status and performance metrics to TUI**
- [ ] Test real-time temporal state updates
- [ ] **Test real-time control theory verification**
- [ ] Validate temporal query performance
- [ ] **Validate control theory verification performance**

### Integration Testing Phase
- [ ] Verify backward compatibility with existing AriaEngine usage
- [ ] Test interoperability between temporal and non-temporal components
- [ ] Performance testing of temporal operations
- [ ] **Performance testing of control theory verification**
- [ ] Integration testing with Membrane workflow system
- [ ] End-to-end testing of TimeStrike temporal features
- [ ] **End-to-end testing of stability and optimality verification**
- [ ] **Verify that all plans satisfy Bellman optimality conditions**
- [ ] **Verify that all dynamic operations pass Lyapunov stability tests**

### Control Theory Verification Testing
- [ ] **Test Bellman residual computation accuracy**
- [ ] **Test Lyapunov function evaluation and derivative computation**
- [ ] **Test convergence of dynamic programming solutions**
- [ ] **Verify optimality gap bounds for all solutions**
- [ ] **Test stability margin computation and monitoring**
- [ ] **Validate performance guarantee enforcement**

## Related Decisions

- **Superseded by**: None (new architectural decision)
- **Supersedes**: None (extends existing architecture)
- **Supports**: ADR-034 (Definitive Temporal Planner Architecture)
- **Implements**: ADR-004 (Mandatory Stability Verification) through Lyapunov and Bellman verification
- **Enables**: Real-time temporal planning for TimeStrike implementation with mathematical guarantees
- **Integrates with**: ADR-032 (Membrane Workflow Migration) for temporal job processing with verification
- **Extends**: Traditional AriaEngine with temporal capabilities and control theory verification

---

*This ADR defines the migration path from traditional AriaEngine to temporal AriaEngine while maintaining backward compatibility, enabling incremental adoption across the ecosystem, and enforcing rigorous control theory-based verification for stability and optimality guarantees. All temporal planner data structures have been consolidated into this ADR from the original `temporal_planner_data_structures.md` document.*
