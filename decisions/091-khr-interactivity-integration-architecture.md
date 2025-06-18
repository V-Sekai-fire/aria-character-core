# ADR-091: KHR_interactivity Integration Architecture Overview

**Status:** Active (June 17, 2025)

## Context

The glTF KHR_interactivity extension specification defines a comprehensive behavior graph system with over 400 node operations for creating interactive 3D experiences. This extension enables portable visual scripting that can execute across different platforms and engines.

### Key Challenges

1. **Scale**: 400+ distinct node operations requiring individual implementation
2. **Mixed Semantics**: Nodes span instant logical operations and time-based temporal execution
3. **Integration Complexity**: Bridging glTF object model with Aria Engine's planning systems
4. **Performance Requirements**: Real-time execution for interactive applications
5. **Type System**: Comprehensive support for scalars, vectors, matrices, and quaternions

### Current Aria Engine Capabilities

- **HTN Planning**: Hierarchical task network decomposition for logical sequencing
- **Temporal Planning**: STN-based scheduling with durative actions
- **StateV2**: Subject-predicate-fact state management
- **Domain System**: Action and method registration with metadata support

### KHR_interactivity Node Categories

| Category | Node Count | Examples | Execution Type |
|----------|------------|----------|----------------|
| Math Constants & Arithmetic | ~50 | `math/pi`, `math/add`, `math/abs` | Instant |
| Trigonometry & Advanced Math | ~40 | `math/sin`, `math/log`, `math/lerp` | Instant |
| Vector & Matrix Operations | ~60 | `math/dot`, `math/cross`, `math/inverse` | Instant |
| Control Flow | ~30 | `flow/sequence`, `flow/branch`, `flow/loop` | Logical |
| Temporal Flow | ~15 | `flow/delay`, `flow/throttle`, `flow/waitAll` | Temporal |
| Variable & State Management | ~40 | `variable/get`, `pointers/set`, `object/get` | Instant |
| Event System | ~25 | `events/onStart`, `events/onTick`, `events/send` | Event-driven |
| Animation & Timeline | ~30 | `animation/play`, `animation/pause`, `keyframe/interpolate` | Temporal |
| Type Conversion & Logic | ~35 | `bool/and`, `convert/floatToInt`, `compare/equal` | Instant |
| Debug & Utility | ~20 | `debug/log`, `debug/assert`, `utility/random` | Instant |

## Decision

Implement a **hybrid logical/temporal architecture** for KHR_interactivity integration:

### Core Architecture Principles

1. **Semantic Appropriateness**: Use temporal constructs only where time is genuinely involved
2. **Performance Optimization**: Instant operations have zero latency overhead
3. **Integration Consistency**: Leverage existing Aria Engine systems appropriately
4. **Modular Implementation**: Independent development per node category
5. **Comprehensive Testing**: Category-specific validation strategies

### Implementation Strategy

#### Instant Operations → Regular Actions
- Mathematical computations
- Logical operations  
- Type conversions
- Variable access
- Debug utilities

```elixir
def math_add(state, [a, b]) do
  result = a + b
  StateV2.add_fact(state, "output", "value", result)
end
```

#### Logical Sequencing → HTN Task Decomposition
- Control flow (sequence, branch, loop)
- Behavior graph execution
- Conditional logic

```elixir
def flow_sequence(state, child_tasks) do
  # Returns ordered task list for HTN planner
  child_tasks
end
```

#### Temporal Operations → DurativeActions
- Delays and timing
- Rate limiting
- Animation control

```elixir
def flow_delay(state, [duration]) do
  DurativeAction.new(
    :flow_delay,
    {:fixed, duration},
    %{at_start: [], over_all: [], at_end: []},
    %{at_start: [], at_end: [delay_complete: true], over_time: []},
    fn state, _args -> state end
  )
end
```

#### Event-Driven → State Change Triggers
- Lifecycle events
- Custom event propagation
- External triggers

```elixir
def events_on_start(state, []) do
  StateV2.add_fact(state, "event", "triggered", "onStart")
end
```

