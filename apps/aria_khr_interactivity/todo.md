# AriaKhrInteractivity TODO

**@aria_serial:** R25W159KHRI

**ADR Reference:** R25W064B8E2 - KHR Interactivity Node Library Standardized Interface

## ⚠️ CRITICAL: Umbrella Workflow Enforcement

**MANDATORY RULE: All Mix commands MUST be executed from umbrella root directory.**

### Verification Commands

Before running ANY Mix commands, verify your location:

```bash
pwd  # Should show /home/ernest.lee/Developer/aria-character-core (umbrella root)
ls   # Should show apps/ directory and root mix.exs
```

### FORBIDDEN Patterns ❌

```bash
# NEVER do these operations:
cd apps/aria_khr_interactivity && mix compile
cd apps/aria_timeline && mix test  
cd apps/any_app && mix deps.get
```

### REQUIRED Patterns ✅

```bash
# ALWAYS work from umbrella root:
mix compile                           # Compiles all apps in dependency order
mix test                             # Runs all tests across all apps
mix test apps/aria_khr_interactivity # Tests specific app from root
mix deps.get                         # Manages dependencies for entire umbrella
mix deps.clean --all                 # Cleans all dependencies
```

## Overview

AriaKhrInteractivity provides the KHR Interactivity domain implementation for glTF behavior graphs and mathematical node operations. This app implements the complete KHR Interactivity specification including mathematical primitives, behavior graph processing, and integration capabilities.

**Extracted from AriaEngineCore:** This functionality was moved from aria_engine_core to create a focused, reusable KHR Interactivity domain app that can be used across multiple projects.

## App Responsibility

**Primary Domain:** KHR Interactivity specification implementation

- **Mathematical Primitives:** All KHR Interactivity mathematical nodes and operations
- **Behavior Graphs:** Processing and execution of KHR behavior graphs
- **Node Library:** Standardized interface for KHR node operations
- **Integration Bridge:** Connection capabilities with other umbrella apps

## Dependencies

**Tier 2 App** (depends on Tier 1 mathematical foundation):

```elixir
defp deps do
  [
    {:aria_engine_core, in_umbrella: true}, # External planner interface
    {:aria_math, in_umbrella: true},        # Mathematical operations
    {:aria_joint, in_umbrella: true}        # Joint operations if needed
  ]
end
```

## Implementation Plan

### Phase 1: Mathematical Primitives Foundation (HIGH PRIORITY)

**EXTRACTED FROM:** AriaEngineCore Phase 0 - KHR Interactivity Mathematical Primitives

- [ ] **Create External API Module**
  - [ ] Create `lib/aria_khr_interactivity.ex` with complete external API
  - [ ] Mathematical primitives delegation
  - [ ] Behavior graph operations delegation
  - [ ] Node library interface delegation

- [ ] **KHR Mathematical Primitives Implementation**
  - [ ] Create `lib/aria_khr_interactivity/primitives.ex`
  - [ ] Port all mathematical nodes from AriaEngineCore:
    - [ ] **Constants:** `math/e`, `math/pi`, `math/inf`, `math/nan`
    - [ ] **Float Arithmetic:** `math/abs`, `math/sign`, `math/add`, `math/sub`, `math/mul`, `math/div`, etc.
    - [ ] **Trigonometric:** `math/sin`, `math/cos`, `math/tan`, `math/asin`, `math/acos`, `math/atan`
    - [ ] **Exponential:** `math/exp`, `math/log`, `math/sqrt`, `math/pow`
    - [ ] **Vector Operations:** `math/length`, `math/normalize`, `math/dot`, `math/cross`
    - [ ] **Matrix Operations:** `math/matmul`, `math/transpose`, `math/inverse`
    - [ ] **Quaternion Operations:** `math/quatMul`, `math/quatConjugate`, `math/quatFromAxisAngle`
  - [ ] IEEE-754 compliance throughout all operations
  - [ ] Comprehensive error handling for edge cases

### Phase 2: AriaEngineCore Planner Integration (HIGH PRIORITY)

- [ ] **KHR Domain Definition**
  - [ ] Create `lib/aria_khr_interactivity/domain.ex`
  - [ ] Define KHR domain actions using AriaEngineCore.Domain
  - [ ] KHR primitive composition methods
  - [ ] Domain registration and action metadata
  - [ ] Temporal specifications for KHR operations

- [ ] **Planner Integration Bridge**
  - [ ] Create `lib/aria_khr_interactivity/planner_integration.ex`
  - [ ] Task abstraction layer (Layer 2 from ADR R25W064B8E2)
  - [ ] KHR sequence planning using AriaEngineCore.plan/3
  - [ ] KHR execution using AriaEngineCore.run_lazy/3
  - [ ] State management integration with AriaEngineCore

- [ ] **Node Library Interface**
  - [ ] Create `lib/aria_khr_interactivity/node_library.ex`
  - [ ] Standardized node definition system
  - [ ] Node registration and discovery
  - [ ] Integration with AriaEngineCore domain actions
  - [ ] Node validation and error handling

### Phase 3: Integration Bridge (MEDIUM PRIORITY)

- [ ] **Integration Bridge System**
  - [ ] Create `lib/aria_khr_interactivity/integration_bridge.ex`
  - [ ] Connection interface for other umbrella apps
  - [ ] Data format conversion capabilities
  - [ ] Event bridging between KHR and other systems
  - [ ] API compatibility layers

### Phase 4: Standards Compliance and Testing (HIGH PRIORITY)

- [ ] **KHR Interactivity Specification Compliance**
  - [ ] Full compliance with glTF KHR Interactivity specification
  - [ ] Validation against official KHR test cases
  - [ ] Documentation of implementation decisions
  - [ ] Performance benchmarking for mathematical operations

- [ ] **Comprehensive Test Suite**
  - [ ] Mathematical primitive tests with IEEE-754 validation
  - [ ] Behavior graph execution tests
  - [ ] Integration bridge tests
  - [ ] Performance benchmarks
  - [ ] Edge case and error handling tests

## External API Design

```elixir
defmodule AriaKhrInteractivity do
  # Mathematical primitives delegation
  defdelegate execute_math_node(node_type, inputs), to: AriaKhrInteractivity.Primitives
  defdelegate get_supported_math_nodes(), to: AriaKhrInteractivity.Primitives
  
  # AriaEngineCore planner integration
  defdelegate create_khr_domain(definition), to: AriaKhrInteractivity.PlannerIntegration
  defdelegate plan_khr_sequence(domain, state, goals), to: AriaKhrInteractivity.PlannerIntegration
  defdelegate execute_khr_plan(domain, state, goals), to: AriaKhrInteractivity.PlannerIntegration
  defdelegate execute_khr_tree(domain, state, solution_tree), to: AriaKhrInteractivity.PlannerIntegration
  
  # Node library interface
  defdelegate get_node_definition(node_type), to: AriaKhrInteractivity.NodeLibrary
  defdelegate list_available_nodes(), to: AriaKhrInteractivity.NodeLibrary
  
  # Integration bridge
  defdelegate create_integration_bridge(target_system), to: AriaKhrInteractivity.IntegrationBridge
end
```

## Success Criteria

- [ ] Complete KHR Interactivity mathematical primitives implementation
- [ ] Functional AriaEngineCore planner integration system
- [ ] Comprehensive test suite with IEEE-754 compliance
- [ ] Clear external API following umbrella standards
- [ ] Integration capabilities with other umbrella apps
- [ ] Performance benchmarks meeting KHR specification requirements

## Related Apps

- **AriaEngineCore:** Uses KHR functionality for temporal planning
- **AriaAnimationDemo:** Uses KHR for animation behavior graphs
- **AriaGltf:** Provides glTF asset processing for KHR content
- **AriaMath:** Provides foundational mathematical operations
- **AriaJoint:** Provides joint hierarchy for KHR transforms

## License and Attribution

**Standards Compliance:**

- glTF 2.0 specification compliance for KHR Interactivity
- IEEE-754 standard compliance for numerical precision
- All mathematical algorithms implement published standards with proper attribution