### Domain Registration Framework

Each node category will register with Aria Engine's domain system:

```elixir
def register_khr_math_nodes(domain) do
  domain
  |> Domain.Actions.add_action(:math_pi, &math_pi/2)
  |> Domain.Actions.add_action(:math_add, &math_add/2)
  |> Domain.Actions.add_action(:math_sin, &math_sin/2)
  # ... additional math operations
end
```

### State Integration

**glTF Object Model Bridge:**
- JSON pointer resolution for glTF properties
- Type mapping between glTF and Elixir data structures
- Bi-directional state synchronization

**StateV2 Integration:**
- Subject-predicate-fact representation of glTF scenes
- Efficient property access and modification
- State persistence across behavior graph execution

## Implementation Plan

### Phase 1: Foundation (ADR-092 to ADR-096)
- Math operations (constants, arithmetic, trigonometry, vectors)
- Control flow nodes
- Variable and state management
- Core testing framework

### Phase 2: Temporal Integration (ADR-097 to ADR-099)
- Temporal flow nodes with DurativeActions
- Event system implementation
- Animation and timeline control

### Phase 3: System Integration (ADR-100 to ADR-101)
- Debug and utility nodes
- End-to-end behavior graph execution
- Performance optimization
- Comprehensive validation

## Consequences

### Advantages

- **Appropriate Semantics**: Temporal planning used only where time matters
- **Performance**: Instant operations avoid temporal overhead
- **Maintainability**: Clear separation of concerns between logical and temporal
- **Scalability**: Independent development per node category
- **Integration**: Leverages existing Aria Engine strengths

### Disadvantages

- **Complexity**: Hybrid execution engine more complex than pure approach
- **Implementation Effort**: 400+ operations requiring individual attention
- **Testing Scope**: Comprehensive validation across multiple execution models
- **Documentation**: Extensive specification and integration documentation

### Risks

- **Scope Creep**: Feature expansion beyond core KHR_interactivity specification
- **Performance**: Real-time execution requirements for complex behavior graphs
- **Compatibility**: Maintaining fidelity with glTF specification updates
- **Resource Requirements**: Significant development and testing effort

## Success Criteria

1. **Complete Coverage**: All 400+ KHR_interactivity nodes implemented
2. **Performance**: Real-time execution of complex behavior graphs
3. **Fidelity**: Accurate implementation matching glTF specification
4. **Integration**: Seamless operation within Aria Engine ecosystem
5. **Testing**: Comprehensive validation with 100% test coverage
6. **Documentation**: Complete ADR series covering all node categories

## Related ADRs

- **ADR-089**: Migrate planner to StateV2 subject-predicate-fact
- **ADR-087**: Entity-agent timeline graph architecture
- **ADR-086**: Implement durative actions
- **ADR-092**: KHR Math Nodes (Constants & Arithmetic) ← Next
- **ADR-093**: KHR Trigonometry & Advanced Math Nodes
- **ADR-094**: KHR Vector & Matrix Operations
- **ADR-095**: KHR Control Flow Nodes
- **ADR-096**: KHR Temporal Flow Nodes
- **ADR-097**: KHR Variable & State Management
- **ADR-098**: KHR Event System Nodes
- **ADR-099**: KHR Animation & Timeline Nodes
- **ADR-100**: KHR Type Conversion & Logic Nodes
- **ADR-101**: KHR Debug & Utility Nodes

## Timeline

- **Week 1-2**: ADR-092 to ADR-094 (Core math and vector operations)
- **Week 3-4**: ADR-095 to ADR-097 (Control flow and temporal nodes)
- **Week 5-6**: ADR-098 to ADR-100 (Events, animation, logic)
- **Week 7-8**: ADR-101 and integration testing
- **Week 9-10**: Performance optimization and validation
- **Week 11-12**: Documentation and final testing

This architecture establishes Aria Engine as the premier platform for executing portable glTF behavior graphs with appropriate logical and temporal semantics.
